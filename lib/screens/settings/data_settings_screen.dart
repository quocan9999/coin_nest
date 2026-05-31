import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backup_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_theme.dart';

class DataSettingsScreen extends StatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  State<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends State<DataSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      context.read<BackupProvider>().loadMetadata(authProvider.currentUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Sao lưu & Phục hồi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<BackupProvider>(
        builder: (context, backupProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacing10),
            children: [
              _StatusPanel(provider: backupProvider),
              const SizedBox(height: AppTheme.spacing8),
              _ActionPanel(
                icon: Icons.cloud_upload_outlined,
                iconColor: AppTheme.primary,
                title: 'Sao lưu dữ liệu',
                description:
                    'Lưu snapshot dữ liệu tài chính của tài khoản hiện tại lên Cloud Firestore.',
                buttonLabel: 'Sao lưu ngay',
                isLoading: backupProvider.isLoading,
                onPressed: () => _backupNow(context),
              ),
              const SizedBox(height: AppTheme.spacing8),
              _ActionPanel(
                icon: Icons.cloud_download_outlined,
                iconColor: AppTheme.loanColor,
                title: 'Khôi phục dữ liệu',
                description:
                    'Tải bản sao lưu cloud và ghi đè accounts, categories, transactions, loans, loan payments và budgets cục bộ.',
                buttonLabel: 'Khôi phục',
                isLoading: backupProvider.isLoading,
                isPrimary: false,
                onPressed: () => _confirmRestore(context),
              ),
              if (backupProvider.errorMessage != null) ...[
                const SizedBox(height: AppTheme.spacing8),
                _ErrorPanel(message: backupProvider.errorMessage!),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _backupNow(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await context.read<BackupProvider>().backupNow(
      authProvider.currentUser,
    );
    if (!context.mounted) return;

    _showSnackBar(
      context,
      success ? 'Đã sao lưu dữ liệu lên Firestore' : 'Sao lưu thất bại',
    );
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ghi đè dữ liệu hiện tại?'),
        content: const Text(
          'Khôi phục sẽ xóa dữ liệu tài chính cục bộ hiện tại và thay bằng bản sao lưu trên cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final authProvider = context.read<AuthProvider>();
    final success = await context.read<BackupProvider>().restoreCurrent(
      authProvider.currentUser,
    );

    if (!context.mounted) return;
    if (success) {
      await _reloadFinancialProviders(context, authProvider.currentUserId);
    }

    if (!context.mounted) return;
    _showSnackBar(
      context,
      success ? 'Đã khôi phục dữ liệu từ Firestore' : 'Khôi phục thất bại',
    );
  }

  Future<void> _reloadFinancialProviders(BuildContext context, int userId) {
    return Future.wait([
      context.read<AccountProvider>().loadAccounts(userId),
      context.read<CategoryProvider>().loadCategories(userId),
      context.read<TransactionProvider>().loadTransactions(userId),
      context.read<LoanProvider>().loadLoans(userId),
      context.read<BudgetProvider>().loadBudgets(userId),
      context.read<ReportProvider>().loadReport(userId),
    ]);
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.provider});

  final BackupProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = provider.metadata;
    final createdAt = metadata?.createdAt.toLocal();
    final dateText = createdAt == null
        ? 'Chưa có bản sao lưu'
        : DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
    final countText = metadata == null
        ? '0 bản ghi'
        : '${metadata.recordCounts.values.fold<int>(0, (sum, count) => sum + count)} bản ghi';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRẠNG THÁI CLOUD',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            dateText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            countText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.isLoading,
    required this.onPressed,
    this.isPrimary = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String buttonLabel;
  final bool isLoading;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: AppTheme.spacing6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: isPrimary
                ? ElevatedButton(
                    onPressed: isLoading ? null : onPressed,
                    child: _ButtonContent(
                      isLoading: isLoading,
                      label: buttonLabel,
                    ),
                  )
                : OutlinedButton(
                    onPressed: isLoading ? null : onPressed,
                    child: _ButtonContent(
                      isLoading: isLoading,
                      label: buttonLabel,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.isLoading, required this.label});

  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return Text(label);

    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppTheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
