# CoinNest Feature AI API

Backend ASP.NET Core Web API cho các tính năng AI và OTP verification của CoinNest.

API này không có database riêng. Flutter gửi dữ liệu tài chính đã tổng hợp lên backend, backend gọi provider AI hoặc SpeedSMS/Firebase Admin rồi trả kết quả về app. API key, SpeedSMS token và Firebase credential chỉ nằm ở backend, không đưa vào Flutter hoặc APK.

## Tính Năng

### 1. Gợi Ý Tiết Kiệm AI

Endpoint:

```text
POST /api/ai/spending-insight
```

Tính năng này nhận báo cáo tài chính tháng, tổng thu, tổng chi, số dư, danh mục chi nổi bật, ngân sách và vay nợ để tạo gợi ý tiết kiệm cho người dùng.

### 2. Trợ Lý Tài Chính AI

Endpoint:

```text
POST /api/ai/financial-assistant
```

Tính năng này trả lời câu hỏi tài chính cá nhân dựa trên dữ liệu tổng hợp từ CoinNest, ví dụ hỏi tháng này chi nhiều nhất vào đâu, ngân sách nào vượt hạn mức, hoặc nên ưu tiên tiết kiệm khoản nào.

### 3. OTP Verification Bằng SpeedSMS

Endpoints:

```text
POST /api/otp/send
POST /api/otp/verify
POST /api/auth/reset-password-by-phone
```

Tính năng này gửi OTP bằng SpeedSMS Android Gateway từ số điện thoại cá nhân của bạn. Backend xác minh OTP, hỗ trợ đăng ký bằng số điện thoại và đặt lại mật khẩu bằng số điện thoại.

## Provider Được Hỗ Trợ

AI provider:

- Groq
- Gemini
- GitHub Models
- OpenRouter

OTP provider:

- SpeedSMS SMS Gateway, dùng `sms_type = 5` để gửi SMS từ điện thoại đang cài app SpeedSMS Gateway.

Firebase:

- Firebase Admin SDK dùng để cập nhật mật khẩu cho tài khoản đăng ký bằng số điện thoại.
- Tài khoản phone được ánh xạ sang synthetic email, ví dụ `84867944070@phone.coinnest.app`.

## Yêu Cầu

- .NET 8 SDK
- Firebase project đã bật Authentication `Email/Password`
- Firebase service account JSON cho Firebase Admin SDK
- Tài khoản SpeedSMS và app `SpeedSMS - SMS Gateway`
- API key của ít nhất một AI provider nếu muốn dùng tính năng AI
- Flutter app CoinNest chạy với `AI_API_BASE_URL` trỏ tới backend này

Không commit API key, token SpeedSMS hoặc Firebase service account JSON vào repo.

## Cấu Trúc Chính

```text
featureAI-API/
  Controllers/
    AiController.cs
    OtpController.cs
  Models/
    SpendingInsightModels.cs
    OtpModels.cs
  Services/
    OpenRouterService.cs
    OtpService.cs
  Program.cs
  appsettings.json
```

## Bộ Lệnh Setup Nhanh

Chạy các lệnh từ root repo `coin_nest`.

### 1. Restore Backend

```powershell
dotnet restore featureAI-API/featureAI-API.csproj
```

Project đã có `UserSecretsId`, nên có thể set User Secrets trực tiếp. Nếu máy bạn chưa nhận User Secrets thì chạy:

```powershell
dotnet user-secrets init --project featureAI-API
```

### 2. Setup AI Provider

Set provider nào bạn có key. Không bắt buộc phải có đủ tất cả provider.

```powershell
dotnet user-secrets set "Groq:ApiKey" "YOUR_GROQ_API_KEY" --project featureAI-API
dotnet user-secrets set "Gemini:ApiKey" "YOUR_GEMINI_API_KEY" --project featureAI-API
dotnet user-secrets set "GitHubModels:Token" "YOUR_GITHUB_PAT" --project featureAI-API
dotnet user-secrets set "OpenRouter:ApiKey" "YOUR_OPENROUTER_API_KEY" --project featureAI-API
```

### 3. Setup OTP Verification Bằng SpeedSMS

`SpeedSms:AccessToken` lấy trong dashboard SpeedSMS.

`SpeedSms:SmsSender` là `deviceId` của điện thoại đang cài app SpeedSMS Gateway. Lấy trong dashboard/app SpeedSMS Gateway sau khi đăng nhập thiết bị.

```powershell
dotnet user-secrets set "SpeedSms:AccessToken" "YOUR_SPEEDSMS_ACCESS_TOKEN" --project featureAI-API
dotnet user-secrets set "SpeedSms:SmsType" "5" --project featureAI-API
dotnet user-secrets set "SpeedSms:SmsSender" "YOUR_SPEEDSMS_GATEWAY_DEVICE_ID" --project featureAI-API
dotnet user-secrets set "SpeedSms:OtpHashSecret" "RANDOM_LONG_SECRET_FOR_OTP_HASH" --project featureAI-API
```

