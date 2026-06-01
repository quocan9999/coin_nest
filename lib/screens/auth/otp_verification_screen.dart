import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
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

  bool get _canResend => !_isBusy && _resendCountdown == 0;

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
    if (!_canResend || widget.onResend == null) return;

    setState(() => _isResending = true);
    try {
      await widget.onResend!();
      _startResendTimer();
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    if (!mounted) return;

    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _resendCountdown = 0;
          timer.cancel();
        }
      });
    });
  }

  void _onOtpChanged(int index, String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length > 1) {
      final currentDigit = cleaned.characters.first;
      final nextDigit = cleaned.characters.last;
      _controllers[index].text = currentDigit;
      _controllers[index].selection = TextSelection.collapsed(
        offset: currentDigit.length,
      );

      if (index < _otpLength - 1) {
        _controllers[index + 1].text = nextDigit;
        _controllers[index + 1].selection = TextSelection.collapsed(
          offset: nextDigit.length,
        );
        _focusNodes[index + 1].requestFocus();
      }

      setState(() {});
      return;
    }

    if (cleaned != value) {
      _controllers[index].text = cleaned;
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: cleaned.length),
      );
    }

    if (cleaned.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (cleaned.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
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
    if (_controllers[index].text.isNotEmpty || index == 0) {
      return KeyEventResult.ignored;
    }

    _focusNodes[index - 1].requestFocus();
    _controllers[index - 1].selection = TextSelection.collapsed(
      offset: _controllers[index - 1].text.length,
    );
    return KeyEventResult.handled;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            color: Theme.of(context).colorScheme.onSurface,
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
                  color: AppTheme.colors(context).textSecondary,
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
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Xác nhận'),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _canResend ? _resend : null,
                  child: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _resendCountdown > 0
                              ? 'Gửi lại mã ($_resendCountdown s)'
                              : 'Gửi lại mã',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
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
      child: Focus(
        onKeyEvent: (node, event) => _onOtpKeyEvent(index, event),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          enabled: !_isBusy,
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
          onSubmitted: (_) => _onOtpSubmitted(index),
        ),
      ),
    );
  }
}
