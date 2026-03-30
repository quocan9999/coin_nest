import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/account.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

class BalanceAdjustmentScreen extends StatefulWidget {
  final Account account;
  const BalanceAdjustmentScreen({super.key, required this.account});

  @override
  State<BalanceAdjustmentScreen> createState() => _BalanceAdjustmentScreenState();
}

class _BalanceAdjustmentScreenState extends State<BalanceAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.account.balance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _adjust() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().currentUserId;
    final newBalance = Validators.parseAmount(_controller.text);
    final success = await context.read<AccountProvider>().adjustBalance(widget.account.id!, newBalance, userId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã điều chỉnh số dư'), backgroundColor: AppTheme.secondary));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Điều chỉnh số dư'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.account.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text('Số dư hiện tại: ${Formatters.currency(widget.account.balance)}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('SỐ DƯ MỚI', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                validator: Validators.amount,
                decoration: const InputDecoration(suffixText: 'đ'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 28),
              SizedBox(height: 52, child: ElevatedButton(onPressed: _adjust, child: const Text('Xác nhận'))),
            ],
          ),
        ),
      ),
    );
  }
}