Có thể tùy chỉnh nội dung SMS OTP:

```powershell
dotnet user-secrets set "SpeedSms:OtpContent" "Ma xac thuc CoinNest cua ban la {pin_code}. Ma co hieu luc trong 5 phut." --project featureAI-API
```

Nội dung SMS nên dùng ASCII không dấu để tránh lỗi mã hóa ở một số nhà mạng.

### 4. Setup Firebase Admin Cho OTP

Backend cần Firebase Admin SDK để tạo/cập nhật tài khoản phone synthetic email và đổi mật khẩu khi quên mật khẩu bằng số điện thoại.

Lấy service account JSON:

1. Firebase Console
2. Project settings
3. Service accounts
4. Generate new private key
5. Lưu file JSON ở ngoài repo, ví dụ `E:\secrets\coinnest-firebase-admin.json`

Set đường dẫn file bằng User Secrets:

```powershell
dotnet user-secrets set "Firebase:ServiceAccountPath" "E:\secrets\coinnest-firebase-admin.json" --project featureAI-API
```

Hoặc set trực tiếp JSON nếu môi trường deploy không tiện dùng file:

```powershell
dotnet user-secrets set "Firebase:ServiceAccountJson" "{...json...}" --project featureAI-API
```

Kiểm tra toàn bộ secret đã set:

```powershell
dotnet user-secrets list --project featureAI-API
```

### 5. Start Backend

Chạy backend cho emulator hoặc điện thoại thật trong cùng mạng LAN:

```powershell
dotnet run --project featureAI-API --urls "http://0.0.0.0:5007"
```

Swagger:

```text
http://localhost:5007/swagger
```

### 6. Start Flutter Kết Nối Backend

Android emulator:

```powershell
flutter run --dart-define=AI_API_BASE_URL=http://10.0.2.2:5007
```

Điện thoại thật cùng mạng LAN:

```powershell
flutter run --dart-define=AI_API_BASE_URL=http://YOUR_LAN_IP:5007
```

Web/Desktop local:

```powershell
flutter run --dart-define=AI_API_BASE_URL=http://localhost:5007
```

Nếu điện thoại thật không gọi được backend, kiểm tra:

- Điện thoại và máy chạy backend cùng mạng LAN
- Backend chạy với `http://0.0.0.0:5007`
- Windows Firewall cho phép inbound port `5007`
- Flutter dùng IP LAN của máy, không dùng `localhost`

## Bộ Lệnh Build Và Kiểm Tra

Build backend:

```powershell
dotnet build featureAI-API/featureAI-API.csproj
```

Nếu backend đang chạy và khóa file `.exe` hoặc `.dll`, dừng `dotnet run` bằng `Ctrl+C` rồi build lại.

Build ra thư mục tạm để kiểm tra khi backend vẫn đang chạy:

```powershell
dotnet build featureAI-API/featureAI-API.csproj --no-restore -o .tmp/featureAI-build-check
```

Chạy Flutter analyzer từ root repo:

```powershell
flutter analyze
```

## Test API AI

### Test Gợi Ý Tiết Kiệm AI

```powershell
$body = @{
  userId = "1"
  period = "2026-06"
  totalIncome = 12000000
  totalExpense = 4500000
  balance = 18000000
  topExpenseCategories = @(
    @{ name = "An uong"; amount = 2500000; percent = 55.5 }
  )
  debtSummary = @{
    borrowedRemaining = 3000000
    lentRemaining = 1000000
    overdueCount = 0
  }
  budgetSummary = @{
    activeCount = 2
    exceededCount = 1
    highestUsagePercent = 112
  }
} | ConvertTo-Json -Depth 6

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:5007/api/ai/spending-insight" `
  -ContentType "application/json" `
  -Body $body
```

### Test Trợ Lý Tài Chính AI

```powershell
$body = @{
  userId = "1"
  question = "Thang nay toi chi nhieu nhat vao dau?"
  period = "2026-06"
  reportSummary = @{
    totalIncome = 12000000
    totalExpense = 4500000
    netBalance = 7500000
    accountBalance = 18000000
  }
  topExpenseCategories = @(
    @{ name = "An uong"; amount = 2500000; percent = 55.5 }
  )
  topIncomeCategories = @()
  debtSummary = @{
    borrowedRemaining = 3000000
    lentRemaining = 1000000
    overdueCount = 0
  }
  budgetSummary = @{
    activeCount = 2
    exceededCount = 1
    highestUsagePercent = 112
  }
  recentMessages = @()
} | ConvertTo-Json -Depth 6

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:5007/api/ai/financial-assistant" `
  -ContentType "application/json" `
  -Body $body
```

## Test API OTP Verification

### 1. Gửi OTP Đăng Ký Phone

```powershell
$sendBody = @{
  phone = "+84867944070"
  purpose = "register_phone"
} | ConvertTo-Json

$sendResult = Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:5007/api/otp/send" `
  -ContentType "application/json" `
  -Body $sendBody

$sendResult
```

