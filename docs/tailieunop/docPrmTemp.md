TECHNICAL REPORT: MOBILE ECOMMERCE APPLICATION

Course: Flutter Application Development

Team Size: 5 Members

Project Name: SmartStore App



1. Team Introduction

Full Name

Role

Responsibilities

Contribution

Lê Mỹ Lộc

Team Leader / Developer

Firebase Auth, SQLite Database Design, Checkout Logic

20%

Nguyễn Minh Hiếu

Developer

UI Design (Login, Product, Cart), Notification UI

20%

Nguyễn Nhất Sinh 

Developer

State Management (Provider), Maps Integration, Chat UI

20%

Dương Trí Toàn

Developer



20%

Trần Văn Tuấn Minh

Developer



20%



2. Case Study

Project Title: SmartStore - Giải pháp mua sắm phụ kiện công nghệ cho sinh viên.

Domain: Online Sales System (E-commerce).

Description:

SmartStore là ứng dụng di động cho phép người dùng tìm kiếm và mua sắm các thiết bị điện tử. Do đặc thù người dùng thường xuyên di chuyển và có thể mất kết nối mạng, ứng dụng sử dụng SQLite để lưu trữ giỏ hàng và danh sách yêu thích cục bộ, đồng thời dùng Firebase để quản lý tài khoản người dùng bảo mật.



3. Business Analysis / System Design

3.1. Requirements

Functional Requirements: Đăng nhập, Xem sản phẩm, Quản lý giỏ hàng, Thanh toán, Xem vị trí cửa hàng, Chat với hỗ trợ.

Non-functional Requirements:

Hiệu năng: Load danh sách sản phẩm < 2s.

Bảo mật: Mật khẩu người dùng được quản lý bởi Firebase Auth.

Tính khả dụng: Giao diện trực quan, hỗ trợ chế độ Offline cho giỏ hàng.

3.2. Application Architecture

Nhóm sử dụng mô hình Provider kết hợp với kiến trúc phân lớp:

UI Layer: Các Widget hiển thị giao diện.

Business Logic Layer (Provider): Xử lý luồng dữ liệu, tính toán giá tiền giỏ hàng.

Data Layer: Kết nối Firebase Auth và SQLite Helper.

3.3. Database Design (SQLite)

Bảng Cart:

Tên cột

Kiểu dữ liệu

Ràng buộc

Giải thích

id

INTEGER

PRIMARY KEY AUTOINCREMENT

ID tự tăng để quản lý các dòng trong DB.

user_id

TEXT

NOT NULL

Lưu UID từ Firebase. Dùng để lọc giỏ hàng đúng người dùng.

product_id

TEXT

NOT NULL

ID của sản phẩm để kiểm tra trùng lặp khi "Add to Cart".

product_name

TEXT

NOT NULL

Tên phụ kiện (hiển thị trên màn hình giỏ hàng).

price

REAL

NOT NULL

Giá sản phẩm tại thời điểm bỏ vào giỏ.

quantity

INTEGER

NOT NULL

Số lượng (Mặc định ban đầu là 1).

image_url

TEXT



Link ảnh để hiển thị thumbnail trong giỏ hàng.



3.4. New Technologies (Ngoài chương trình học)

Google Maps Flutter: Tích hợp bản đồ để định vị cửa hàng.

Firebase Authentication: Giải pháp đăng nhập bảo mật không cần tự xây dựng server riêng.



4. Development Requirements

4.1. Implementation Details

State Management: Sử dụng ChangeNotifierProvider để quản lý trạng thái giỏ hàng và danh sách sản phẩm trên toàn ứng dụng.

Local Database: Sử dụng thư viện sqflite để lưu trữ dữ liệu giỏ hàng bền vững ngay cả khi đóng app.

Remote Auth: Firebase Auth xử lý đăng ký/đăng nhập qua Email & Password.

4.2. Testing

Unit Test: Kiểm tra logic tính tổng tiền giỏ hàng trong CartProvider.

Widget Test: Kiểm tra xem nút "Add to Cart" có hiển thị đúng trên Product Detail screen hay không.

4.3. Deployment

Build Mode: Release Mode (flutter build apk --release).

Proof: (Nhóm sẽ đính kèm ảnh chụp màn hình chạy lệnh build thành công và file APK trong tệp nộp bài).



5. Demo of Functions

Database/API Structure: Thiết kế Schema SQLite và cấu trúc JSON cho danh sách sản phẩm.

Login Screen: Giao diện đăng nhập/đăng ký kết nối Firebase.

Product List: Hiển thị danh sách sản phẩm dạng GridView.

Product Detail: Thông tin chi tiết, giá và nút thêm vào giỏ hàng.

Shopping Cart: Hiển thị các sản phẩm đã chọn từ SQLite, cho phép tăng/giảm số lượng.

Checkout Screen: Form nhập thông tin giao hàng và xác nhận đơn đơn hàng.

Notifications: Hiển thị danh sách các ưu đãi hoặc trạng thái đơn hàng.

Map Screen: Hiển thị vị trí cửa hàng SmartStore trên Google Maps.

Messaging Screen: Giao diện chat hỗ trợ khách hàng (Mockup/Firebase Realtime).

State Management: Toàn bộ ứng dụng được đồng bộ dữ liệu thông qua Provider.



6. Conclusion and Discussion

Pros: App chạy nhanh, hỗ trợ lưu giỏ hàng offline, bảo mật tốt nhờ Firebase.

Cons: Chưa tích hợp thanh toán trực tuyến (VNPay/Momo), dữ liệu sản phẩm hiện đang là dữ liệu giả (Mock data).

Learning: Hiểu sâu về cách kết hợp giữa Database cục bộ (SQLite) và Cloud Service (Firebase).

Future Improvements: Tích hợp thêm AI để gợi ý sản phẩm và hệ thống Admin để quản lý kho hàng.



7. Contribution Table

Topic

Effort

Member A

Member B

Member C

Case Study Analysis

100%

40%

30%

30%

Business Analysis

100%

30%

40%

30%

System Design

100%

50%

20%

30%

Implementation

100%

30%

30%

40%

Documentation

100%

34%

33%

33%



8. References

Flutter Documentation: https://docs.flutter.dev/

Firebase Auth Guide: https://firebase.google.com/docs/auth

Provider Package: https://pub.dev/packages/provider

SQLite for Flutter: https://pub.dev/packages/sqflite

