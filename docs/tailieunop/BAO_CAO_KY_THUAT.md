# TECHNICAL REPORT: MOBILE ECOMMERCE APPLICATION

**Course:** Flutter Application Development  
**Team Size:** 5 Members  
**Project Name:** sumaatophon (phoneShop)  
**Repository:** `E:/Project/sumaatophon`  
**Version:** 1.0.0+1  
**Ngày lập:** 29/06/2026

---

## 1. Team Introduction

| Full Name | Role | Responsibilities (theo phân công nhiệm vụ) | Contribution |
|-----------|------|---------------------------------------------|--------------|
| **Lê Mỹ Lộc** | Team Leader / Developer | Product List screen, Product Detail screen, tìm kiếm/lọc sản phẩm | 20% |
| **Nguyễn Minh Hiếu** | Developer | Shopping Cart screen, Checkout/Billing screen, PayOS thanh toán, Cart API MySQL | 20% |
| **Nguyễn Nhất Sinh** | Developer | Login screen, Profile screen / Thông tin bảo hành, Firebase Auth, OTP điện thoại | 20% |
| **Dương Trí Toàn** | Developer | Notifications screen, Messaging/Chat screen, FCM, Socket.IO | 20% |
| **Trần Văn Tuấn Minh** | Developer | Map (Store Location) screen, đa ngôn ngữ (vi/en/ja), UI review/đánh giá sao, Google Maps | 20% |

### Phân công chi tiết theo màn hình

| STT | Màn hình / Feature | Thành viên phụ trách | File chính |
|-----|-------------------|----------------------|------------|
| 1 | Login screen | Nguyễn Nhất Sinh | `lib/features/auth/presentation/pages/login_page.dart` |
| 2 | Profile / Bảo hành | Nguyễn Nhất Sinh | `lib/features/profile/presentation/pages/profile_page.dart` |
| 3 | Map (Store Location) + Ngôn ngữ + Review sao | Trần Văn Tuấn Minh | `lib/features/store_locator/`, `lib/core/theme/language_cubit.dart`, `lib/features/products/presentation/widgets/product_review_tile.dart` |
| 4 | Product List screen | Lê Mỹ Lộc | `lib/features/products/presentation/pages/product_list_page.dart` |
| 5 | Product Detail screen | Lê Mỹ Lộc | `lib/features/products/presentation/pages/product_detail_page.dart` |
| 6 | Shopping Cart screen | Nguyễn Minh Hiếu | `lib/features/cart/presentation/pages/cart_page.dart` |
| 7 | Checkout / Billing screen | Nguyễn Minh Hiếu | `lib/features/checkout/presentation/pages/checkout_page.dart` |
| 8 | Notifications screen | Dương Trí Toàn | `lib/features/notifications/presentation/pages/notifications_page.dart` |
| 9 | Messaging / Chat screen | Dương Trí Toàn | `lib/features/chat/presentation/pages/chat_hub_page.dart` |

---

## 2. Case Study

**Project Title:** sumaatophon — Ứng dụng mua sắm điện thoại cao cấp (Phone Shop).

**Domain:** Online Sales System (E-commerce).

**Description:**

sumaatophon là ứng dụng di động Flutter cho phép người dùng tìm kiếm, xem chi tiết và mua điện thoại thông minh. Ứng dụng kết nối backend REST API (Node.js + Express) với cơ sở dữ liệu MySQL trên server; Flutter **không** kết nối trực tiếp MySQL.

Dữ liệu sản phẩm được cache cục bộ bằng SQLite (`products_cache`) để hỗ trợ xem offline sau lần tải đầu. Giỏ hàng và đơn hàng được lưu trên MySQL theo `customer_id` qua API. Xác thực dùng Firebase Auth (Google Sign-In, OTP điện thoại) đồng bộ với backend qua `POST /auth/sync`. Chat nhân viên real-time qua Socket.IO; thông báo đẩy qua Firebase Cloud Messaging (FCM).

**Đối tượng người dùng:** Khách hàng mua điện thoại; Admin hỗ trợ chat (`admin@phoneshop.com`).

---

## 3. Business Analysis / System Design

### 3.1. Requirements

#### Functional Requirements

| ID | Yêu cầu | Màn hình liên quan |
|----|---------|-------------------|
| FR-01 | Đăng nhập / đăng ký / OTP / Google / sinh trắc học | Login |
| FR-02 | Quản lý hồ sơ, đơn hàng, bảo hành | Profile |
| FR-03 | Xem danh sách & chi tiết sản phẩm, tìm kiếm, lọc | Product List, Detail |
| FR-04 | Giỏ hàng: thêm/sửa/xóa, mã giảm giá | Cart |
| FR-05 | Thanh toán: địa chỉ, giao hàng, PayOS | Checkout |
| FR-06 | Thông báo đơn hàng, sản phẩm mới, chat | Notifications |
| FR-07 | Chat bot AI + chat nhân viên real-time | Chat Hub |
| FR-08 | Tìm cửa hàng trên bản đồ | Store Location |
| FR-09 | Đa ngôn ngữ vi / en / ja | Toàn app (`context.tr`) |
| FR-10 | Đánh giá sao & review sản phẩm | Product Detail, Product Card |

#### Non-functional Requirements

| ID | Yêu cầu | Cách đáp ứng |
|----|---------|--------------|
| NFR-01 | Load danh sách sản phẩm < 2s (mạng ổn định) | Shimmer loading, pagination `LoadMoreProductsEvent`, cache SQLite |
| NFR-02 | Bảo mật tài khoản | Firebase Auth, token lưu `flutter_secure_storage`, không lưu plain password |
| NFR-03 | Tính khả dụng offline một phần | `products_cache` SQLite khi API lỗi |
| NFR-04 | Dark / Light mode | `ThemeCubit`, `AppColors`, `AppTheme` |
| NFR-05 | Đa ngôn ngữ | `LanguageCubit` + `app_localizations_{vi,en,ja}.dart` |

