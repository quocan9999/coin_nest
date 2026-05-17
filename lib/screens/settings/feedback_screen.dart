import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../database/database_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _type = 'improvement';
  int _rating = 5;

  @override
  void dispose() { _titleController.dispose(); _contentController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().currentUserId;
    final db = await DatabaseHelper.instance.database;
    await db.insert('feedbacks', {
      'user_id': userId, 'type': _type,
      'title': _titleController.text.trim(), 'content': _contentController.text.trim(),
      'rating': _rating, 'created_at': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cảm ơn bạn đã góp ý!'), backgroundColor: AppTheme.secondary));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Góp ý'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _label('LOẠI GÓP Ý'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: AppConstants.feedbackTypeLabels.entries.map((e) {
            final sel = _type == e.key;
            return GestureDetector(
              onTap: () => setState(() => _type = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: sel ? AppTheme.primary : AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                child: Text(e.value, style: TextStyle(fontSize: 13, color: sel ? Colors.white : AppTheme.onSurface, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
              ),
            );
          }).toList()),
          const SizedBox(height: 20),
          _label('TIÊU ĐỀ'),
          const SizedBox(height: 8),
          TextFormField(controller: _titleController, validator: (v) => Validators.entityName(v, 'Tiêu đề'), decoration: const InputDecoration(hintText: 'VD: Cải thiện tốc độ')),
          const SizedBox(height: 20),
          _label('NỘI DUNG'),
          const SizedBox(height: 8),
          TextFormField(controller: _contentController, maxLines: 4, validator: (v) => Validators.required(v, 'Nội dung'),
              decoration: const InputDecoration(hintText: 'Chia sẻ ý kiến của bạn...')),
          const SizedBox(height: 20),
          _label('ĐÁNH GIÁ'),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 36, color: i < _rating ? const Color(0xFFFFA726) : AppTheme.outlineVariant),
            ),
          ))),
          const SizedBox(height: 28),
          SizedBox(height: 52, child: ElevatedButton(onPressed: _submit, child: const Text('Gửi góp ý'))),
        ])),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8));
}
