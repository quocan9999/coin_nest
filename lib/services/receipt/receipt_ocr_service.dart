import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../models/receipt_scan_result.dart';

class ReceiptOcrService {
  final TextRecognizer _textRecognizer;

  ReceiptOcrService({TextRecognizer? textRecognizer})
    : _textRecognizer =
          textRecognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  /// Đọc chữ từ ảnh hoá đơn và chỉ trả về dữ liệu đủ tin cậy để người dùng xác nhận.
  Future<ReceiptScanResult?> scanImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return ReceiptOcrParser.parse(recognizedText.text);
  }

  Future<void> dispose() => _textRecognizer.close();
}

class ReceiptOcrParser {
  ReceiptOcrParser._();

  static final RegExp _amountPattern = RegExp(
    r'(?<!\d)(?:\d{1,3}(?:[.,]\d{3})+|\d{4,9})(?!\d)',
  );

  static final RegExp _datePattern = RegExp(
    r'(?<!\d)(\d{1,2}[\/.-]\d{1,2}[\/.-]\d{2,4})(?!\d)',
  );

  static const List<String> _totalKeywords = [
    'tong tien thanh toan',
    'tong tien phai thanh toan',
    'tong cong',
    'tong thanh tien',
    'tong dich vu',
    'tong tien',
    'thanh toan',
  ];

  static const List<String> _ignoredAmountKeywords = [
    'tien khach tra',
    'khach tra',
    'tien thua',
    'tra lai',
    'vat',
    'ma hoa don',
    'ma hd',
    'so hd',
    'so ct',
    'sdt',
    'dien thoai',
    'ngay',
    'gio',
    'ban',
    'nhan vien',
    'thu ngan',
  ];

  static ReceiptScanResult? parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (lines.isEmpty) {
      return null;
    }

    final bestAmount = _selectBestTotal(lines);
    if (bestAmount == null) {
      return null;
    }

    final merchantName = _detectMerchantName(lines);
    final receiptDate = _detectReceiptDate(lines);
    final noteParts = <String>['Hoá đơn', ?merchantName, ?receiptDate];

    return ReceiptScanResult(
      totalAmount: bestAmount,
      merchantName: merchantName,
      receiptDateText: receiptDate,
      generatedNote: noteParts.join(' - '),
      rawText: rawText,
    );
  }

  static int? _selectBestTotal(List<String> lines) {
    _AmountCandidate? best;

    for (final line in lines) {
      final normalizedLine = _normalize(line);
      final matches = _amountPattern.allMatches(line);

      for (final match in matches) {
        final value = _parseAmount(match.group(0)!);
        if (value == null || value < 1000 || value > 999999999999) {
          continue;
        }

        final score = _scoreAmountLine(normalizedLine, value);
        if (score == null) {
          continue;
        }

        final candidate = _AmountCandidate(value: value, score: score);
        if (best == null || candidate.isBetterThan(best)) {
          best = candidate;
        }
      }
    }

    return best?.value;
  }

  /// Heuristic này ưu tiên dòng tổng/thanh toán và loại dòng nhiễu để không lấy nhầm
  /// tiền khách trả, tiền thừa, VAT hoặc mã hoá đơn làm số tiền giao dịch.
  static int? _scoreAmountLine(String normalizedLine, int value) {
    if (_ignoredAmountKeywords.any(normalizedLine.contains)) {
      return null;
    }

    var score = 10;
    for (var i = 0; i < _totalKeywords.length; i++) {
      if (normalizedLine.contains(_totalKeywords[i])) {
        score += 120 - (i * 5);
        break;
      }
    }

    if (normalizedLine.contains('thanh toan')) {
      score += 35;
    }

    if (normalizedLine.contains('tong')) {
      score += 25;
    }

    if (value % 1000 == 0) {
      score += 5;
    }

    return score;
  }

  static int? _parseAmount(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return null;
    }
    return int.tryParse(digits);
  }

  static String? _detectReceiptDate(List<String> lines) {
    for (final line in lines) {
      final match = _datePattern.firstMatch(line);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  static String? _detectMerchantName(List<String> lines) {
    for (final line in lines.take(6)) {
      final normalizedLine = _normalize(line);
      final hasLetters = RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(line);
      if (!hasLetters || _ignoredAmountKeywords.any(normalizedLine.contains)) {
        continue;
      }
      if (normalizedLine.contains('hoa don') ||
          normalizedLine.contains('phieu thanh toan') ||
          normalizedLine.contains('in boi')) {
        continue;
      }
      return line;
    }
    return null;
  }

  static String _normalize(String input) {
    var text = input.toLowerCase();
    const from =
        'áàảãạâấầẩẫậăắằẳẵặđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
    const to =
        'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    for (var i = 0; i < from.length; i++) {
      text = text.replaceAll(from[i], to[i]);
    }
    return text;
  }
}

class _AmountCandidate {
  final int value;
  final int score;

  const _AmountCandidate({required this.value, required this.score});

  bool isBetterThan(_AmountCandidate other) {
    if (score != other.score) {
      return score > other.score;
    }
    return value > other.value;
  }
}