### 3.2. Application Architecture

Nhóm sử dụng **feature-first architecture** kết hợp **BLoC** và **get_it** (dependency injection):

```text
Page / Widget
  → Bloc / Cubit
    → Repository (interface)
      → RepositoryImpl
        → RemoteDataSource  → REST API / Socket.IO
        → LocalDataSource   → SQLite (nếu có)
```

**Luồng phụ thuộc chuẩn** (theo `docs/ARCHITECTURE.md`):

```text
Flutter App
  → REST API Backend (Node.js, port 3000/3001)
    → MySQL Database
```

**Các package chính:**

| Package | Mục đích |
|---------|----------|
| `flutter_bloc` | State management |
| `get_it` | Dependency injection (`setupDependencyInjection()` trong `main.dart`) |
| `sqflite` | SQLite local (`products_cache`, users demo) |
| `http` | REST API client |
| `socket_io_client` | Chat real-time |
| `firebase_auth`, `google_sign_in` | Xác thực |
| `firebase_messaging`, `flutter_local_notifications` | Push notification |
| `google_maps_flutter` | Bản đồ cửa hàng (dependency sẵn sàng) |
| `local_auth` | Đăng nhập sinh trắc học |
| `pinput` | Nhập OTP 6 số |

### 3.3. Database Design

#### 3.3.1. MySQL (Backend — nguồn dữ liệu chính)

**Bảng `customers`** — người dùng sau khi sync Firebase:

| Cột | Kiểu | Ràng buộc | Giải thích |
|-----|------|-----------|------------|
| customer_id | INT | PRIMARY KEY AUTO_INCREMENT | ID khách hàng MySQL |
| firebase_uid | VARCHAR | UNIQUE | UID từ Firebase Auth |
| name | VARCHAR | NOT NULL | Tên hiển thị |
| email | VARCHAR | | Email đăng nhập |
| phone | VARCHAR | | Số điện thoại (OTP) |
| gender | TINYINT | | 1=Nam, 2=Nữ |
| role | VARCHAR | | `user` / `admin` |

**Bảng `products`, `product_versions`, `product_items`** — sản phẩm và IMEI tồn kho:

| Bảng | Mô tả |
|------|-------|
| `products` | Thông tin sản phẩm: tên, brand, `warranty_period` (tháng bảo hành) |
| `product_versions` | Phiên bản màu/RAM/ROM, giá |
| `product_items` | IMEI từng máy, `status` = `IN_STOCK` / `SOLD` |

**Bảng `carts`, `cart_items`** — giỏ hàng (theo `docs/features/cart/SPEC.md`):

| Bảng | Cột chính | Giải thích |
|------|-----------|------------|
| `carts` | cart_id, customer_id, status=1 | Mỗi khách 1 cart active |
| `cart_items` | cart_item_id, cart_id, product_version_id, quantity | Số lượng tối đa = số IMEI IN_STOCK |

**Bảng `orders`, `order_details`** — đơn hàng; `warrantyUntil` tính từ `warranty_period`.

**Bảng `feedbacks`** — đánh giá sản phẩm:

| Cột | Kiểu | Giải thích |
|-----|------|------------|
| feedback_id | INT | PK |
| product_id | INT | FK sản phẩm |
| customer_id | INT | Người đánh giá |
| rate | DECIMAL | Điểm 1–5 sao |
| content | TEXT | Nội dung review |
| created_at | DATETIME | Ngày đánh giá |

**Bảng `notifications`** — thông báo in-app:

| Cột | Kiểu | Giải thích |
|-----|------|------------|
| id | VARCHAR/INT | PK |
| customer_id | INT | FK khách hàng |
| type | VARCHAR | `product_new`, `order_status`, `chat_message` |
| title, body | TEXT | Nội dung hiển thị |
| payload | JSON | `orderId`, `productId`, `threadId` |
| is_read | BOOLEAN | Đã đọc chưa |
| created_at | DATETIME | Thời gian tạo |

**Bảng `chat_threads`, `chat_messages`** — chat nhân viên (theo `docs/features/chat/SPEC.md`).

#### 3.3.2. SQLite (Local trên thiết bị)

**Bảng `products_cache`** — cache sản phẩm sau mỗi lần load API thành công:

| Tên cột | Kiểu dữ liệu | Ràng buộc | Giải thích |
|---------|--------------|-----------|------------|
| id | TEXT | PRIMARY KEY | ID sản phẩm |
| name | TEXT | NOT NULL | Tên sản phẩm |
| brand | TEXT | | Hãng (Apple, Samsung...) |
| price | REAL | | Giá hiện tại |
| original_price | REAL | | Giá gốc (nếu giảm giá) |
| image_url | TEXT | | Ảnh thumbnail |
| gallery_images | TEXT | | JSON mảng URL ảnh |
| ram_rom_options | TEXT | | JSON tùy chọn RAM/ROM |
| colors | TEXT | | JSON màu sắc |
| specifications | TEXT | | JSON thông số kỹ thuật |
| rating | REAL | | Điểm trung bình sao |
| review_count | INTEGER | | Số lượt đánh giá |
| is_new | INTEGER | | Badge sản phẩm mới |
| stock_quantity | INTEGER | | Tồn kho tổng hợp |
| cached_at | TEXT | | Thời điểm cache |

**Bảng `users`** (auth local/demo nếu cần): `id`, `name`, `email`, `passwordHash`, `createdAt`.

> **Lưu ý:** Giỏ hàng **không** dùng SQLite — lưu trên MySQL qua REST API (`docs/features/cart/SPEC.md`).

### 3.4. New Technologies (Ngoài chương trình học)

