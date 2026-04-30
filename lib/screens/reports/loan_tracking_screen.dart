import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/loan.dart';
import '../../providers/loan_provider.dart';
import '../../providers/auth_provider.dart';
import '../loans/add_edit_loan_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class LoanTrackingScreen extends StatefulWidget {
  const LoanTrackingScreen({super.key});

  @override
  State<LoanTrackingScreen> createState() => _LoanTrackingScreenState();
}

class _LoanTrackingScreenState extends State<LoanTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId != 0) {
      context.read<LoanProvider>().loadLoans(userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loanProv = context.watch<LoanProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Theo dõi vay nợ',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          tabs: const [
            Tab(text: 'Cho Vay'),
            Tab(text: 'Còn Nợ'),
          ],
        ),
      ),
      body: loanProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(
                  context: context,
                  loans: loanProv.loans.where((l) => l.type == 'lend').toList(),
                  isLend: true,
                ),
                _buildTabContent(
                  context: context,
                  loans: loanProv.loans.where((l) => l.type == 'borrow').toList(),
                  isLend: false,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          final userId = context.read<AuthProvider>().currentUserId;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditLoanScreen()),
          ).then((_) {
            if (userId != 0) {
              context.read<LoanProvider>().loadLoans(userId);
            }
          });
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildTabContent({
    required BuildContext context,
    required List<Loan> loans,
    required bool isLend,
  }) {
    final activeLoans = loans.where((l) => l.status != 'paid').toList();
    final paidLoans = loans.where((l) => l.status == 'paid').toList();
    double totalAmount = 0;
    double totalRemaining = 0;

    for (final l in activeLoans) {
      totalAmount += l.amount;
      totalRemaining += l.remainingAmount;
    }
    final totalPaid = totalAmount - totalRemaining;

    final color = isLend ? AppTheme.secondary : AppTheme.tertiary;
    final colorContainer =
        isLend ? AppTheme.secondaryContainer : AppTheme.tertiaryContainer;

    return RefreshIndicator(
      color: isLend ? AppTheme.secondary : AppTheme.tertiary,
      onRefresh: () async {
        final userId = context.read<AuthProvider>().currentUserId;
        if (userId != 0) {
          await context.read<LoanProvider>().loadLoans(userId);
        }
      },
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLend
                            ? 'Tổng tiến độ thu tiền'
                            : 'Tổng tiến độ trả nợ',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.currency(totalPaid),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                      ),
                      Text(
                        '/ ${Formatters.currency(totalAmount)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: color.withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: totalAmount > 0 ? (totalPaid / totalAmount) : 0,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.4),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Text(
                      '${totalAmount > 0 ? ((totalPaid / totalAmount) * 100).toStringAsFixed(0) : 0}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            isLend ? 'DANH SÁCH CHO VAY' : 'DANH SÁCH CẦN TRẢ',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.outline,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 16),
          if (activeLoans.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Không có khoản nào')),
            ),
          ...activeLoans.map((loan) {
            final paid = loan.amount - loan.remainingAmount;
            return GestureDetector(
              onLongPress: () => _showDeleteDialog(context, loan),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loan.personName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          Formatters.currency(loan.amount),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (loan.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: AppTheme.outlineVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Hạn: ${Formatters.date(loan.dueDate!)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.outline),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: loan.amount > 0 ? paid / loan.amount : 0,
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${loan.amount > 0 ? ((paid / loan.amount) * 100).toStringAsFixed(0) : 0}%',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đã thanh toán: ${Formatters.currency(paid)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatusBadge(context, loan),
                        const Spacer(),
                        if (loan.status != 'paid')
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              backgroundColor: isLend
                                  ? AppTheme.secondaryContainer
                                  : AppTheme.tertiaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                            ),
                            onPressed: () => _showPaymentDialog(
                              context: context,
                              loan: loan,
                              isLend: isLend,
                            ),
                            child: Text(
                              isLend ? 'Thu tiền' : 'Trả nợ',
                              style: TextStyle(
                                color: isLend ? AppTheme.secondary : AppTheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          if (paidLoans.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'ĐÃ HOÀN THÀNH',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.outline,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 12),
            ...paidLoans.map((loan) {
              final paid = loan.amount - loan.remainingAmount;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loan.personName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          Formatters.currency(loan.amount),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đã thanh toán: ${Formatters.currency(paid)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusBadge(context, loan),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 40),
        ],
      ),
    ));
  }

  Widget _buildStatusBadge(BuildContext context, Loan loan) {
    if (loan.status == 'paid') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Text(
          'Đã hoàn thành',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
    }

    if (loan.dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDate = DateTime(
        loan.dueDate!.year,
        loan.dueDate!.month,
        loan.dueDate!.day,
      );
      if (dueDate.isBefore(today)) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.errorContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            'Quá hạn',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w700,
                ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        'Đang hoạt động',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Future<void> _showPaymentDialog({
    required BuildContext context,
    required Loan loan,
    required bool isLend,
  }) async {
    final controller = TextEditingController();
    String? errorText;

    final confirmedAmount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                isLend
                    ? 'Thu tiền từ ${loan.personName}'
                    : 'Trả nợ cho ${loan.personName}',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Còn lại: ${Formatters.currency(loan.remainingAmount)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Số tiền',
                      hintText: 'Nhập số tiền (VND)',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    final raw = controller.text.trim().replaceAll(',', '');
                    final amount = double.tryParse(raw);
                    if (amount == null || amount <= 0) {
                      setDialogState(() => errorText = 'Số tiền phải lớn hơn 0');
                      return;
                    }
                    if (amount > loan.remainingAmount) {
                      setDialogState(
                        () => errorText = 'Số tiền không được vượt quá số còn lại',
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, amount);
                  },
                  child: Text(isLend ? 'Thu tiền' : 'Trả nợ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmedAmount == null) return;
    if (!mounted) return;

    final loanId = loan.id;
    final userId = context.read<AuthProvider>().currentUserId;
    if (loanId == null || userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật khoản vay')),
      );
      return;
    }

    final ok =
        await context.read<LoanProvider>().recordPayment(loanId, confirmedAmount, userId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (isLend
                  ? 'Đã thu ${Formatters.currency(confirmedAmount)} thành công'
                  : 'Đã trả ${Formatters.currency(confirmedAmount)} thành công')
              : 'Cập nhật thất bại',
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, Loan loan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa khoản vay?'),
        content: Text(
          'Bạn có chắc muốn xóa khoản vay của ${loan.personName} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final loanId = loan.id;
    final userId = context.read<AuthProvider>().currentUserId;
    if (loanId == null || userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa khoản vay')),
      );
      return;
    }

    final ok = await context.read<LoanProvider>().deleteLoan(loanId, userId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Đã xóa khoản vay' : 'Xóa khoản vay thất bại'),
      ),
    );
  }
}
