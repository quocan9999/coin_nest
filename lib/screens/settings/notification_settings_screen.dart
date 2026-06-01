import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/account_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/account.dart'; // Đã sửa tên import chuẩn xác
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isEnabled = false;
  int? _expenseAccountId;
  int? _incomeAccountId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Đã xử lý lỗi biến bool? không thể gán cho bool
      _isEnabled = prefs.getBool('auto_notification_enabled') ?? false;
      _expenseAccountId = prefs.getInt('auto_expense_account_id');
      _incomeAccountId = prefs.getInt('auto_income_account_id');
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_notification_enabled', _isEnabled);
    if (_expenseAccountId != null) {
      await prefs.setInt('auto_expense_account_id', _expenseAccountId!);
    }
    if (_incomeAccountId != null) {
      await prefs.setInt('auto_income_account_id', _incomeAccountId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final accounts = accountProvider.accounts;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Cài đặt thông báo tự động'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Ghi chép từ thông báo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text(
              'Tự động nhận diện và tạo bản nháp giao dịch khi có thông báo biến động số dư.',
            ),
            activeTrackColor: AppTheme.primary, // Đã thay thế activeColor bị lỗi thời
            value: _isEnabled,
            onChanged: (bool value) async {
              setState(() {
                _isEnabled = value;
              });
              await _saveSettings();
              if (_isEnabled) {
                await NotificationService.initListener();
              } else {
                NotificationService.stopListener();
              }
            },
          ),
          
          if (_isEnabled) ...[
            const SizedBox(height: 24),
            const Text(
              'CẤU HÌNH TÀI KHOẢN MẶC ĐỊNH',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.outline,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildAccountDropdown(
              label: 'Tài khoản áp dụng khi bị trừ tiền (Chi)',
              accounts: accounts,
              value: _expenseAccountId,
              onChanged: (val) {
                setState(() {
                  _expenseAccountId = val;
                  _saveSettings();
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildAccountDropdown(
              label: 'Tài khoản áp dụng khi được cộng tiền (Thu)',
              accounts: accounts,
              value: _incomeAccountId,
              onChanged: (val) {
                setState(() {
                  _incomeAccountId = val;
                  _saveSettings();
                });
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildAccountDropdown({
    required String label,
    required List<Account> accounts,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    final isValueValid = value != null && accounts.any((acc) => acc.id == value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.outline.withAlpha(50)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: isValueValid ? value : null,
              hint: const Text('Chọn tài khoản mặc định'),
              // Đã fix lỗi null với .where((acc) => acc.id != null)
              items: accounts.where((acc) => acc.id != null).map((Account acc) {
                return DropdownMenuItem<int>(
                  value: acc.id!,
                  child: Text(acc.name),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}