# CoinNest Feature AI API

Backend ASP.NET Core Web API cho card **Gợi ý tiết kiệm AI** trong CoinNest.

API nhận tóm tắt tài chính tháng từ Flutter, gọi AI provider theo thứ tự ưu tiên, rồi trả về JSON gợi ý tiết kiệm/cảnh báo chi tiêu. Backend v1 không dùng SQL Server, không có database riêng, không lưu dữ liệu người dùng.

## Trợ lý tài chính AI

Feature AI hiện hỗ trợ thêm màn **Trợ lý tài chính AI** trong tab **Báo cáo**. Trong danh sách báo cáo, card này đứng đầu và nằm trên card **Tài chính hiện tại**.

- Endpoint: `POST /api/ai/financial-assistant`.
- Request gồm `userId`, `question`, `period`, `reportSummary`, `topExpenseCategories`, `topIncomeCategories`, `debtSummary`, `budgetSummary` và tối đa vài `recentMessages`.
- Response gồm `answer`, `suggestedQuestions`, `model`, `generatedAt`.
- Backend dùng lại hạ tầng provider/model hiện có, không có database riêng và không lưu lịch sử chat.
- Câu hỏi ngoài phạm vi tài chính CoinNest hoặc yêu cầu code/HTML/website/script sẽ được trả lời bằng phản hồi finance-safe.

Ví dụ request:

