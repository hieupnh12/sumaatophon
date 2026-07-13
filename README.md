# sumaatophon (phoneShop)

Ứng dụng mua sắm điện thoại premium — Flutter (Android / iOS / Web) + backend Node.js + MySQL.

Người dùng duyệt sản phẩm, đặt hàng, thanh toán PayOS, theo dõi đơn, đánh giá sản phẩm, chat nhân viên, tìm cửa hàng trên bản đồ và quản lý bảo hành.

## Tech stack

| Tầng | Công nghệ |
|------|-----------|
| Mobile / Web | Flutter 3, BLoC, GetIt |
| Backend | Node.js, Express, Socket.IO |
| Database | MySQL (Aiven / VPS) |
| Local cache | SQLite (session, cart cache…) |
| Auth | Firebase Auth, Google Sign-In, OTP |
| Thanh toán | PayOS |
| Push | Firebase Cloud Messaging |
| Bản đồ | Google Maps, Geolocator |

## Tính năng chính

- **Sản phẩm** — danh sách, tìm kiếm, lọc, chi tiết, đánh giá sau đơn hoàn tất
- **Giỏ hàng & Checkout** — mã giảm giá, địa chỉ giao hàng, PayOS QR/WebView
- **Đơn hàng** — lịch sử, chi tiết, trạng thái, đánh giá sản phẩm từ đơn hoàn tất
- **Cửa hàng** — bản đồ Google Maps, gọi điện, chỉ đường
- **Chat** — khách ↔ nhân viên (REST + Socket.IO)
- **Chatbot** — tư vấn điện thoại (rule-based / Gemini)
- **Thông báo** — in-app + push FCM
- **Bảo hành** — sản phẩm đủ điều kiện, gửi yêu cầu bảo hành
- **Hồ sơ** — đăng nhập, địa chỉ, ngôn ngữ (vi / en / ja), dark mode

## Cấu trúc thư mục

```text
sumaatophon/
├── lib/                    # Flutter app
│   ├── core/               # design system, l10n, network, database
│   └── features/           # feature-first (auth, products, cart, orders…)
├── backend/                # REST API + Socket.IO
│   ├── server.js           # entry point
│   ├── src/routes/         # Express routers
│   └── src/services/       # business logic
├── docs/                   # ARCHITECTURE, API, feature SPEC
├── test/                   # Flutter unit/widget tests
└── assets/images/          # hình ảnh UI
```

Luồng dữ liệu chuẩn:

```text
Page/Widget → BLoC → Repository → DataSource → REST API / SQLite
```

Chi tiết: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

## Yêu cầu

- Flutter SDK `>=3.2.3`
- Node.js 18+
- MySQL (local hoặc Aiven)
- Firebase project (Auth, FCM)
- Google Maps API key (tab Cửa hàng)
- PayOS credentials (thanh toán — tùy chọn khi dev)

## Chạy backend

```bash
cd backend
cp .env.example .env   # điền DB_HOST, DB_USER, DB_PASSWORD, DB_NAME…
npm install
npm run dev            # http://localhost:3000
```

Kiểm tra kết nối DB:

```bash
npm run test:db
```

Migration (chạy khi cần):

```bash
node migrate-db.js
node migrate-stores.js
node migrate-addresses.js
```

Firebase Admin (push notification): đặt `backend/firebase-service-account.json` (đã ignore trong git).

## Chạy Flutter

```bash
flutter pub get
flutter run
```

### API khi dev trên máy thật

App tự chọn base URL theo môi trường (`lib/core/network/api_config.dart`):

| Môi trường | URL |
|------------|-----|
| Release | `https://maclenin.io.vn/mobile` |
| Emulator Android | `http://10.0.2.2:3000` |
| Máy thật + USB (`adb reverse`) | `http://127.0.0.1:3000` |
| Web debug | `http://localhost:3000` |

USB + backend local:

```bash
adb reverse tcp:3000 tcp:3000
cd backend && npm run dev
```

WiFi (không USB): chạy với IP máy tính:

```bash
flutter run --dart-define=LOCAL_API_HOST=192.168.x.x
```

### Google Maps

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
```

## API

Contract REST: [`docs/API.md`](docs/API.md)

Một số endpoint tiêu biểu:

| Method | Path | Mô tả |
|--------|------|-------|
| GET | `/health` | Health check |
| GET | `/products` | Danh sách sản phẩm |
| GET | `/stores` | Danh sách cửa hàng |
| POST | `/products/:id/feedbacks` | Gửi đánh giá sản phẩm |
| GET | `/api/orders` | Đơn hàng của khách |
| POST | `/api/payments/payos/create` | Tạo link thanh toán |

## Kiểm tra & chất lượng code

```bash
flutter analyze
flutter test
```

## Tài liệu cho developer / AI agent

| File | Nội dung |
|------|----------|
| [`AGENTS.md`](AGENTS.md) | Quy chuẩn thêm/sửa feature |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Kiến trúc tầng |
| [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) | Đặt tên, coding style |
| [`docs/API.md`](docs/API.md) | REST API contract |
| [`docs/features/`](docs/features/) | SPEC từng feature |

Khi thêm feature mới: tạo `docs/features/<tên>/SPEC.md`, thêm l10n (`vi` / `en` / `ja`), đăng ký DI trong `lib/main.dart`.

## Deploy production

Backend deploy lên VPS (Docker + Nginx proxy `/mobile/`). Sau khi thêm route mới (vd. feedback, stores), cần deploy backend để app production hoạt động đầy đủ.

Flutter build release:

```bash
flutter build apk
flutter build ios
flutter build web
```

## License

Private project — không publish lên pub.dev.
