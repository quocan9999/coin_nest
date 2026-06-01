import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_utils.dart';
import '../../utils/validators.dart';

/// Các bước trong flow quên mật khẩu — state machine nội bộ.
enum _ForgotStep {
  /// Bước 1: nhập email hoặc số điện thoại
  identifier,

  /// Bước 2: xác minh OTP (chỉ nhánh phone)
  otp,

  /// Bước 3: nhập mật khẩu mới (chỉ nhánh phone)
  newPassword,
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // ─── State machine ──────────────────────────────────────────────
  _ForgotStep _currentStep = _ForgotStep.identifier;

  // ─── Bước 1: Identifier ─────────────────────────────────────────
  final _identifierFormKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  // ─── Bước 2: OTP ────────────────────────────────────────────────
  static const _otpLength = 6;
  late final List<TextEditingController> _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _otpFocusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );
  String? _verificationId;
  String _phoneDisplay = '';

  // Timer countdown 60s để gửi lại OTP
  Timer? _resendTimer;
  int _resendCountdown = 0;

  // ─── Bước 3: Mật khẩu mới ──────────────────────────────────────
  final _passwordFormKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  // ─── Loading riêng cho screen (không dùng provider isLoading
  //     để tránh conflict với các flow khác) ───────────────────────
  bool _isSubmitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ─── Bước 1: Xử lý submit identifier ───────────────────────────

  Future<void> _handleIdentifierSubmit() async {
    final input = _identifierController.text.trim();

    // Validate thủ công và hiển thị lỗi qua SnackBar thay vì inline text
    final validationError = Validators.emailOrPhoneVN(input);
    if (validationError != null) {
      _showErrorSnackBar(validationError);
      return;
    }

    final isEmail = input.contains('@');

    if (isEmail) {
      await _handleEmailBranch(input);
    } else {
      await _handlePhoneBranch(input);
    }
  }

  /// Nhánh email: tra Firebase server trước → phân luồng Google / Email+Password.
  /// Không phụ thuộc local SQLite — hoạt động đúng trên mọi thiết bị.
  Future<void> _handleEmailBranch(String email) async {
    setState(() => _isSubmitting = true);

    try {
      final normalised = email.trim().toLowerCase();
      final auth = context.read<AuthProvider>();

      // Tra cứu provider trực tiếp trên Firebase server
      final provider = await auth.checkAccountProvider(normalised);

      if (!mounted) return;

      // Trường hợp email không tồn tại trên Firebase
      if (provider == null) {
        setState(() => _isSubmitting = false);
        _showErrorSnackBar('Không tìm thấy tài khoản với email này');
        return;
      }

      // Trường hợp tài khoản Google — không có password để reset
      if (provider == 'google') {
        setState(() => _isSubmitting = false);
        await _showInfoDialog(
          icon: Icons.account_circle_outlined,
          iconColor: AppTheme.primary,
          title: 'Tài khoản Google',
          message:
              'Tài khoản này sử dụng Google Sign-In và không có mật khẩu. '
              'Vui lòng đăng nhập bằng Google.',
          buttonText: 'Đã hiểu',
        );
        return;
      }

      // Nhánh email+password → gửi link reset qua Firebase
      final success = await auth.sendPasswordResetEmailForUser(
        email: normalised,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        await _showInfoDialog(
          icon: Icons.mark_email_read_outlined,
          iconColor: AppTheme.primary,
          title: 'Kiểm tra email',
          message:
              'Đã gửi link đặt lại mật khẩu vào email $normalised. '
              'Vui lòng kiểm tra hộp thư (bao gồm thư rác).',
          buttonText: 'Về đăng nhập',
          onPressed: () {
            Navigator.of(context).pop(); // đóng dialog
            Navigator.of(context).pop(); // pop về Login
          },
        );
      } else {
        _showErrorSnackBar(
          auth.errorMessage ?? 'Gửi email đặt lại mật khẩu thất bại',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnackBar('Đã xảy ra lỗi. Vui lòng thử lại.');
    }
  }

  /// Nhánh phone: tra Firebase bằng synthetic email để xác nhận tài khoản
  /// tồn tại, rồi gửi OTP. Không phụ thuộc local SQLite.
  Future<void> _handlePhoneBranch(String rawPhone) async {
    setState(() => _isSubmitting = true);

    try {
      final normalisedPhone = PhoneUtils.normaliseVnPhone(rawPhone);
      final auth = context.read<AuthProvider>();

      // Chuyển phone sang synthetic email rồi tra cứu Firebase server
      final syntheticEmail = PhoneUtils.phoneToSyntheticEmail(normalisedPhone);
      final provider = await auth.checkAccountProvider(syntheticEmail);

      if (!mounted) return;

      // Không tìm thấy tài khoản phone trên Firebase
      if (provider == null) {
        setState(() => _isSubmitting = false);
        _showErrorSnackBar('Không tìm thấy tài khoản với số điện thoại này');
        return;
      }

      // Nhánh phone (có password) → gửi OTP
      _phoneDisplay = normalisedPhone;
      final verificationId = await auth.requestForgotPasswordOtp(
        phone: normalisedPhone,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (verificationId != null) {
        _verificationId = verificationId;
        _startResendTimer();
        setState(() => _currentStep = _ForgotStep.otp);
      } else {
        _showErrorSnackBar(
          auth.errorMessage ?? 'Gửi mã OTP thất bại. Vui lòng thử lại.',
        );
      }
    } on FormatException {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnackBar('Số điện thoại không hợp lệ');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnackBar('Đã xảy ra lỗi. Vui lòng thử lại.');
    }
  }

  // ─── Bước 2: Xử lý OTP ─────────────────────────────────────────

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  bool get _canSubmitOtp => _otpCode.length == _otpLength && !_isSubmitting;

  void _onOtpChanged(int index, String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length > 1) {
      final currentDigit = cleaned.characters.first;
      final nextDigit = cleaned.characters.last;
      _otpControllers[index].text = currentDigit;
      _otpControllers[index].selection = TextSelection.collapsed(
        offset: currentDigit.length,
      );

      if (index < _otpLength - 1) {
        _otpControllers[index + 1].text = nextDigit;
        _otpControllers[index + 1].selection = TextSelection.collapsed(
          offset: nextDigit.length,
        );
        _otpFocusNodes[index + 1].requestFocus();
      }

      setState(() {});
      return;
    }

    if (cleaned != value) {
      _otpControllers[index].text = cleaned;
      _otpControllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: cleaned.length),
      );
    }

    if (cleaned.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    if (cleaned.isNotEmpty && index < _otpLength - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  KeyEventResult _onOtpKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_otpControllers[index].text.isNotEmpty || index == 0) {
      return KeyEventResult.ignored;
    }

    _otpFocusNodes[index - 1].requestFocus();
    _otpControllers[index - 1].selection = TextSelection.collapsed(
      offset: _otpControllers[index - 1].text.length,
    );
    return KeyEventResult.handled;
  }

  void _onOtpFieldSubmitted(int index) {
    if (index == _otpLength - 1) {
      _handleOtpConfirm();
    } else {
      _otpFocusNodes[index + 1].requestFocus();
    }
  }

  /// Khi OTP đủ 6 số và đúng --> chuyển sang màn hình đặt lại mật khẩu
  Future<void> _handleOtpConfirm() async {
    if (!_canSubmitOtp) return;

    final verificationId = _verificationId;
    if (verificationId == null) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final isValid = await auth.confirmForgotPasswordOtp(
      verificationId: verificationId,
      otpCode: _otpCode,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!isValid) {
      _showErrorSnackBar(
        auth.errorMessage ?? 'Mã OTP không hợp lệ hoặc đã hết hạn',
      );
      return;
    }

    setState(() => _currentStep = _ForgotStep.newPassword);
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) timer.cancel();
      });
    });
  }

  /// Gửi lại OTP — gọi lại requestForgotPasswordOtp
  Future<void> _handleResendOtp() async {
    if (_isSubmitting || _resendCountdown > 0) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final verificationId = await auth.requestForgotPasswordOtp(
      phone: _phoneDisplay,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (verificationId != null) {
      _verificationId = verificationId;
      // Xoá OTP cũ
      for (final c in _otpControllers) {
        c.clear();
      }
      _startResendTimer();
      _showSuccessSnackBar('Đã gửi lại mã OTP');
    } else {
      _showErrorSnackBar(
        auth.errorMessage ?? 'Gửi lại mã thất bại. Vui lòng thử lại.',
      );
    }
  }

  // ─── Bước 3: Đặt lại mật khẩu ──────────────────────────────────

  Future<void> _handleResetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    if (_verificationId == null) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPasswordByPhoneFirebase(
      verificationId: _verificationId!,
      otpCode: _otpCode,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu đã được đặt lại thành công'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      Navigator.pop(context);
    } else {
      _showErrorSnackBar(
        auth.errorMessage ?? 'Đặt lại mật khẩu thất bại. Vui lòng thử lại.',
      );
    }
  }

  // ─── Helpers UI ─────────────────────────────────────────────────

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.secondary),
    );
  }

  Future<void> _showInfoDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String buttonText,
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: AppTheme.colors(ctx).textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed ?? () => Navigator.of(ctx).pop(),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  /// Quay lại bước trước đó trong state machine
  void _goBack() {
    switch (_currentStep) {
      case _ForgotStep.otp:
        // Xoá OTP đã nhập khi quay lại
        for (final c in _otpControllers) {
          c.clear();
        }
        _resendTimer?.cancel();
        setState(() => _currentStep = _ForgotStep.identifier);
        break;
      case _ForgotStep.newPassword:
        setState(() => _currentStep = _ForgotStep.otp);
        break;
      case _ForgotStep.identifier:
        Navigator.pop(context);
        break;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: _isSubmitting ? null : _goBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case _ForgotStep.identifier:
        return _buildIdentifierStep();
      case _ForgotStep.otp:
        return _buildOtpStep();
      case _ForgotStep.newPassword:
        return _buildNewPasswordStep();
    }
  }

  // ─── Bước 1: Nhập identifier ────────────────────────────────────

  Widget _buildIdentifierStep() {
    return Form(
      key: _identifierFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Quên mật khẩu',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập số điện thoại hoặc email đã đăng ký để đặt lại mật khẩu.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.colors(context).textSecondary,
            ),
          ),

          const SizedBox(height: 28),

          _label('SỐ ĐIỆN THOẠI HOẶC EMAIL'),
          const SizedBox(height: 8),
          TextField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleIdentifierSubmit(),
            decoration: const InputDecoration(
              hintText: 'Nhập số điện thoại hoặc email',
            ),
          ),

          const SizedBox(height: 28),

          _submitButton(label: 'Tiếp tục', onPressed: _handleIdentifierSubmit),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Bước 2: Xác minh OTP ──────────────────────────────────────

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Xác thực OTP',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Nhập mã gồm 6 chữ số đã được gửi đến số điện thoại của bạn',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.colors(context).textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _phoneDisplay,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 30),

        // 6 ô OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpLength, _buildOtpField),
        ),

        const SizedBox(height: 28),

        _submitButton(
          label: 'Xác nhận',
          onPressed: _canSubmitOtp ? _handleOtpConfirm : null,
        ),

        const SizedBox(height: 20),

        // Nút gửi lại mã
        Center(
          child: TextButton(
            onPressed: (_isSubmitting || _resendCountdown > 0)
                ? null
                : _handleResendOtp,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _resendCountdown > 0
                        ? 'Gửi lại mã ($_resendCountdown s)'
                        : 'Gửi lại mã',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _resendCountdown > 0
                          ? AppTheme.outline
                          : AppTheme.primary,
                      decoration: _resendCountdown > 0
                          ? null
                          : TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Focus(
        onKeyEvent: (node, event) => _onOtpKeyEvent(index, event),
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          enabled: !_isSubmitting,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: index == _otpLength - 1
              ? TextInputAction.done
              : TextInputAction.next,
          maxLength: 2,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              borderSide: BorderSide(
                color: AppTheme.outlineVariant.withAlpha(51),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
          onChanged: (value) => _onOtpChanged(index, value),
          onSubmitted: (_) => _onOtpFieldSubmitted(index),
        ),
      ),
    );
  }

  // ─── Bước 3: Nhập mật khẩu mới ─────────────────────────────────

  Widget _buildNewPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Đặt mật khẩu mới',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập mật khẩu mới cho tài khoản của bạn.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.colors(context).textSecondary,
            ),
          ),

          const SizedBox(height: 28),

          _label('MẬT KHẨU MỚI'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscure1,
            validator: Validators.password,
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure1
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.outline,
                ),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              ),
            ),
          ),

          const SizedBox(height: 20),

          _label('XÁC NHẬN MẬT KHẨU MỚI'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscure2,
            validator: (v) =>
                Validators.confirmPassword(v, _newPasswordController.text),
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure2
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.outline,
                ),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),
          ),

          const SizedBox(height: 28),

          _submitButton(
            label: 'Đặt lại mật khẩu',
            onPressed: _handleResetPassword,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Shared widgets ─────────────────────────────────────────────

  Widget _label(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _submitButton({required String label, VoidCallback? onPressed}) {
    final isDisabled = onPressed == null || _isSubmitting;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        child: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}
