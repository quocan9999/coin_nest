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
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().currentUserId;
    final db = await DatabaseHelper.instance.database;
    await db.insert('feedbacks', {
      'user_id': userId,
      'type': _type,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'rating': _rating,
      'created_at': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cảm ơn bạn đã góp ý!'),
        backgroundColor: AppTheme.colors(context).income,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text('Góp ý'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('LOẠI GÓP Ý'),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.feedbackTypeLabels.entries.map((e) {
                  final sel = _type == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _type = e.key),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.colors(context).primary
                            : AppTheme.colors(context).input,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 13,
                          color: sel
                              ? Theme.of(context).colorScheme.onPrimary
                              : AppTheme.colors(context).textPrimary,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              _label('TIÊU ĐỀ'),
              SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: (v) => Validators.entityName(v, 'Tiêu đề'),
                decoration: InputDecoration(hintText: 'VD: Cải thiện tốc độ'),
              ),
              SizedBox(height: 20),
              _label('NỘI DUNG'),
              SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                validator: (v) => Validators.required(v, 'Nội dung'),
                decoration: InputDecoration(
                  hintText: 'Chia sẻ ý kiến của bạn...',
                ),
              ),
              SizedBox(height: 20),
              _label('ĐÁNH GIÁ'),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 36,
                        color: i < _rating
                            ? AppTheme.colors(context).warning
                            : AppTheme.colors(context).border,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text('Gửi góp ý'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );
}
