import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _googleLogoUrl =
      'https://www.figma.com/api/mcp/asset/a5a387b4-0de9-4b38-b49a-5d0d6c8ab868';

  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng nhập thất bại'),
          backgroundColor: AppTheme.colors(context).expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildLogoHeader(context),
                    SizedBox(height: 34),
                    Text(
                      'Chào mừng quay trở lại',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.colors(context).textPrimary,
                          ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Vui lòng nhập thông tin để tiếp tục quản lý tài\nchính của bạn.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.colors(context).textDisabled,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.colors(
                              context,
                            ).textPrimary.withAlpha(10),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLabel(context, 'EMAIL HOẶC SỐ ĐIỆN THOẠI'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _identifierController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            validator: Validators.emailOrPhoneVN,
                            decoration: InputDecoration(
                              hintText: 'Nhập Email hoặc Số điện thoại',
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLabel(context, 'MẬT KHẨU'),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ForgotPasswordScreen(),
                                  ),
                                ),
                                child: Text(
                                  'Quên mật khẩu?',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppTheme.colors(context).primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: Validators.password,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.colors(context).textDisabled,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.colors(
                                  context,
                                ).primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                  : Text('Đăng nhập'),
                            ),
                          ),
                          SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: AppTheme.colors(
                                    context,
                                  ).border.withAlpha(60),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'HOẶC ĐĂNG NHẬP VỚI',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppTheme.colors(
                                          context,
                                        ).textSecondary,
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: AppTheme.colors(
                                    context,
                                  ).border.withAlpha(60),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: isLoading ? null : _loginWithGoogle,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppTheme.colors(
                                    context,
                                  ).border.withAlpha(40),
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
                                        Icon(Icons.g_mobiledata, size: 22),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Google',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: AppTheme.colors(
                                            context,
                                          ).textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 24, bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.colors(context).textDisabled,
                                ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RegisterScreen(),
                              ),
                            ),
                            child: Text(
                              'Đăng ký ngay',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.colors(context).primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.colors(context).primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.colors(context).textPrimary.withAlpha(13),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 30,
            ),
          ),
          SizedBox(height: 16),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.colors(context).primary,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
            ),
          ),
          SizedBox(height: 2),
          Text(
            AppConstants.appTagline,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.colors(context).textDisabled,
              letterSpacing: 2,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppTheme.colors(context).textSecondary,
      ),
    );
  }

  /// Xử lý đăng nhập bằng Google — gọi AuthProvider,
  /// chuyển Home nếu thành công hoặc hiện lỗi.
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
}
