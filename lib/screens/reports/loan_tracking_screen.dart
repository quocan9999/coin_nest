import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class LoanTrackingScreen extends StatefulWidget {
  const LoanTrackingScreen({super.key});

  @override
  State<LoanTrackingScreen> createState() => _LoanTrackingScreenState();
}

class _LoanTrackingScreenState extends State<LoanTrackingScreen> with SingleTickerProviderStateMixin {
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
    );
  }

  Widget _buildTabContent({
    required BuildContext context,
    required List<dynamic> loans, 
    required bool isLend,
  }) {
    double totalAmount = 0;
    double totalRemaining = 0;
    
    for (var l in loans) {
      totalAmount += l.amount;
      totalRemaining += l.remainingAmount;
    }
    double totalPaid = totalAmount - totalRemaining;
    
    final color = isLend ? AppTheme.secondary : AppTheme.tertiary;
    final colorContainer = isLend ? AppTheme.secondaryContainer : AppTheme.tertiaryContainer;

    return SingleChildScrollView(
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
                        isLend ? 'Tổng tiến độ thu tiền' : 'Tổng tiến độ trả nợ',
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
          if (loans.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Không có khoản nào')),
            ),
          ...loans.map((loan) {
            double paid = loan.amount - loan.remainingAmount;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4)),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        Formatters.currency(loan.amount),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (loan.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 14, color: AppTheme.outlineVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Hạn: ${Formatters.date(loan.dueDate)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.outline),
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
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: color),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đã thanh toán: ${Formatters.currency(paid)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
