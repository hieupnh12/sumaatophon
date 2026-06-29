# Specification: Warranty (Bảo hành)

## 1. Mục tiêu tính năng (Objective)
Cho phép khách hàng xem các thiết bị đã mua còn thời hạn bảo hành và gửi yêu cầu bảo hành/đổi trả trực tuyến qua ứng dụng. Tính năng này đóng vai trò quan trọng trong việc chăm sóc khách hàng sau mua hàng.

## 2. Hành vi nghiệp vụ (Business Rules)
- **Thiết bị hợp lệ:** Chỉ các thiết bị được mua và đơn hàng đã thành công (hoàn tất) mới được hiển thị. 
- **Ngày tính bảo hành:** Tính từ ngày `completed_at` của đơn hàng (hoặc `created_at` nếu không có), cộng với số tháng `warranty_period` của sản phẩm.
- **Quy tắc tạo yêu cầu:**
  - Khách hàng chọn nhóm lỗi và phương thức tiếp nhận (mang tới cửa hàng hoặc thu gom tại nhà) qua giao diện.
  - Các lựa chọn này sẽ được ghép thành 1 đoạn văn bản (Text) duy nhất và lưu vào trường `reason` trong DB. (Ví dụ: `[Lỗi nguồn] [Tại cửa hàng] - Bật không lên`). Không cần sửa cấu trúc Database hiện tại.
- **Trạng thái:** Dùng hệ thống trạng thái cũ của bảng `return_warranty_requests`: `pending`, `accepted`, `rejected`, `in_progress`, `completed`. Trên UI sẽ map (ánh xạ) sang các thuật ngữ thân thiện như "Chờ duyệt", "Đang xử lý", "Hoàn thành".

## 3. UI/UX
- **Vị trí:** Truy cập từ `ProfilePage` -> Mục "Thông tin bảo hành" (nằm dưới "Đơn hàng của tôi").
- **Màn hình chính (WarrantyPage):** Gồm 2 tab:
  - Tab 1: **Thiết bị của tôi** (Danh sách máy còn/hết bảo hành).
  - Tab 2: **Yêu cầu bảo hành** (Lịch sử các yêu cầu đã gửi, trạng thái theo UI Timeline).
- **Màn hình form (WarrantyRequestFormPage):**
  - Hiển thị tóm tắt sản phẩm cần bảo hành.
  - Dropdown Nhóm lỗi (Lỗi nguồn, lỗi màn hình, v.v.).
  - Dropdown Phương thức tiếp nhận (Giao tại cửa hàng, Thu gom tại nhà).
  - Textarea mô tả chi tiết lỗi.
  - Nút Gửi.

## 4. API Endpoints
Base path: `/api/warranties`

| Method | Endpoint | Description |
|---|---|---|
| GET | `/eligible-items` | Lấy danh sách sản phẩm từ các đơn hàng thành công, kèm `warrantyUntil` |
| GET | `/` | Lấy lịch sử yêu cầu bảo hành của user hiện tại |
| POST | `/` | Gửi yêu cầu bảo hành mới. Payload: `{ order_id, product_version_id, reason, type: 'warranty' }` |

## 5. Localization Keys (l10n)
Dự kiến thêm các key:
- `warranty_title`, `warranty_my_devices`, `warranty_requests`
- `warranty_until`, `warranty_expired`
- `warranty_form_title`, `warranty_reason_label`, `warranty_issue_group`, `warranty_receipt_method`, `warranty_submit`
- `warranty_status_pending`, `warranty_status_accepted`, `warranty_status_in_progress`, `warranty_status_completed`, `warranty_status_rejected`

## 6. Cấu trúc thư mục (Folder Structure)
Sử dụng Clean Architecture trong `lib/features/warranty/`:
```text
lib/features/warranty/
  domain/
    entities/
      warranty_item.dart
      warranty_request.dart
    repositories/
      warranty_repository.dart
  data/
    models/
      warranty_item_model.dart
      warranty_request_model.dart
    datasources/
      warranty_remote_datasource.dart
    repositories/
      warranty_repository_impl.dart
  presentation/
    bloc/
      warranty_bloc.dart
      warranty_event.dart
      warranty_state.dart
    pages/
      warranty_page.dart
      warranty_request_form_page.dart
    widgets/
      warranty_item_card.dart
      warranty_request_card.dart
```

## 7. Database (SQLite / MySQL)
- MySQL: Dùng bảng `return_warranty_requests` sẵn có, KHÔNG sửa đổi. Lợi dụng trường `reason` để ghép chuỗi.
- SQLite: Không lưu local caching cho tính năng này ở MVP để đảm bảo data luôn real-time và chính xác với trung tâm bảo hành.