| Công nghệ | Mục đích | File tham chiếu |
|-----------|----------|-----------------|
| **BLoC + get_it** | State management & DI thay Provider thuần | `lib/main.dart`, mọi `*_bloc.dart` |
| **Firebase Auth + Google Sign-In** | Đăng nhập OAuth, OTP | `lib/features/auth/` |
| **Socket.IO** | Chat real-time user ↔ admin | `lib/features/chat/data/datasources/chat_remote_datasource.dart` |
| **PayOS** | Thanh toán QR / chuyển khoản | `lib/features/checkout/presentation/pages/payos_qr_payment_page.dart` |
| **FCM + flutter_local_notifications** | Push notification | `lib/core/notifications/push_notification_service.dart` |
| **Google Maps Flutter** | Định vị cửa hàng (package đã thêm; UI map hiện dùng mock grid) | `pubspec.yaml`, `store_location_page.dart` |

---

## 4. Development Requirements

### 4.1. Implementation Details

| Hạng mục | Chi tiết triển khai |
|----------|---------------------|
| **State Management** | `flutter_bloc`: `AuthBloc`, `ProductBloc`, `CartBloc`, `CheckoutBloc`, `NotificationBloc`, `ChatBloc`, `StoreLocatorBloc`; `ThemeCubit`, `LanguageCubit` |
| **Local Database** | `sqflite` qua `ProductLocalDataSource` — bảng `products_cache` |
| **Remote API** | `ApiClient` + `ApiEndpoints` trong `lib/core/network/` |
| **Remote Auth** | Firebase Auth → `POST /auth/sync` → nhận `UserEntity` có `customer_id` MySQL |
| **Localization** | `context.tr('key')` — 3 ngôn ngữ: `vi`, `en`, `ja` |
| **Design System** | `AppColors`, `AppTheme`, `AppConfirmDialog` cho popup xác nhận |

### 4.2. Testing

| Loại test | Nội dung kiểm tra | File / lệnh |
|-----------|-------------------|-------------|
| **Static analysis** | Lint, type check | `flutter analyze` |
| **Unit test** | Logic CartBloc (promo, tổng tiền), ProductModel parse JSON | `test/` (nếu có) |
| **Widget test** | Nút Add to Cart, empty state giỏ hàng | `flutter test` |
| **Integration test thủ công** | Chat 2 tài khoản user + admin; PayOS sandbox; FCM token đăng ký | Theo `docs/features/chat/SPEC.md` |

### 4.3. Deployment

| Hạng mục | Chi tiết |
|----------|----------|
| **Build Android** | `flutter build apk --release` |
| **Build iOS** | `flutter build ios --release` |
| **Backend** | `npm start` trong `backend/`; deploy Docker + Nginx (`backend/deploy/nginx-maclenin.docker.conf`) |
| **Production API** | `https://maclenin.io.vn/mobile/` — Socket.IO path `/mobile/socket.io`, **bắt buộc `gzip off`** trong Nginx |
| **Proof** | Ảnh chụp build thành công + file APK trong tệp nộp bài |

---

## 5. Demo of Functions — Chi tiết từng màn hình

> Phần này mô tả cụ thể từng màn hình theo đúng code thực tế trong repo, kèm luồng nghiệp vụ, API, state, file và tiêu chí nghiệm thu.

---

### 5.1. Login Screen — Nguyễn Nhất Sinh

#### Mục tiêu
Cho phép người dùng xác thực trước khi dùng giỏ hàng, checkout, chat nhân viên và thông báo cá nhân.

#### File cấu trúc

```text
lib/features/auth/
  domain/entities/user_entity.dart
  domain/repositories/auth_repository.dart
  data/datasources/auth_remote_datasource.dart
  data/datasources/auth_mock_datasource.dart
  data/repositories/auth_repository_impl.dart
  presentation/bloc/auth_bloc.dart
  presentation/pages/login_page.dart          ← LoginScreen
  presentation/pages/register_page.dart
  presentation/pages/forgot_password_page.dart
  presentation/pages/link_phone_page.dart
```

#### Luồng người dùng

1. Mở app → `CheckAuthStatusEvent` kiểm tra session Firebase / secure storage.
2. Chưa đăng nhập → hiển thị `LoginScreen` (hoặc Onboarding trước đó).
3. Người dùng chọn một trong các phương thức:
   - **OTP điện thoại:** nhập SĐT → `OtpRequested` → nhập PIN 6 số (`pinput`) → `OtpLoginSubmitted`.
   - **Google Sign-In:** `GoogleLoginRequested` → Firebase → `syncAuth(idToken)`.
   - **Email/Password:** `LoginSubmitted` (nếu bật form email).
   - **Sinh trắc học:** `BiometricLoginRequested` qua `local_auth`.
   - **Guest:** `GuestLoginRequested` — chỉ xem, không dùng cart/chat thật.
4. Thành công → `AuthenticatedState` → điều hướng `AppMainPage`.
5. Nếu mở login từ giỏ hàng: `LoginScreen(returnAfterAuth: true)` → pop về sau khi auth.

#### API Backend

| Method | Endpoint | Request | Response |
|--------|----------|---------|----------|
| POST | `/auth/sync` | Header: Firebase ID token | `UserModel` (customer_id, role, phone...) |
| POST | `/auth/request-otp` | `{ "phone": "+84..." }` | `{ "devOtp": "123456" }` (môi trường dev) |
| POST | `/auth/verify-otp` | `{ "phone", "otp" }` | `UserModel` |
| POST | `/auth/link-phone` | `{ "phone", "otp", "force" }` | `UserModel` |

#### State Management (`AuthBloc`)

| Event | Kết quả state |
|-------|---------------|
| `OtpRequested` | Gửi OTP, bắt đầu đếm ngược 300s hiệu lực / 60s resend |
| `OtpLoginSubmitted` | `AuthenticatedState` hoặc `AuthError` |
| `GoogleLoginRequested` | Sync backend; lỗi `REQUIRE_PHONE_LINK` → mở `LinkPhonePage` |
| `LogoutRequested` | `UnauthenticatedState` |

#### UI/UX chi tiết

