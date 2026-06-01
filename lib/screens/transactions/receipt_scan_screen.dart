import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/receipt/receipt_ocr_service.dart';
import '../../theme/app_theme.dart';

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen>
    with WidgetsBindingObserver {
  final ReceiptOcrService _ocrService = ReceiptOcrService();
  final ImagePicker _imagePicker = ImagePicker();

  CameraController? _cameraController;
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    unawaited(_ocrService.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    // Camera plugin yêu cầu giải phóng controller khi app mất focus để tránh giữ
    // camera sau khi người dùng mở quyền/cài đặt rồi quay lại app.
    if (state == AppLifecycleState.inactive) {
      unawaited(controller.dispose());
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    final permission = await Permission.camera.request();
    if (!mounted) {
      return;
    }

    if (!permission.isGranted) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'CoinNest cần quyền camera để chụp hoá đơn.';
      });
      await _showCameraPermissionDialog();
      return;
    }

    try {
      final cameras = await availableCameras();
      if (!mounted) {
        return;
      }

      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage =
              'Không tìm thấy camera. Bạn vẫn có thể chọn ảnh hoá đơn từ thư viện.';
        });
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController?.dispose();
        _cameraController = controller;
        _isInitializing = false;
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }

      // Genymotion có thể không gắn camera thật; giữ luồng chọn ảnh để người dùng
      // vẫn kiểm thử OCR bằng hoá đơn trong thư viện.
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'Không mở được camera (${error.code}). Hãy thử chọn ảnh hoá đơn từ thư viện.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
        _errorMessage =
            'Không mở được camera. Hãy thử lại hoặc chọn ảnh hoá đơn từ thư viện.';
      });
    }
  }

  Future<void> _showCameraPermissionDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cần quyền camera'),
          content: const Text(
            'Bạn cần cấp quyền camera để chụp hoá đơn. Nếu đã từ chối vĩnh viễn, hãy mở cài đặt ứng dụng để cấp lại quyền.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Để sau'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                unawaited(openAppSettings());
              },
              child: const Text('Mở cài đặt'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _captureReceipt() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isProcessing) {
      return;
    }

    try {
      final image = await controller.takePicture();
      await _scanImage(image.path);
    } on CameraException {
      if (!mounted) {
        return;
      }

      _showSnackBar('Không chụp được ảnh hoá đơn. Hãy thử lại.');
    }
  }

  Future<void> _pickReceiptFromGallery() async {
    if (_isProcessing) {
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );

      if (image == null) {
        return;
      }

      await _scanImage(image.path);
    } catch (_) {
      if (!mounted) {
        return;
      }

      // Android Photo Picker thường cấp quyền theo từng ảnh; nếu plugin hoặc thiết
      // bị yêu cầu quyền riêng, lỗi được gom về thông báo người dùng dễ hiểu.
      _showSnackBar(
        'Không chọn được ảnh hoá đơn. Hãy kiểm tra quyền truy cập thư viện.',
      );
    }
  }

  Future<void> _scanImage(String imagePath) async {
    setState(() => _isProcessing = true);

    try {
      final result = await _ocrService.scanImage(imagePath);
      if (!mounted) {
        return;
      }

      if (result == null) {
        _showSnackBar(
          'CoinNest chưa đọc được tổng tiền. Bạn có thể thử ảnh khác hoặc nhập thủ công.',
        );
        return;
      }

      Navigator.pop(context, result);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Không xử lý được hoá đơn. Hãy thử chụp rõ hơn hoặc chọn ảnh khác.',
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Scan hoá đơn'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: _buildPreview(colorScheme),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing8,
                0,
                AppTheme.spacing8,
                AppTheme.spacing8,
              ),
              child: _buildControls(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ColorScheme colorScheme) {
    final controller = _cameraController;

    if (_isProcessing) {
      return _buildStatusPane(
        colorScheme,
        icon: Icons.document_scanner_outlined,
        message: 'Đang đọc hoá đơn...',
        showLoader: true,
      );
    }

    if (_isInitializing) {
      return _buildStatusPane(
        colorScheme,
        icon: Icons.camera_alt_outlined,
        message: 'Đang mở camera...',
        showLoader: true,
      );
    }

    if (_errorMessage != null) {
      return _buildStatusPane(
        colorScheme,
        icon: Icons.no_photography_outlined,
        message: _errorMessage!,
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return _buildStatusPane(
        colorScheme,
        icon: Icons.camera_alt_outlined,
        message: 'Camera chưa sẵn sàng.',
      );
    }

    return ColoredBox(
      color: AppTheme.inverseSurface,
      child: Center(child: CameraPreview(controller)),
    );
  }

  Widget _buildStatusPane(
    ColorScheme colorScheme, {
    required IconData icon,
    required String message,
    bool showLoader = false,
  }) {
    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(AppTheme.spacing12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppTheme.spacing6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (showLoader) ...[
              const SizedBox(height: AppTheme.spacing8),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _pickReceiptFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn ảnh'),
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing || _errorMessage != null
                  ? null
                  : _captureReceipt,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Chụp'),
            ),
          ),
        ],
      ),
    );
  }
}
