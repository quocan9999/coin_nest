import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _googleLogoUrl =
      'https://www.figma.com/api/mcp/asset/3ee347b0-a8b2-46d5-9ac3-0f8e4effb5f7';

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
    final success = await auth.register(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng ký thất bại'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Đăng ký',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Tạo tài khoản',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đăng ký để bắt đầu quản lý tài chính cá nhân.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.outline,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'HỌ TÊN',
                      hint: 'Nguyễn Văn A',
                      controller: _nameController,
                      validator: Validators.fullName,
                      enabled: !isLoading,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'SỐ ĐIỆN THOẠI',
                      hint: '09x xxxx xxx',
                      controller: _phoneController,
                      validator: Validators.phoneVN,
                      keyboardType: TextInputType.phone,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'MẬT KHẨU',
                      hint: '••••••••',
                      controller: _passwordController,
                      validator: Validators.password,
                      enabled: !isLoading,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'XÁC NHẬN MẬT KHẨU',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      validator: (v) =>
                          Validators.confirmPassword(v, _passwordController.text),
                      enabled: !isLoading,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor:
                              AppTheme.primary.withAlpha(122),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Đăng ký',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                      ),
                    ),
                    if (auth.errorMessage != null && auth.errorMessage!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          auth.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.error,
                              ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppTheme.outlineVariant.withAlpha(120),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Hoặc đăng ký bằng',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.outline,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppTheme.outlineVariant.withAlpha(120),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tính năng đang phát triển'),
                                  ),
                                );
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              _googleLogoUrl,
                              width: 20,
                              height: 20,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.g_mobiledata, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Google',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: const Color(0xFF374151),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 150),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.outline,
                              ),
                        ),
                        GestureDetector(
                          onTap: isLoading ? null : () => Navigator.pop(context),
                          child: Text(
                            'Đăng nhập',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.55,
                  color: AppTheme.outline,
                ),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          enabled: enabled,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: AppTheme.surfaceContainerHigh,
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
