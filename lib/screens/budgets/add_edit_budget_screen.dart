import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart'; 
import '../../models/budget.dart'; // Bổ sung Model để nhận dữ liệu truyền vào
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/formatters.dart'; 

class AddEditBudgetScreen extends StatefulWidget {
  final Budget? budget; // Thêm biến nhận dữ liệu

  const AddEditBudgetScreen({super.key, this.budget});
  
  @override
  State<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  
  int? _categoryId;
  int? _accountId;
  String _period = 'monthly';
  DateTime _startDate = DateTime.now(); 
  DateTime? _endDate; 

  final Map<String, String> _periodOptions = {
    'none': 'Không lặp lại',
    'daily': 'Theo ngày',
    'weekly': 'Theo tuần',
    'monthly': 'Theo tháng',
    'quarterly': 'Theo quý',
    'yearly': 'Theo năm',
  };

  bool get isEditMode => widget.budget != null; // Kiểm tra xem đang ở chế độ Thêm hay Sửa

  @override
  void initState() {
    super.initState();
    
    if (isEditMode) {
      // Đổ dữ liệu cũ vào các ô nhập nếu là chế độ Sửa
      final b = widget.budget!;
      _nameController.text = b.name;
      
      String initialAmount = b.amount.toInt().toString();
      String formatted = '';
      int count = 0;
      for (int i = initialAmount.length - 1; i >= 0; i--) {
        if (count != 0 && count % 3 == 0) formatted = '.$formatted';
        formatted = initialAmount[i] + formatted;
        count++;
      }
      _amountController.text = formatted;
      
      _categoryId = b.categoryId;
      _accountId = b.accountId;
      _period = b.period;
      _startDate = b.startDate;
      _endDate = b.endDate;
    } else {
      // Khởi tạo tài khoản mặc định nếu là Thêm mới
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final accounts = context.read<AccountProvider>().accounts;
        if (accounts.isNotEmpty) {
          setState(() => _accountId = accounts.first.id);
        }
      });
    }
  }

  @override
  void dispose() { 
    _nameController.dispose(); 
    _amountController.dispose(); 
    super.dispose(); 
  }

  // --- HÀM HIỂN THỊ HỘP THOẠI XÁC NHẬN ---
  void _showConfirmDialog({
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng hộp thoại
              onConfirm(); // Thực thi hành động
            },
            child: const Text('Có', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- LOGIC LƯU HẠN MỨC ---
  Future<void> _executeSave() async {
    final userId = context.read<AuthProvider>().currentUserId;
    bool success;

    if (isEditMode) {
      final updatedBudget = Budget(
        id: widget.budget!.id,
        userId: userId,
        categoryId: _categoryId,
        accountId: _accountId,
        name: _nameController.text.trim(),
        amount: Validators.parseAmount(_amountController.text),
        period: _period,
        startDate: _startDate,
        endDate: _endDate,
        isActive: widget.budget!.isActive,
        createdAt: widget.budget!.createdAt,
        updatedAt: DateTime.now(),
      );
      success = await context.read<BudgetProvider>().updateBudget(updatedBudget);
    } else {
      success = await context.read<BudgetProvider>().addBudget(
        userId: userId, 
        categoryId: _categoryId, 
        accountId: _accountId,
        name: _nameController.text.trim(),
        amount: Validators.parseAmount(_amountController.text), 
        period: _period,
        startDate: _startDate,
        endDate: _endDate,
      );
    }
    
    if (!mounted) return;
    if (success) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tài khoản áp dụng hạn mức'))
      );
      return;
    }

    if (_endDate != null && _endDate!.isBefore(DateTime(_startDate.year, _startDate.month, _startDate.day))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc không được trước ngày bắt đầu'))
      );
      return;
    }

    if (isEditMode) {
      _showConfirmDialog(
        message: 'Chú ý! Dữ liệu bị thay đổi sẽ không thể khôi phục lại được. Bạn có muốn tiếp tục?',
        onConfirm: _executeSave,
      );
    } else {
      await _executeSave();
    }
  }

  // --- LOGIC XOÁ HẠN MỨC ---
  Future<void> _executeDelete() async {
    final userId = context.read<AuthProvider>().currentUserId;
    final success = await context.read<BudgetProvider>().deleteBudget(widget.budget!.id!, userId);
    
    if (!mounted) return;
    if (success) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!isEditMode) return;
    _showConfirmDialog(
      message: 'Chú ý! Dữ liệu bị xoá sẽ không thể khôi phục lại được. Bạn có muốn tiếp tục?',
      onConfirm: _executeDelete,
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null; 
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate, 
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().expenseCategories;
    final accounts = context.watch<AccountProvider>().accounts;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(isEditMode ? 'Sửa hạn mức' : 'Thêm hạn mức'), 
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context))
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              
              // 1. NHẬP SỐ TIỀN
              _label('SỐ TIỀN'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController, 
                keyboardType: TextInputType.number, 
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(), 
                ],
                validator: Validators.amount, 
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                decoration: const InputDecoration(hintText: '0', suffixText: 'đ')
              ),
              const SizedBox(height: 20),

              // 2. TÊN HẠN MỨC
              _label('TÊN HẠN MỨC'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController, 
                validator: (v) => Validators.entityName(v, 'Tên'), 
                decoration: const InputDecoration(hintText: 'VD: Ăn uống tháng này')
              ),
              const SizedBox(height: 20),

              // 3. HẠNG MỤC
              _label('HẠNG MỤC (TÙY CHỌN)'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppTheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _categoryId, 
                    isExpanded: true, 
                    hint: const Text('Tất cả hạng mục'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Tất cả hạng mục')),
                      ...categories.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)))
                    ],
                    onChanged: (v) => setState(() => _categoryId = v)
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. TÀI KHOẢN
              _label('TÀI KHOẢN'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppTheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _accountId, 
                    isExpanded: true, 
                    hint: const Text('Chọn tài khoản'),
                    items: accounts.map((a) => DropdownMenuItem<int?>(value: a.id, child: Text(a.name))).toList(),
                    onChanged: (v) => setState(() => _accountId = v)
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 5. CHU KỲ
              _label('CHU KỲ'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppTheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _period, 
                    isExpanded: true, 
                    items: _periodOptions.entries.map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) => setState(() => _period = v!)
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 6. NGÀY BẮT ĐẦU
              _label('NGÀY BẮT ĐẦU'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickStartDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(Formatters.date(_startDate)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // 7. NGÀY KẾT THÚC
              _label('NGÀY KẾT THÚC'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickEndDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  child: Row(
                    children: [
                      const Icon(Icons.event_busy_outlined, size: 18, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _endDate != null ? Formatters.date(_endDate!) : 'Không xác định',
                          style: TextStyle(color: _endDate != null ? AppTheme.onSurface : AppTheme.onSurfaceVariant),
                        ),
                      ),
                      if (_endDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _endDate = null),
                          child: const Icon(Icons.close, size: 20, color: AppTheme.tertiary),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 8. CỤM NÚT LƯU HOẶC LƯU/XÓA
              if (isEditMode)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _delete,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.tertiary, width: 1.5),
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.tertiary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                          ),
                          child: const Text('Xoá', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                          ),
                          child: const Text('Lưu lại'),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 52, 
                  child: ElevatedButton(onPressed: _save, child: const Text('Lưu hạn mức'))
                ),
                
              const SizedBox(height: 20),
            ]
          )
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8));
}

// Lớp định dạng tiền tệ
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) return newValue.copyWith(text: '');
    String formatted = '';
    int count = 0;
    for (int i = newText.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) formatted = '.$formatted';
      formatted = newText[i] + formatted;
      count++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}