- Animation fade + slide khi mở màn hình (`AnimationController` 1200ms).
- Form OTP: `Pinput` 6 ô, timer hiển thị thời gian còn lại.
- Toggle dark/light qua `ThemeCubit` trên AppBar.
- Mọi label: `context.tr('login_*')`, `email_hint`, `password_hint`...
- Lỗi hiển thị inline dưới OTP hoặc SnackBar.

#### Demo accounts (chat/admin)

| Email | Password | Role |
|-------|----------|------|
| `admin@phoneshop.com` | `password123` | admin |
| `user@phoneshop.com` | `password123` | user |

#### Acceptance criteria

- [ ] Không gọi API trực tiếp từ Widget — chỉ qua `AuthBloc`.
- [ ] Guest không có `customer_id` MySQL → `isRealAuthenticatedState()` = false.
- [ ] `returnAfterAuth` pop đúng sau login từ cart.
- [ ] Text UI đủ 3 ngôn ngữ vi/en/ja.

---

### 5.2. Profile Screen / Thông tin bảo hành — Nguyễn Nhất Sinh

#### Mục tiêu
Tab **Cá nhân** — quản lý tài khoản, xem đơn hàng, truy cập thông tin bảo hành, cài đặt ngôn ngữ/theme.

#### File chính

```text
lib/features/profile/presentation/pages/profile_page.dart
lib/features/profile/presentation/pages/account_info_page.dart
lib/features/orders/presentation/pages/order_list_page.dart
lib/features/orders/presentation/pages/order_detail_page.dart   ← hiển thị bảo hành
lib/features/address/presentation/pages/address_list_page.dart
```

#### Luồng người dùng

1. Tab Profile trong `AppMainPage` → `ProfilePage`.
2. **Guest:** hiển thị `_buildGuestBody` — CTA đăng nhập, liệt kê lợi ích (`profile_guest_feature_3`: xem bảo hành nhanh).
3. **Đã đăng nhập:**
   - Header: avatar DiceBear theo giới tính, tên, email.
   - **Đơn hàng:** shortcut Chờ xử lý / Đang giao / Đánh giá → `OrderListPage`.
   - **Lịch sử giao dịch** → `OrderListPage(titleKey: 'profile_transaction_history')`.
   - **Thông tin bảo hành** (`profile_warranty_info`) — mục menu; dữ liệu bảo hành thực tế hiển thị tại **Order Detail** khi xem đơn đã mua.
   - **Tiện ích:** Thông tin tài khoản → `AccountInfoPage`; Địa chỉ → `AddressListPage`.
   - **Cài đặt:** Ngôn ngữ (bottom sheet 3 lựa chọn), Dark mode (`ThemeCubit`), Đăng xuất (`showLogoutConfirmDialog`).

#### Thông tin bảo hành (nghiệp vụ)

- Backend tính `warrantyUntil` khi tạo order detail:

```text
warrantyUntil = ngày mua + warranty_period (tháng) từ bảng products
```

- File backend: `backend/src/controllers/ordersController.js`
- Hiển thị UI: `order_detail_page.dart` — dòng `order_warranty_until` + ngày.

| Localization key | Tiếng Việt |
|------------------|------------|
| `profile_warranty_info` | Thông tin bảo hành |
| `order_warranty_until` | Bảo hành đến: |

#### State & dữ liệu

- Đọc `AuthBloc` → `AuthenticatedState.user` (name, email, gender, id).
- Không có Bloc riêng cho Profile — UI reactive qua `BlocBuilder<AuthBloc>`.

#### Acceptance criteria

- [ ] Guest thấy CTA login, không thấy dữ liệu nhạy cảm.
- [ ] Đổi ngôn ngữ qua `LanguageCubit.changeLanguage('vi'|'en'|'ja')`.
- [ ] Logout dùng `AppConfirmDialog` chuẩn dự án.
- [ ] Bảo hành hiển thị đúng trên Order Detail sau khi đặt hàng.

---

### 5.3. Map (Store Location) + Ngôn ngữ + Review đánh giá sao — Trần Văn Tuấn Minh

Phần này gồm 3 hạng mục được giao cho Minh.

---

#### 5.3.1. Map — Store Location Screen

##### File chính

```text
lib/features/store_locator/
  presentation/pages/store_location_page.dart
  presentation/bloc/store_locator_bloc.dart
```

##### Luồng người dùng

1. Từ Profile hoặc Checkout (nhận tại cửa hàng) → `Navigator.push` → `StoreLocationPage`.
2. `StoreLocatorBloc` load 3 cửa hàng mock TP.HCM (Q1, Q2, Q7).
3. UI: nền bản đồ mock (`CustomPaint` grid) + marker vị trí + `PageView` card cửa hàng phía dưới.
4. Chạm marker / vuốt card → `SelectStoreEvent` → đồng bộ highlight marker và card.
5. Card hiển thị: tên, khoảng cách, địa chỉ, giờ mở cửa, nút gọi điện (`url_launcher`).

##### Dữ liệu cửa hàng mẫu

| ID | Tên | Địa chỉ |
|----|-----|---------|
| 1 | phoneShop Premium Q1 | 68 Lê Lợi, P. Bến Nghé, Q.1, TP.HCM |
| 2 | phoneShop Mega Mall Q2 | 159 Xa lộ Hà Nội, Thảo Điền, Q.2 |
| 3 | phoneShop Hub Q7 | (mock trong bloc) |

##### Hướng phát triển

- Thay mock grid bằng `GoogleMap` (`google_maps_flutter` đã có trong `pubspec.yaml`).
- Lấy tọa độ GPS thật + API cửa hàng từ backend.

---

#### 5.3.2. Đa ngôn ngữ (vi / en / ja)

##### File chính

```text
lib/core/l10n/app_localizations.dart          ← abstract + extension context.tr()
lib/core/l10n/app_localizations_vi.dart
lib/core/l10n/app_localizations_en.dart
lib/core/l10n/app_localizations_ja.dart
lib/core/theme/language_cubit.dart
```

