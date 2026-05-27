import 'package:coin_nest/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Số tiền nhập ở form debt phải vừa parse đúng định dạng tiền Việt,
  // vừa chặn giá trị không thể ghi nhận thành giao dịch hợp lệ.
  group('Kiểm tra số tiền vay và cho vay', () {
    // Chấp nhận hai kiểu phân tách phổ biến mà người dùng có thể nhập.
    test('chấp nhận số tiền dương có định dạng và phân tách hàng nghìn', () {
      expect(Validators.amount('1.234.000'), isNull);
      expect(Validators.amount('1,234,000'), isNull);
      expect(Validators.parseAmount('1.234.000'), 1234000);
      expect(Validators.parseAmount('1,234,000'), 1234000);
    });

    // Chặn đầu vào không phát sinh được khoản vay có ý nghĩa hoặc vượt giới hạn.
    test('từ chối số tiền trống không hợp lệ bằng 0 hoặc quá lớn', () {
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('1000000000000'), isNotNull);
    });
  });

  // Lãi suất là tùy chọn nhưng khi có giá trị phải nằm trong miền phần trăm.
  group('Kiểm tra lãi suất vay và cho vay', () {
    // Bỏ trống tương ứng không tính lãi; cận 0 đến 100 vẫn là hợp lệ.
    test('chấp nhận giá trị trống và giá trị trong phạm vi', () {
      expect(Validators.interestRate(''), isNull);
      expect(Validators.interestRate('0'), isNull);
      expect(Validators.interestRate('12.5'), isNull);
      expect(Validators.interestRate('100'), isNull);
    });

    // Chặn các giá trị không thể diễn giải thành tỷ lệ phần trăm nghiệp vụ.
    test('từ chối lãi suất âm vượt phạm vi hoặc không hợp lệ', () {
      expect(Validators.interestRate('-1'), isNotNull);
      expect(Validators.interestRate('100.1'), isNotNull);
      expect(Validators.interestRate('abc'), isNotNull);
    });
  });
}
