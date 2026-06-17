# Feature: Orders

## 1. Muc tieu

Quan ly lich su don hang sau khi checkout thanh cong.

## 2. Pham vi

Bao gom:

- Hien thi danh sach don hang cua user.
- Hien thi chi tiet don hang.
- Hien thi trang thai don hang.
- Doc order tu backend neu co API.

Khong bao gom:

- Tao order truc tiep, viec tao order thuoc `checkout`.
- Quan ly van chuyen/admin.
- Hoan tien/huy don neu chua co yeu cau rieng.

## 3. Luong nguoi dung

1. User vao profile hoac tab orders neu co.
2. App load danh sach orders theo user.
3. User bam mot order de xem chi tiet.

## 4. Hanh vi nghiep vu

- Neu chua co don hang, hien empty state.
- Neu API loi, hien error state.
- Order status nen co cac gia tri ro rang: pending, confirmed, shipping, completed, cancelled.

## 5. UI/UX

- Order card hien ma don, ngay dat, tong tien, trang thai.
- Detail hien items, dia chi, shipping, payment, tong tien.
- Status chip dung mau trong `AppColors`.
- Moi text UI dung `context.tr()`.

## 6. Data/API/SQLite

API du kien:

- `GET /orders?userId=...`
- `GET /orders/{id}`

File du kien:

```text
lib/features/orders/domain/entities/order.dart
lib/features/orders/domain/repositories/order_repository.dart
lib/features/orders/data/models/order_model.dart
lib/features/orders/data/datasources/order_remote_datasource.dart
lib/features/orders/data/repositories/order_repository_impl.dart
lib/features/orders/presentation/bloc/order_bloc.dart
lib/features/orders/presentation/pages/order_list_page.dart
lib/features/orders/presentation/pages/order_detail_page.dart
lib/features/orders/presentation/widgets/order_card.dart
```

SQLite:

- Khong can neu orders lay tu backend.
- Co the dung local cache neu can offline.

## 7. Localization keys

Can co neu implement:

```text
orders_title
orders_empty_title
orders_empty_desc
orders_status_pending
orders_status_confirmed
orders_status_shipping
orders_status_completed
orders_status_cancelled
orders_detail_title
orders_order_items
orders_order_total
```

## 8. Cau truc code du kien

```text
lib/features/orders/
  domain/
  data/
  presentation/
```

## 9. Acceptance criteria

- [ ] Load orders qua repository.
- [ ] Co loading/empty/error state.
- [ ] Detail hien day du thong tin don.
- [ ] Text UI dung `context.tr()`.
- [ ] UI dung light/dark mode.

## 10. Ghi chu cho AI agent

- Khong tron orders vao checkout page.
- Neu checkout submit thanh cong, co the navigate ve orders sau nay neu user yeu cau.

