import 'package:flutter_test/flutter_test.dart';
import 'package:coin_nest/services/receipt/receipt_ocr_service.dart';

void main() {
  group('ReceiptOcrParser', () {
    test('đọc tổng tiền Coffee Binbo', () {
      const text = '''
COFFEE BINBO
HÓA ĐƠN BÀN 10
Giờ bắt đầu: 20:33 10/12/2017
Tổng dịch vụ 89.000
Thanh toán 89.000
Mã hóa đơn 1691
''';

      final result = ReceiptOcrParser.parse(text);

      expect(result?.totalAmount, 89000);
      expect(result?.merchantName, 'COFFEE BINBO');
      expect(result?.receiptDateText, '10/12/2017');
    });

    test('không lấy nhầm tiền khách trả POS365', () {
      const text = '''
HÓA ĐƠN THANH TOÁN
Ngày: 01/02/2022
Milo Dầm 35,000 1 35,000
Tổng thành tiền 167,000
VAT (10%) 0
Tổng cộng 167,000
Tiền khách trả 334,000
Tiền thừa 0
''';

      final result = ReceiptOcrParser.parse(text);

      expect(result?.totalAmount, 167000);
    });

    test('đọc tổng tiền phiếu thanh toán', () {
      const text = '''
PHIẾU THANH TOÁN
24/06/14-20:58:08
Bia hà nội 25.000
Phụ phí nhạc 90.000
Tổng tiền thanh toán: 165.000 đ
''';

      final result = ReceiptOcrParser.parse(text);

      expect(result?.totalAmount, 165000);
    });

    test('ưu tiên thanh toán hơn tổng tiền trước làm tròn', () {
      const text = '''
BÁCH HÓA XANH
Ngày CT: 20/07/2021 06:41
CẢI NGỌT (KG) 17,628
BẦU SAO 19,836
BẮP CẢI TRẮNG (KG) 47,656
Tổng tiền: 85,120
Thanh toán: 85,000
''';

      final result = ReceiptOcrParser.parse(text);

      expect(result?.totalAmount, 85000);
    });
  });
}
