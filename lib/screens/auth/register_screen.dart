import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_utils.dart';
import '../../utils/validators.dart';
import '../home/home_screen.dart';
import 'otp_verification_screen.dart';
import 'register_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _googleLogoUrl =
      'https://www.figma.com/api/mcp/asset/3ee347b0-a8b2-46d5-9ac3-0f8e4effb5f7';
  static const _phoneRowFieldHeight = 54.0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final fullName = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final verificationId = await auth.requestPhoneRegistrationOtp(phone: phone);

    if (!mounted) return;

    if (verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Không thể gửi mã OTP'),
          backgroundColor: AppTheme.colors(context).expense,
        ),
      );
      return;
    }

    await _openOtpVerification(
      fullName: fullName,
      phone: phone,
      password: password,
      initialVerificationId: verificationId,
    );
  }

  Future<void> _openOtpVerification({
    required String fullName,
    required String phone,
    required String password,
    required String initialVerificationId,
  }) async {
    String currentVerificationId = initialVerificationId;
    final auth = context.read<AuthProvider>();
    String phoneDisplay = phone;
    try {
      phoneDisplay = PhoneUtils.normaliseVnPhone(phone);
    } catch (_) {}

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phoneDisplay: phoneDisplay,
          onConfirm: (otpCode) async {
            final success = await auth.confirmPhoneRegistration(
              fullName: fullName,
              phone: phone,
              password: password,
              otpVerificationId: currentVerificationId,
              otpCode: otpCode,
            );

            if (!mounted) return;
            if (success) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => HomeScreen()),
                (route) => false,
              );
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(auth.errorMessage ?? 'Xác thực OTP thất bại'),
                backgroundColor: AppTheme.colors(context).expense,
              ),
            );
          },
          onResend: () async {
            final newVerificationId = await auth.requestPhoneRegistrationOtp(
              phone: phone,
            );
            if (!mounted) return;
            if (newVerificationId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    auth.errorMessage ?? 'Không thể gửi lại mã OTP',
                  ),
                  backgroundColor: AppTheme.colors(context).expense,
                ),
              );
              return;
            }

            currentVerificationId = newVerificationId;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Đã gửi lại mã OTP')));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        backgroundColor: AppTheme.colors(context).surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Đăng ký',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppTheme.colors(context).textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 16),
                    Text(
                      'Tạo tài khoản',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.colors(context).textPrimary,
                          ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Đăng ký để bắt đầu quản lý tài chính cá nhân.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.colors(context).textDisabled,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildInputField(
                      label: 'HỌ TÊN',
                      hint: 'Nguyễn Văn A',
                      controller: _nameController,
                      validator: Validators.fullName,
                      enabled: !isLoading,
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 16),
                    _buildPhoneField(enabled: !isLoading),
                    SizedBox(height: 16),
                    _buildInputField(
                      label: 'MẬT KHẨU',
                      hint: '••••••••',
                      controller: _passwordController,
                      validator: Validators.password,
                      enabled: !isLoading,
                      obscureText: true,
                    ),
                    SizedBox(height: 16),
                    _buildInputField(
                      label: 'XÁC NHẬN MẬT KHẨU',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      validator: (v) => Validators.confirmPassword(
                        v,
                        _passwordController.text,
                      ),
                      enabled: !isLoading,
                      obscureText: true,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: AppTheme.colors(
                            context,
                          ).primary.withAlpha(122),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                'Đăng ký',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                      ),
                    ),
                    if (auth.errorMessage != null &&
                        auth.errorMessage!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          auth.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.colors(context).expense,
                              ),
                        ),
                      ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppTheme.colors(
                              context,
                            ).border.withAlpha(120),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Hoặc đăng ký bằng',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.colors(context).textDisabled,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppTheme.colors(
                              context,
                            ).border.withAlpha(120),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    // Nút toggle chuyển sang đăng ký bằng Email
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                // pushReplacement để tránh stack chồng nhiều lần
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterEmailScreen(),
                                  ),
                                );
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.colors(context).border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 20,
                              color: AppTheme.colors(context).textSecondary,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Email',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppTheme.colors(
                                      context,
                                    ).textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Nút đăng ký bằng Google — placeholder cho Phase 5
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.colors(context).border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              _googleLogoUrl,
                              width: 20,
                              height: 20,
                              errorBuilder: (_, _, _) =>
                                  Icon(Icons.g_mobiledata, size: 20),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Google',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppTheme.colors(
                                      context,
                                    ).textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 150),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.colors(context).textDisabled,
                              ),
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(
                            'Đăng nhập',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.colors(context).primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField({required bool enabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'SỐ ĐIỆN THOẠI',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.55,
              color: AppTheme.colors(context).textDisabled,
            ),
          ),
        ),
        SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: _phoneRowFieldHeight,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.colors(context).input,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+84',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colors(context).textSecondary,
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: _phoneRowFieldHeight,
                child: TextFormField(
                  controller: _phoneController,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '867944050',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    fillColor: AppTheme.colors(context).input,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    final req = Validators.required(value, 'Số điện thoại');
                    if (req != null) return req;
                    if (!PhoneUtils.isValidVnLocalInput(value!.trim())) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Xử lý đăng nhập bằng Google từ màn đăng ký — chuyển Home nếu thành công.
  Future<void> _loginWithGoogle() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng nhập Google thất bại'),
          backgroundColor: AppTheme.colors(context).expense,
        ),
      );
    }
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required bool enabled,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.55,
              color: AppTheme.colors(context).textDisabled,
            ),
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          enabled: enabled,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: AppTheme.colors(context).input,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
