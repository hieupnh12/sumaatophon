# Feature: Cart

## 1. Muc tieu

Quan ly gio hang cua nguoi dung truoc khi checkout. Gio hang luu tren MySQL theo `customer_id`, khong dung SQLite local.

## 2. Pham vi

Bao gom:

- Yeu cau dang nhap truoc khi mo gio hang hoac them san pham.
- Them san pham vao gio (theo `product_version_id`).
- Tang/giam so luong (toi da = so IMEI `IN_STOCK` cua version do).
- Xoa san pham / xoa toan bo gio hang.
- Ap dung/xoa ma giam gia (local trong Bloc).
- Tinh subtotal, discount, total truoc phi ship.
- Mo checkout khi gio hang co san pham.

Khong bao gom:

- Lich su don hang (feature `orders`).

## 3. Luong nguoi dung

1. User bam cart hoac add to cart.
2. Neu chua dang nhap that (co `customer_id` MySQL) → mo `LoginScreen(returnAfterAuth: true)`.
3. Sau dang nhap → sync cart tu API `GET /api/cart`.
4. User them/sua/xoa item → API cap nhat bang `carts` + `cart_items`.
5. User checkout → `POST /api/orders` gan IMEI tu `product_items` va danh dau `SOLD`.

## 4. Hanh vi nghiep vu

- Moi `customer_id` co toi da 1 cart `status = 1` (active).
- Cung `product_version_id` trong cart thi tang `quantity`, khong tao dong trung.
- Quantity toi thieu = 1; quantity toi da = so IMEI `IN_STOCK` cua version (dem tu `product_items`).
- Guest login / biometric demo khong duoc dung cart.
- Promo code hop le cap nhat discount (local Bloc, chua sync MySQL).

## 5. Database MySQL

### `carts`

| Cot | Mo ta |
|-----|-------|
| cart_id | PK |
| customer_id | FK → customers |
| status | 1 = active |
| create_date, update_date | timestamp |

### `cart_items`

| Cot | Mo ta |
|-----|-------|
| cart_item_id | PK |
| cart_id | FK → carts |
| product_version_id | FK → product_versions |
| quantity | so luong muon mua |
| status | 1 = active |

### Stock / IMEI

- Moi version co nhieu dong `product_items` (imei).
- Stock hien thi = COUNT imei WHERE `status = 'IN_STOCK'` AND `order_detail_id IS NULL`.
- Khi dat hang: chon N imei theo `quantity`, set `status = 'SOLD'`, `order_detail_id` = chi tiet don.

## 6. API Backend

| Method | Endpoint | Mo ta |
|--------|----------|-------|
| GET | `/api/cart?customerId=` | Lay items enriched (product + version + stock) |
| POST | `/api/cart/items` | Them/tang quantity `{ customerId, productVersionId }` |
| PUT | `/api/cart/items/:productVersionId` | Cap nhat quantity |
| DELETE | `/api/cart/items/:productVersionId?customerId=` | Xoa 1 item |
| DELETE | `/api/cart?customerId=` | Xoa toan bo cart |
| POST | `/api/orders` | Tao don + gan IMEI + clear cart |

## 7. Cau truc Flutter

```text
lib/features/cart/
  data/datasources/cart_remote_datasource.dart
  data/models/cart_item_model.dart
  data/repositories/cart_repository_impl.dart
  domain/entities/cart_item.dart
  domain/repositories/cart_repository.dart
  presentation/bloc/cart_bloc.dart
  presentation/cart_auth_helper.dart
  presentation/pages/cart_page.dart
  presentation/widgets/
lib/core/auth/auth_guard.dart
```

SQLite `cart_items` **khong con dung** cho feature nay.

## 8. Localization keys

```text
cart_login_required
cart_version_stock
cart_max_stock_reached
cart_save_error
(cac key cart_* hien co)
```

## 9. Acceptance criteria

- [x] Chua dang nhap → bam cart/add to cart mo login.
- [x] Cart luu tren MySQL qua REST API.
- [x] Hien thi product version (mau, RAM/ROM) va stock IMEI.
- [x] Quantity khong vuot qua stock IMEI.
- [x] Dat hang gan IMEI va danh dau SOLD (endpoint orders).
- [x] Text UI dung `context.tr()`.
