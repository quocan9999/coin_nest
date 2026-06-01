class ReceiptScanResult {
  final int totalAmount;
  final String? merchantName;
  final String? receiptDateText;
  final String generatedNote;
  final String rawText;

  const ReceiptScanResult({
    required this.totalAmount,
    required this.generatedNote,
    required this.rawText,
    this.merchantName,
    this.receiptDateText,
  });
}