```powershell
$body = @{
  userId = "1"
  question = "Tháng này tôi chi nhiều nhất vào đâu?"
  period = "2026-06"
  reportSummary = @{
    totalIncome = 12000000
    totalExpense = 4500000
    netBalance = 7500000
    accountBalance = 18000000
  }
  topExpenseCategories = @(
    @{ name = "Ăn uống"; amount = 2500000; percent = 55.5 }
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

Flutter chỉ gửi dữ liệu tổng hợp và history ngắn, không gửi toàn bộ lịch sử giao dịch tháng, mật khẩu, token Firebase hoặc API key.


## Chức năng

- Endpoint chính: `POST /api/ai/spending-insight`
- Nhận dữ liệu tổng hợp: tổng thu, tổng chi, số dư, top danh mục chi tiêu, tóm tắt vay nợ và ngân sách
- Ưu tiên Groq, sau đó fallback GitHub Models, Gemini, cuối cùng OpenRouter
- Ghi nhớ provider/model trả kết quả hợp lệ gần nhất và thử lại provider/model đó trước
- Hậu xử lý số tiền về định dạng Việt Nam, ví dụ `2.850.000 đ`
- Chỉ trả JSON theo schema cố định
- Chặn phản hồi markdown/code hoặc nội dung ngoài phạm vi tài chính cá nhân

## Yêu cầu

- .NET 8 SDK
- Groq API key
- GitHub Models personal access token nếu muốn dùng fallback GitHub Models
- Gemini API key nếu muốn dùng fallback Gemini
- OpenRouter API key nếu muốn dùng fallback OpenRouter
- Flutter app CoinNest đã chạy được

Không commit API key vào repo.

## Cấu hình API key

Vào thư mục API:

```powershell
cd featureAI-API
```

Khởi tạo user-secrets nếu project chưa có:

```powershell
dotnet user-secrets init
```

Lưu API key/token theo provider bạn có:

```powershell
dotnet user-secrets set "Groq:ApiKey" "YOUR_GROQ_API_KEY"
dotnet user-secrets set "GitHubModels:Token" "YOUR_GITHUB_PAT"
dotnet user-secrets set "Gemini:ApiKey" "YOUR_GEMINI_API_KEY"
dotnet user-secrets set "OpenRouter:ApiKey" "YOUR_OPENROUTER_API_KEY"
```

Có thể kiểm tra lại:

```powershell
dotnet user-secrets list
```

Cách khác là dùng environment variable:

```powershell
$env:Groq__ApiKey="YOUR_GROQ_API_KEY"
$env:GitHubModels__Token="YOUR_GITHUB_PAT"
$env:Gemini__ApiKey="YOUR_GEMINI_API_KEY"
$env:OpenRouter__ApiKey="YOUR_OPENROUTER_API_KEY"
```

## Chạy backend

Từ root repo `coin_nest`:

```powershell
dotnet run --project featureAI-API
```

Hoặc từ thư mục `featureAI-API`:

```powershell
dotnet run
```

Profile development hiện dùng:

```text
http://localhost:5007
```

Swagger:

```text
http://localhost:5007/swagger
```

## Test API thủ công

Có thể dùng file:

```text
featureAI-API/featureAI-API.http
```

Hoặc gọi bằng PowerShell:

```powershell
$body = @{
  userId = "1"
  period = "2026-06"
  totalIncome = 12000000
  totalExpense = 4500000
  balance = 18000000
  topExpenseCategories = @(
    @{ name = "Ăn uống"; amount = 2500000; percent = 55.5 }
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
} | ConvertTo-Json -Depth 5

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:5007/api/ai/spending-insight" `
  -ContentType "application/json" `
  -Body $body
```

Response hợp lệ có dạng:

```json
{
  "title": "Chi tiêu cần chú ý",
  "summary": "Bạn đang chi nhiều vào nhóm ăn uống trong tháng này.",
  "severity": "medium",
  "alerts": ["Chi tiêu ăn uống chiếm tỷ trọng cao."],
  "savingTips": ["Đặt hạn mức ăn uống theo tuần."],
  "model": "Groq: llama-3.3-70b-versatile",
  "generatedAt": "2026-06-04T03:00:00Z"
}
```

## Chạy Flutter app để dùng tính năng AI

Backend phải đang chạy trước.

### Android emulator

Emulator Android không gọi được `localhost` của máy tính trực tiếp. Dùng `10.0.2.2`:

```powershell
flutter run --dart-define=AI_API_BASE_URL=http://10.0.2.2:5007
```

### Điện thoại thật

Điện thoại và máy chạy API phải cùng mạng LAN. Lấy IP LAN của máy Windows:

```powershell
ipconfig
```

Ví dụ máy có IP `192.168.1.10`, chạy app bằng:

```powershell
flutter run --dart-define=AI_API_BASE_URL=http://192.168.1.10:5007
```

Nếu điện thoại không gọi được API, kiểm tra Windows Firewall có cho phép cổng `5007` hay không.

### Web/Desktop local

Nếu Flutter chạy ngay trên máy đang chạy backend:

```powershell
flutter run --dart-define=AI_API_BASE_URL=http://localhost:5007
```

## Workflow sử dụng trong app

1. Chạy `featureAI-API`.
2. Chạy Flutter app với `AI_API_BASE_URL`.
3. Đăng nhập CoinNest và bảo đảm app đã có dữ liệu giao dịch tháng hiện tại.
4. Vào màn **Tổng quan**.
5. Card **Gợi ý tiết kiệm AI** nằm dưới card **Tổng số dư**.
6. Bấm **Cập nhật**.
7. Flutter gửi tóm tắt tháng lên backend và hiển thị kết quả AI.

Tính năng này không tự gọi API khi mở màn hình. Người dùng phải bấm **Cập nhật** để tiết kiệm quota AI provider.

## Dữ liệu Flutter gửi lên API

Flutter chỉ gửi dữ liệu tổng hợp:

- `userId`
- `period`
- `totalIncome`
- `totalExpense`
- `balance`
- `topExpenseCategories`
- `debtSummary`
- `budgetSummary`

Flutter không gửi toàn bộ lịch sử giao dịch, ghi chú chi tiết, mật khẩu, token Firebase hoặc dữ liệu đăng nhập.

## Cấu hình provider và model

Danh sách provider/model nằm trong `appsettings.json`. Thứ tự fallback mặc định:

1. Groq
2. GitHub Models
3. Gemini
4. OpenRouter

```json
{
  "Groq": {
    "Models": [
      "llama-3.3-70b-versatile",
      "llama-3.1-8b-instant"
    ]
  },
  "GitHubModels": {
    "Models": [
      "openai/gpt-4.1-mini"
    ]
  },
  "Gemini": {
    "Models": [
      "gemini-2.5-flash"
    ]
  },
  "OpenRouter": {
    "Models": [
      "poolside/laguna-m.1:free",
      "openrouter/free"
    ]
  }
}
```

Danh sách model có thể thay đổi tại đây. Service sẽ thử theo thứ tự provider ở trên, và nếu một provider/model đã trả insight hợp lệ thì request sau sẽ ưu tiên lại provider/model đó trước.

## Troubleshooting

### Flutter báo chưa cấu hình AI_API_BASE_URL

Chạy lại app với:

```powershell
flutter run --dart-define=AI_API_BASE_URL=http://10.0.2.2:5007
```

Hoặc dùng IP LAN nếu chạy trên điện thoại thật.

### API trả lỗi 502

Nguyên nhân thường gặp:

- Chưa cấu hình key của provider hiện tại, ví dụ `Groq:ApiKey`
- API key sai hoặc hết quota
- Provider/model đang lỗi tạm thời
- Model cụ thể không còn endpoint, ví dụ provider trả `No endpoints found`
- Provider bị rate-limit, ví dụ trả `429`
- Model trả nội dung không đúng schema JSON nên backend reject

Kiểm tra log terminal đang chạy `dotnet run`.

### Điện thoại thật không gọi được backend

Kiểm tra:

- Điện thoại và máy Windows cùng mạng
- Dùng IP LAN, không dùng `localhost`
- Windows Firewall cho phép inbound cổng `5007`
- Backend đang chạy ở `http://0.0.0.0:5007` hoặc profile cho phép truy cập từ LAN nếu cần

Nếu `localhost:5007` chỉ bind trong máy, có thể chạy:

```powershell
dotnet run --project featureAI-API --urls "http://0.0.0.0:5007"
```

Sau đó Flutter dùng:

```powershell
flutter run --dart-define=AI_API_BASE_URL=http://YOUR_LAN_IP:5007
```

### Backend build có warning NU1900

Nếu build hiện warning kiểu:

```text
NU1900: Error occurred while getting package vulnerability data
```

Đây thường là lỗi không truy cập được NuGet vulnerability feed trong môi trường mạng hiện tại. Nếu build vẫn `Build succeeded`, API vẫn chạy được.

## Ghi chú bảo mật

- Không commit Groq/GitHub/Gemini/OpenRouter API key.
- Không thêm key vào `appsettings.json`.
- Không đưa key vào Flutter `--dart-define`.
- Flutter chỉ biết base URL của backend, không biết OpenRouter key.