##### Cách hoạt động

1. `LanguageCubit` mặc định `'vi'`.
2. `MaterialApp` trong `main.dart` đọc `LanguageCubit.state` → `locale`.
3. UI gọi `context.tr('key')` — không hard-code text hiển thị.
4. Profile → bottom sheet chọn ngôn ngữ → `changeLanguage(langCode)`.
5. Review tile format ngày theo locale: `vi` = dd/MM/yyyy, `en` = MMM d yyyy, `ja` = yyyy/MM/dd.

##### Quy tắc đặt key

```text
<feature>_<screen>_<meaning>
Ví dụ: cart_empty_title, checkout_confirm_order, profile_warranty_info
```

##### Checklist l10n

- [ ] Mỗi key mới phải có trong cả 3 file vi, en, ja.
- [ ] Store Location: một số text còn hard-code tiếng Việt (`Tìm cửa hàng quanh bạn`, `Mở cửa:`) — cần bổ sung key khi hoàn thiện.

---

#### 5.3.3. Review & đánh giá sao

##### File chính

```text
lib/features/products/domain/entities/product_feedback.dart
lib/features/products/data/models/product_feedback_model.dart
lib/features/products/presentation/widgets/product_review_tile.dart
lib/features/products/presentation/widgets/product_card.dart        ← sao trên card
lib/features/products/presentation/pages/product_detail_page.dart   ← section reviews
backend/src/services/productService.js → fetchProductFeedbacks()
```

##### API

```text
GET /products/{id}/feedbacks
```

Response mẫu:

```json
[
  {
    "feedbackId": "1",
    "customerName": "Nguyễn Văn A",
    "rate": 5,
    "content": "Máy đẹp, giao nhanh",
    "createdAt": "2026-06-01T10:00:00Z"
  }
]
```

##### UI đánh giá sao

| Vị trí | Hiển thị |
|--------|----------|
| **Product Card** (list) | Icon `star_rounded` màu `#FFB800` + `rating.toStringAsFixed(1)` |
| **Product Detail** | Tổng điểm lớn + 5 sao visual + `reviews_based_on: reviewCount` |
| **ProductReviewTile** | Avatar chữ cái đầu, tên, ngày, 5 sao (filled theo `rate`), nội dung review |

##### Entity `ProductFeedback`

| Field | Kiểu | Mô tả |
|-------|------|-------|
| id | String | feedback_id |
| customerName | String | Tên khách (ẩn nếu "customer" → `product_review_guest`) |
| rate | double | 1.0 – 5.0 |
| content | String | Nội dung |
| createdAt | DateTime? | Ngày đánh giá |

---

### 5.4. Product List Screen — Lê Mỹ Lộc

#### Mục tiêu
Tab **Cửa hàng** — hiển thị lưới sản phẩm, tìm kiếm, lọc, infinite scroll.

#### File chính

```text
lib/features/products/presentation/pages/product_list_page.dart
lib/features/products/presentation/pages/product_search_page.dart
lib/features/products/presentation/widgets/product_card.dart
lib/features/products/presentation/widgets/shimmer_product_card.dart
lib/features/products/presentation/bloc/product_bloc.dart
lib/features/products/data/datasources/product_remote_datasource.dart
lib/features/products/data/datasources/product_local_datasource.dart
```

#### Luồng người dùng

1. Vào tab Shop → `LoadProductsEvent`.
2. Loading → 6 card shimmer (`ShimmerProductCard`).
3. Thành công → `GridView` 2 cột, mỗi ô `ProductCard`.
4. Kéo gần cuối list → `LoadMoreProductsEvent` (pagination).
5. Thanh tìm kiếm → mở `ProductSearchPage` full-screen.
6. Lọc: brand chip (All, Apple, Samsung, Google, Xiaomi), slider giá 0–50.000.000 VNĐ, RAM, ROM.
7. Tap card → `ProductDetailPage(productId)`.
8. Tap icon giỏ → `onOpenCart` callback; icon chuông → `NotificationsPage` + badge unread.

#### API

```text
GET /products?search=&brand=&minPrice=&maxPrice=&ram=&rom=&page=&limit=
```

#### State (`ProductBloc`)

| State | UI |
|-------|-----|
| `ProductLoading` | Shimmer |
| `ProductLoaded` | Grid + `hasMore`, `isLoadingMore` |
| `ProductError` | Error message + retry; fallback SQLite cache nếu có |
| `ProductEmpty` | `not_found_title`, `not_found_desc` |

#### `ProductCard` hiển thị

- Ảnh sản phẩm, badge NEW / giảm giá %.
- Brand, tên, giá (gạch giá gốc nếu `hasDiscount`).
- **Rating sao** + số điểm.
- Nút thêm giỏ nhanh (qua `CartBloc` + `requireAuthForCart`).

#### Cache offline

- Mỗi lần API thành công → ghi `products_cache` SQLite.
- API lỗi + có cache → vẫn hiển thị danh sách cũ.

#### Acceptance criteria

- [ ] Filter không làm vỡ layout 2 cột.
- [ ] Pagination không gọi trùng khi `isLoadingMore`.
- [ ] Badge cart cập nhật qua `BlocBuilder<CartBloc>`.
- [ ] Text UI qua `context.tr()`.

---

### 5.5. Product Detail Screen — Lê Mỹ Lộc

#### Mục tiêu
Hiển thị đầy đủ thông tin một sản phẩm: ảnh, giá, chọn màu/RAM-ROM, thông số, review, thêm giỏ / mua ngay.

#### File chính

```text
lib/features/products/presentation/pages/product_detail_page.dart
lib/features/products/presentation/widgets/product_color_option_tile.dart
lib/features/products/presentation/widgets/product_review_tile.dart
lib/features/products/domain/entities/product_version.dart
```

#### Luồng người dùng

