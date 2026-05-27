import 'package:coin_nest/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Kiểm tra số tiền vay và cho vay', () {
    test('chấp nhận số tiền dương có định dạng và phân tách hàng nghìn', () {
      expect(Validators.amount('1.234.000'), isNull);
      expect(Validators.amount('1,234,000'), isNull);
      expect(Validators.parseAmount('1.234.000'), 1234000);
      expect(Validators.parseAmount('1,234,000'), 1234000);
    });

    test('từ chối số tiền trống không hợp lệ bằng 0 hoặc quá lớn', () {
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('1000000000000'), isNotNull);
    });
  });

  group('Kiểm tra lãi suất vay và cho vay', () {
    test('chấp nhận giá trị trống và giá trị trong phạm vi', () {
      expect(Validators.interestRate(''), isNull);
      expect(Validators.interestRate('0'), isNull);
      expect(Validators.interestRate('12.5'), isNull);
      expect(Validators.interestRate('100'), isNull);
    });

    test('từ chối lãi suất âm vượt phạm vi hoặc không hợp lệ', () {
      expect(Validators.interestRate('-1'), isNotNull);
      expect(Validators.interestRate('100.1'), isNotNull);
      expect(Validators.interestRate('abc'), isNotNull);
    });
  });
}