Response:

```json
{
  "verificationId": "speedsms:register_phone:+84867944070"
}
```

### 2. Xác Minh OTP

Thay `123456` bằng OTP thật nhận được qua SMS.

```powershell
$verifyBody = @{
  verificationId = $sendResult.verificationId
  otpCode = "123456"
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:5007/api/otp/verify" `
  -ContentType "application/json" `
  -Body $verifyBody
```

Response đúng:

```json
{
  "verified": true
}
```

### 3. Đặt Lại Mật Khẩu Bằng Số Điện Thoại

Gửi OTP với purpose `forgot_password` trước:

```powershell
$sendBody = @{
  phone = "+84867944070"
  purpose = "forgot_password"
} | ConvertTo-Json

$sendResult = Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:5007/api/otp/send" `
  -ContentType "application/json" `
  -Body $sendBody
```

Sau đó gọi reset:

```powershell
$resetBody = @{
  verificationId = $sendResult.verificationId
  otpCode = "123456"
  newPassword = "NewPassword123"
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:5007/api/auth/reset-password-by-phone" `
  -ContentType "application/json" `
  -Body $resetBody
```

## Rate Limit OTP

Backend đang áp dụng các giới hạn sau để giảm rủi ro spam SMS làm tốn tiền:

- 60 giây cho mỗi số điện thoại và mỗi purpose trước khi được gửi lại.
- 5 OTP cho mỗi số điện thoại trong 1 ngày.
- 20 OTP cho mỗi IP trong 1 giờ.
- 3 OTP cho mỗi cặp IP + số điện thoại trong 10 phút.
- 5 lần nhập sai cho mỗi OTP.
- OTP hết hạn sau 5 phút.

Các rate limit này đang dùng `IMemoryCache`, phù hợp local/demo. Khi đưa lên production nhiều instance hoặc cần chống spam bền vững qua restart backend, nên chuyển counter sang Redis hoặc database.

## Dữ Liệu Flutter Gửi Lên

AI endpoints chỉ nhận dữ liệu tổng hợp:

- `userId`
- `period`
- tổng thu, tổng chi, số dư
- danh mục thu/chi nổi bật
- tóm tắt vay nợ
- tóm tắt ngân sách
- một phần lịch sử chat ngắn cho trợ lý tài chính

Flutter không gửi toàn bộ lịch sử giao dịch, mật khẩu, token Firebase hoặc API key provider.

OTP endpoints nhận:

- số điện thoại
- mục đích OTP
- mã OTP khi xác minh

Backend không trả OTP về client.

## Bảo Mật

- Không commit API key vào `appsettings.json`.
- Không commit Firebase service account JSON.
- Không đưa SpeedSMS token vào Flutter hoặc APK.
- Flutter chỉ biết `AI_API_BASE_URL`.
- SpeedSMS token và Firebase credential chỉ nằm ở backend qua User Secrets hoặc environment variables.
- Rate limit local hiện dùng memory cache; production nên dùng Redis/database.

## Troubleshooting

### Flutter Báo Chưa Cấu Hình AI_API_BASE_URL

Chạy lại app với:

```powershell
flutter run --dart-define=AI_API_BASE_URL=http://10.0.2.2:5007
```

Hoặc dùng IP LAN nếu chạy trên điện thoại thật.

### Không Nhận Được SMS OTP

Kiểm tra:

- `SpeedSms:AccessToken` đã đúng.
- `SpeedSms:SmsSender` đúng deviceId của app SpeedSMS Gateway.
- App SpeedSMS Gateway đang online và đăng nhập đúng tài khoản.
- Tài khoản SpeedSMS còn tiền/quota.
- Số điện thoại đúng định dạng Việt Nam.
- Terminal backend có log gọi `POST https://api.speedsms.vn/index.php/sms/send`.

### Nhập OTP Nhưng Báo Sai Hoặc Hết Hạn

Kiểm tra terminal backend:

- Có log `Verifying OTP...` không.
- Response verify là `true` hay `false`.
- Bạn có restart backend sau khi gửi OTP không. Vì OTP đang nằm trong `IMemoryCache`, restart backend sẽ mất OTP.
- Bạn có dùng OTP cũ quá 5 phút không.

### API AI Trả Lỗi 502

Nguyên nhân thường gặp:

- Chưa cấu hình API key provider.
- API key sai hoặc hết quota.
- Provider/model đang lỗi tạm thời.
- Model trả nội dung không đúng JSON schema nên backend reject.

Kiểm tra log terminal đang chạy `dotnet run`.

### Điện Thoại Thật Không Gọi Được Backend

Kiểm tra:

- Dùng IP LAN, không dùng `localhost`.
- Backend chạy bằng `http://0.0.0.0:5007`.
- Windows Firewall cho phép inbound port `5007`.
- Điện thoại và máy tính cùng mạng.
