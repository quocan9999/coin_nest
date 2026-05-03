import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.phoneDisplay,
    this.isLoading = false,
    this.onConfirm,
    this.onResend,
  });

  final String phoneDisplay;
  final bool isLoading;
  final Future<void> Function(String otp)? onConfirm;
  final Future<void> Function()? onResend;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _otpLength = 6;

  late final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((e) => e.text).join();

  bool get _canSubmit => _otpCode.length == _otpLength && !_isBusy;

  bool get _isBusy => widget.isLoading || _isSubmitting || _isResending;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (widget.onConfirm == null) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm!(_otpCode);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_isBusy || widget.onResend == null) return;

    setState(() => _isResending = true);
    try {
      await widget.onResend!();
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _onOtpChanged(int index, String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned != value) {
      _controllers[index].text = cleaned;
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: cleaned.length),
      );
    }

    if (cleaned.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  void _onOtpSubmitted(int index) {
    if (index == _otpLength - 1) {
      _submit();
    } else {
      _focusNodes[index + 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: _isBusy ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Xác thực OTP',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 54),
              Text(
                'Nhập mã gồm 6 chữ số đã được gửi đến số điện thoại của bạn',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.phoneDisplay,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_otpLength, _buildOtpField),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  child: _isSubmitting || widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Xác nhận'),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _isBusy ? null : _resend,
                  child: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Gửi lại mã',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.primary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 48,
      height: 48,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: !_isBusy,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: index == _otpLength - 1
            ? TextInputAction.done
            : TextInputAction.next,
        maxLength: 1,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.onSurface,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: AppTheme.surfaceContainerHighest,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: BorderSide(
              color: AppTheme.outlineVariant.withAlpha(51),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: const BorderSide(
              color: AppTheme.primary,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) => _onOtpChanged(index, value),
        onSubmitted: (_) => _onOtpSubmitted(index),
      ),
    );
  }
}