1. Nhận `productId` (+ optional `heroImageUrl` cho Hero animation).
2. `LoadProductByIdEvent` → API `GET /products/{id}` + `GET /products/{id}/feedbacks`.
3. Chọn **màu** và **RAM/ROM** → cập nhật `ProductVersion` (giá, stock IMEI).
4. Sections: mô tả, thông số kỹ thuật (scroll tới `_specsKey`), **Reviews** với tổng sao và danh sách `ProductReviewTile`.
5. Bottom bar:
   - **Thêm vào giỏ** → `AddToCartEvent(product, version)` — yêu cầu auth.
   - **Mua ngay** → thêm giỏ + `Navigator.push(CheckoutPage)`.

#### Dữ liệu `Product` / `ProductVersion`

| Field Product | Mô tả |
|---------------|-------|
| specifications | Map (Display, Chip, Warranty = X months...) |
| galleryImages | Carousel ảnh |
| ramRomOptions, colors | Selector |
| rating, reviewCount | Tổng hợp từ `feedbacks` |
| feedbacks | `List<ProductFeedback>` |

| Field ProductVersion | Mô tả |
|---------------------|-------|
| id | `product_version_id` — dùng cho cart |
| color, ramRom | Biến thể |
| price, stockQuantity | Giá & tồn IMEI |

#### Hero animation

```dart
Hero(tag: 'product_image_${productId}', ...)
```

#### Acceptance criteria

- [ ] Không add to cart khi chưa chọn version hợp lệ.
- [ ] Stock = 0 → disable nút / thông báo hết hàng.
- [ ] Reviews empty → `product_reviews_empty`.
- [ ] Buy now chỉ với user có `customer_id` thật.

---

### 5.6. Shopping Cart Screen — Nguyễn Minh Hiếu

#### Mục tiêu
Quản lý giỏ hàng đồng bộ MySQL: chọn item, sửa số lượng, mã giảm giá, chuyển checkout.

#### File chính

```text
lib/features/cart/presentation/pages/cart_page.dart
lib/features/cart/presentation/widgets/cart_item_tile.dart
lib/features/cart/presentation/widgets/cart_summary.dart
lib/features/cart/presentation/bloc/cart_bloc.dart
lib/features/cart/presentation/cart_auth_helper.dart
lib/features/cart/data/datasources/cart_remote_datasource.dart
```

#### Luồng người dùng

1. Mở tab Giỏ hàng hoặc từ Product List.
2. Chưa đăng nhập thật → `requireAuthForCart` / `LoginScreen(returnAfterAuth: true)`.
3. Đã đăng nhập → `SyncCartCustomerEvent(customerId)` → `GET /api/cart?customerId=`.
4. Danh sách `CartItemTile`: ảnh, tên, màu/RAM-ROM, giá, +/- quantity, checkbox chọn.
5. `CartSummary`: subtotal, promo code (`ApplyPromoCodeEvent`), discount, nút Checkout.
6. Giỏ trống → empty state (`cart_empty_title`, `cart_empty_desc`, `explore_now`).

#### API Cart

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/cart?customerId=` | Lấy giỏ enriched |
| POST | `/api/cart/items` | `{ customerId, productVersionId }` |
| PUT | `/api/cart/items/:productVersionId` | Cập nhật quantity |
| DELETE | `/api/cart/items/:productVersionId` | Xóa 1 item |
| DELETE | `/api/cart?customerId=` | Xóa toàn bộ |

#### Quy tắc nghiệp vụ

- Quantity tối thiểu = 1; tối đa = số IMEI `IN_STOCK`.
- Cùng `product_version_id` → gộp dòng, tăng quantity.
- Promo code xử lý local trong `CartBloc` (ví dụ `APPLE10`).
- Chỉ item **được chọn** (`selectedVersionIds`) mới đưa vào checkout.

#### State (`CartBloc`)

| Event | Hành vi |
|-------|---------|
| `AddToCartEvent` | POST API + emit `lastAddedProduct` cho snackbar |
| `UpdateQuantityEvent` | PUT API, validate stock |
| `ToggleCartItemSelectionEvent` | Chọn/bỏ chọn từng dòng |
| `ApplyPromoCodeEvent` | Tính `discountAmount` |
| `ClearCartEvent` | Sau đặt hàng thành công |

#### Localization keys quan trọng

```text
cart, cart_empty_title, cart_empty_desc
cart_login_required, cart_max_stock_reached
cart_version_stock, explore_now
```

#### Acceptance criteria

- [ ] Guest / biometric demo không sync cart MySQL.
- [ ] Quantity không vượt stock IMEI.
- [ ] Promo hiển thị tổng sau giảm giá đúng.
- [ ] SQLite cart **không** dùng (theo SPEC mới).

---

### 5.7. Checkout / Billing Screen — Nguyễn Minh Hiếu

#### Mục tiêu
Thu thập thông tin giao hàng / nhận tại cửa hàng, chọn thanh toán, tạo đơn hàng, tích hợp PayOS.

#### File chính

```text
lib/features/checkout/presentation/pages/checkout_page.dart
lib/features/checkout/presentation/pages/payos_qr_payment_page.dart
lib/features/checkout/presentation/widgets/checkout_info_tab.dart
lib/features/checkout/presentation/widgets/checkout_payment_tab.dart
lib/features/checkout/presentation/widgets/checkout_bottom_bar.dart
lib/features/checkout/presentation/bloc/checkout_bloc.dart
lib/features/checkout/data/datasources/checkout_remote_datasource.dart
lib/features/checkout/data/datasources/payment_remote_datasource.dart
```

#### Luồng người dùng

1. Từ `CartPage` (item đã chọn) hoặc Buy Now → `CheckoutPage`.
2. `InitializeCheckoutEvent` — điền sẵn tên, SĐT, email từ `AuthBloc`.
3. **Tab Thông tin** (`CheckoutStep.information`):
   - Thông tin khách hàng + ghi chú VAT.
   - Nhận hàng: **Tại cửa hàng** (`ApplyDefaultPickupStoreEvent`) hoặc **Giao tận nơi** (tỉnh/quận/phường, địa chỉ, tốc độ giao, hóa đơn công ty).
4. **Tab Thanh toán** (`CheckoutStep.payment`):
   - Chọn phương thức: COD, chuyển khoản, **PayOS QR**.
   - Bottom bar: tạm tính, tiết kiệm, phí ship, tổng, nút xác nhận.
5. Submit → `POST /api/orders` → nếu PayOS → mở `PayOsQrPaymentPage` poll trạng thái.
6. Thành công → clear cart, push notification đơn hàng, dialog success.

#### Công thức tổng tiền

```text
total = subtotal(selected items) - discount + shippingCost
```

#### API Orders / Payment

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/orders` | Tạo đơn + gán IMEI SOLD + clear cart |
| GET | `/api/payments/payos/status/:orderId` | Poll PayOS |

