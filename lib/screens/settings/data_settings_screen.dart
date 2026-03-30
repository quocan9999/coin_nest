import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DataSettingsScreen extends StatelessWidget {
  const DataSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Sao lưu & Phục hồi'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Backup section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.cloud_upload_outlined, color: AppTheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Sao lưu dữ liệu', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                ]),
                const SizedBox(height: 12),
                Text('Xuất dữ liệu ra file để sao lưu. Hỗ trợ khôi phục lại khi cần.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 44,
                    child: ElevatedButton(
                      onPressed: () => _showComingSoon(context),
                      child: const Text('Sao lưu ngay'),
                    )),
              ]),
            ),
            const SizedBox(height: 16),

            // Restore section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.cloud_download_outlined, color: AppTheme.loanColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Phục hồi dữ liệu', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                ]),
                const SizedBox(height: 12),
                Text('Nhập file sao lưu để khôi phục dữ liệu.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 44,
                    child: OutlinedButton(onPressed: () => _showComingSoon(context), child: const Text('Chọn file sao lưu'))),
              ]),
            ),
            const SizedBox(height: 24),

            // Danger zone
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer.withAlpha(51),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.error.withAlpha(51)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Vùng nguy hiểm', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.error)),
                const SizedBox(height: 8),
                Text('Xóa tất cả dữ liệu không thể khôi phục.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, height: 44,
                    child: OutlinedButton(
                      onPressed: () => _showComingSoon(context),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)),
                      child: const Text('Xóa toàn bộ dữ liệu'),
                    )),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển')));
  }
}