#### State (`CheckoutBloc`)

| Event | Mô tả |
|-------|-------|
| `SetCheckoutStepEvent` | Chuyển tab Thông tin ↔ Thanh toán |
| `SetDeliveryMethodEvent` | Pickup vs delivery |
| `SubmitOrderEvent` | Loading `isProcessing` |
| `CompletePayOsPaymentEvent` | Kết quả thanh toán QR |

#### Acceptance criteria

- [ ] Không submit khi cart selection rỗng.
- [ ] Loading state khi đang tạo đơn.
- [ ] Thành công → `ClearCartEvent` + notification.
- [ ] Lỗi → `checkout_submit_error` thân thiện.

---

### 5.8. Notifications Screen — Dương Trí Toàn

#### Mục tiêu
Hiển thị thông báo in-app the push từ backend/FCM: sản phẩm mới, trạng thái đơn, tin nhắn chat.

#### File chính

```text
lib/features/notifications/presentation/pages/notifications_page.dart
lib/features/notifications/presentation/bloc/notification_bloc.dart
lib/features/notifications/presentation/notification_helpers.dart
lib/features/notifications/presentation/widgets/notification_badge_icon.dart
lib/features/notifications/data/datasources/notification_remote_datasource.dart
lib/core/notifications/push_notification_service.dart
backend/src/routes/notifications.js
```

#### Luồng người dùng

1. Icon chuông trên Product List → `NotificationsPage`.
2. Chưa login → CTA mở `LoginScreen`.
3. Đã login → `LoadNotificationsEvent(customerId)`.
4. Hai tab: **Sản phẩm** (`productNew`) | **Đơn hàng & Chat** (`orderStatus`, `chatMessage`).
5. Tap item → đánh dấu đọc + điều hướng:
   - `productNew` → `ProductDetailPage(productId)`.
   - `orderStatus` → `OrderDetailPage(orderId)`.
   - `chatMessage` → `ChatHubPage(openStaffTab: true)`.
6. Vuốt trái (`flutter_slidable`) → xóa (`DeleteNotificationEvent`).
7. Menu → Đánh dấu tất cả đã đọc.

#### API

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/notifications?customerId=` | Danh sách + `unreadCount` |
| PATCH | `/notifications/:id/read` | Đánh dấu 1 |
| POST | `/notifications/read-all` | Đánh dấu tất cả |
| DELETE | `/notifications/:id` | Xóa |
| POST | `/notifications/register-token` | Đăng ký FCM token |

#### Entity `AppNotification`

| Field | Mô tả |
|-------|-------|
| type | `productNew`, `orderStatus`, `chatMessage` |
| title, body | Hiển thị trên list |
| payload | JSON: `orderId`, `productId`, `threadId` |
| isRead | Trạng thái đọc |

#### FCM tích hợp

- `PushNotificationService` đăng ký token khi user login.
- Backend gửi notification khi: thanh toán thành công, admin trả lời chat, sản phẩm mới.

#### Acceptance criteria

- [ ] Badge unread trên icon chuông đúng `unreadCount`.
- [ ] Đổi user → `ClearNotificationsEvent` + reload.
- [ ] Deep link đúng màn hình theo `type`.
- [ ] Slidable delete hoạt động với haptic feedback.

---

### 5.9. Messaging / Chat Screen — Dương Trí Toàn

#### Mục tiêu
Tab **Hỗ trợ** — Chatbot AI tư vấn + Chat nhân viên real-time (Socket.IO).

#### File chính

```text
lib/features/chat/presentation/pages/chat_hub_page.dart
lib/features/chat/presentation/pages/chat_conversation_page.dart
lib/features/chat/presentation/pages/admin_inbox_page.dart
lib/features/chat/presentation/bloc/chat_bloc.dart
lib/features/chat/data/datasources/chat_remote_datasource.dart
lib/features/chatbot/presentation/pages/chatbot_page.dart
backend/chat.js, backend/src/routes/chat (REST)
```

#### Luồng người dùng — User

1. Tab Hỗ trợ → `ChatHubPage` — 2 tab: **Bot tư vấn** | **Nhân viên**.
2. Tab Bot → `ChatbotPage` — gợi ý câu hỏi, hỏi giá/tồn kho/chính sách bảo hành.
3. Tab Nhân viên → yêu cầu `user.canUseStaffChat` (đã login thật).
4. `InitChatEvent(user)` → REST lấy thread + Socket.IO connect.
5. `ChatConversationPage` — gửi `SendMessageEvent` → event `send_message`.
6. Nhận `new_message` real-time → cập nhật list.

#### Luồng — Admin

1. Login `admin@phoneshop.com` → tab Nhân viên → `AdminInboxPage`.
2. Danh sách thread → chọn user → `join_thread` → trả lời.
3. `threads_updated` khi có tin mới.

#### REST API

| Method | Path | Mô tả |
|--------|------|-------|
| GET | `/chat/threads/mine?userId=` | User: lấy/tạo thread |
| GET | `/chat/threads?role=admin` | Admin: inbox |
| GET | `/chat/threads/:id/messages` | Lịch sử tin |

#### Socket.IO

| Môi trường | Origin | Path |
|------------|--------|------|
| Local | `http://127.0.0.1:3000` | `/socket.io` |
| Production | `https://maclenin.io.vn` | `/mobile/socket.io` |

| Event | Hướng | Payload |
|-------|-------|---------|
| `send_message` | Client → Server | `{ threadId, text }` |
| `new_message` | Server → Client | `ChatMessageEntity` |
| `join_thread` | Admin → Server | thread room |
| `threads_updated` | Server → Admin | danh sách thread |

**Cấu hình Nginx:** `gzip off` trong `location ^~ /mobile/` — tránh timeout Socket.IO polling.

#### State (`ChatBloc`)

| State field | Mô tả |
|-------------|-------|
| threads | Inbox admin |
| activeThread | Thread đang mở |
| messages | Tin nhắn thread hiện tại |
| isLoading, isSending | UX loading |
| error | `ChatSocketException` — timeout / handshake |

#### Acceptance criteria

- [ ] Guest không init staff chat.
- [ ] Tin gửi/nhận real-time giữa 2 client (Chrome + Edge test).
- [ ] Lỗi socket hiển thị `chat_error_socket_*` + hint production/nginx.
- [ ] Chat message tạo notification `chatMessage`.

---

## 6. Conclusion and Discussion

### Ưu điểm (Pros)

- Kiến trúc **feature-first + BLoC** rõ ràng, dễ bảo trì và mở rộng từng màn hình độc lập.
- **MySQL + REST API** quản lý giỏ hàng, đơn hàng, IMEI tồn kho chính xác cho điện thoại.
- **Cache SQLite** giúp xem sản phẩm khi mất mạng tạm thời.
- **Đa ngôn ngữ** vi/en/ja và dark mode đầy đủ.
- **Chat real-time** và **FCM notification** nâng trải nghiệm hỗ trợ khách hàng.
- **PayOS** tích hợp thanh toán QR thực tế.

### Hạn chế (Cons)

- Màn **Store Location** vẫn dùng bản đồ mock, chưa gắn `GoogleMap` và API cửa hàng thật.
- Mục **Thông tin bảo hành** trên Profile chưa có màn riêng — dữ liệu xem qua Order Detail.
- Một số chuỗi UI Store Location chưa qua l10n.
- Phụ thuộc server production (Nginx, Socket.IO path) khi demo chat ngoài local.

### Bài học (Learning)

- Kết hợp **Firebase Auth** với **backend sync** để có `customer_id` MySQL thống nhất.
- Tách **Remote vs Local datasource** giúp xử lý offline có kiểm soát.
- Triển khai **Socket.IO qua Nginx reverse proxy** cần cấu hình `gzip off`, `Upgrade` headers.

### Hướng cải tiến (Future Improvements)

- Google Maps thật + định vị GPS cho Store Locator.
- Màn Warranty riêng: tra cứu IMEI / QR trên máy đã mua.
- Đánh giá sản phẩm từ app (POST feedback) sau khi nhận hàng.
- Admin dashboard web quản lý kho, đơn hàng, chat.

---

## 7. Contribution Table

| Topic | Effort | Lê Mỹ Lộc | Nguyễn Minh Hiếu | Nguyễn Nhất Sinh | Dương Trí Toàn | Trần Văn Tuấn Minh |
|-------|--------|-----------|------------------|------------------|----------------|---------------------|
| Case Study Analysis | 100% | 20% | 20% | 20% | 20% | 20% |
| Business Analysis | 100% | 20% | 20% | 20% | 20% | 20% |
| System Design | 100% | 25% | 20% | 15% | 20% | 20% |
| **Login Screen** | 100% | — | — | **100%** | — | — |
| **Profile / Bảo hành** | 100% | — | — | **100%** | — | — |
| **Map + Ngôn ngữ + Review sao** | 100% | — | — | — | — | **100%** |
| **Product List** | 100% | **100%** | — | — | — | — |
| **Product Detail** | 100% | **100%** | — | — | — | — |
| **Shopping Cart** | 100% | — | **100%** | — | — | — |
| **Checkout / Billing** | 100% | — | **100%** | — | — | — |
| **Notifications** | 100% | — | — | — | **100%** | — |
| **Messaging / Chat** | 100% | — | — | — | **100%** | — |
| Documentation | 100% | 20% | 20% | 20% | 20% | 20% |
| Testing & Deployment | 100% | 20% | 20% | 20% | 20% | 20% |

---

## 8. References

| Tài liệu | URL / Đường dẫn |
|----------|-----------------|
| Flutter Documentation | https://docs.flutter.dev/ |
| flutter_bloc | https://pub.dev/packages/flutter_bloc |
| get_it (DI) | https://pub.dev/packages/get_it |
| sqflite | https://pub.dev/packages/sqflite |
| Firebase Auth | https://firebase.google.com/docs/auth |
| Socket.IO Client Dart | https://pub.dev/packages/socket_io_client |
| Google Maps Flutter | https://pub.dev/packages/google_maps_flutter |
| PayOS | https://pay.payos.vn/web4c/docs/ |
| **Nội bộ dự án** | |
| Kiến trúc | `docs/ARCHITECTURE.md` |
| API Contract | `docs/API.md` |
| Database local | `docs/DATABASE.md` |
| Feature SPEC | `docs/features/*/SPEC.md` |
| Agent playbook | `AGENTS.md` |
| Nginx deploy chat | `backend/deploy/nginx-maclenin.docker.conf` |

---

*Tài liệu được biên soạn theo template `docs/tailieunop/docPrmTemp.md`, đối chiếu trực tiếp với mã nguồn `sumaatophon` tại nhánh hiện tại.*
