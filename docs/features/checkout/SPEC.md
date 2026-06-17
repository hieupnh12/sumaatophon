# Feature: Checkout

## 1. Muc tieu

Cho phep nguoi dung xac nhan don hang tu cart, chon dia chi giao hang, phuong thuc van chuyen, phuong thuc thanh toan va dat hang.

## 2. Pham vi

Bao gom:

- Doc cart hien tai tu `CartBloc`.
- Hien thi order summary.
- Chon dia chi giao hang.
- Chon shipping method.
- Chon payment method.
- Submit order.
- Clear cart khi dat hang thanh cong.

Khong bao gom:

- Lich su don hang, phan nay nen thuoc `orders`.
- Thanh toan online that neu backend/payment gateway chua ho tro.
- Quan ly dia chi nang cao neu chua co feature address book.

## 3. Luong nguoi dung

1. User co item trong cart.
2. User bam checkout tu `CartPage` hoac buy now tu product detail.
3. `CheckoutPage` doc `CartBloc` de lay items/subtotal/discount.
4. User chon address/shipping/payment.
5. User bam confirm order.
6. `CheckoutBloc` submit order.
7. Thanh cong thi clear cart va hien success.

## 4. Hanh vi nghiep vu

- Khong submit neu cart rong.
- Total order = cart final price + shipping cost.
- Khi submit, button vao processing/loading state.
- Submit thanh cong chi hien success mot lan.
- Submit loi phai hien error message than thien.
- Sau khi thanh cong, cart phai duoc clear.

## 5. UI/UX

- Page co AppBar title.
- Section rieng cho address, shipping, payment, order summary.
- Bottom confirm button co loading indicator khi processing.
- Success dialog/screen co action quay ve home hoac orders.
- Tat ca text UI phai dung `context.tr()`.
- UI dung `AppColors`, `Theme.of(context)`, light/dark mode.

## 6. Data/API/SQLite

Neu submit order that qua backend MySQL:

- Method: `POST`
- Endpoint: `/orders`
- Request body du kien:

```json
{
  "userId": "string",
  "items": [
    {
      "productId": "string",
      "quantity": 1,
      "price": 999
    }
  ],
  "address": "string",
  "shippingMethod": "string",
  "shippingCost": 5,
  "paymentMethod": "string",
  "subtotal": 999,
  "discount": 0,
  "total": 1004
}
```

File du kien neu co API:

```text
lib/features/checkout/domain/entities/order.dart
lib/features/checkout/domain/entities/delivery_address.dart
lib/features/checkout/domain/entities/shipping_method.dart
lib/features/checkout/domain/entities/payment_method.dart
lib/features/checkout/domain/repositories/checkout_repository.dart
lib/features/checkout/data/models/order_model.dart
lib/features/checkout/data/datasources/checkout_remote_datasource.dart
lib/features/checkout/data/repositories/checkout_repository_impl.dart
```

SQLite:

- Khong can cho checkout neu order luu tren backend.
- Neu offline order draft, them local datasource rieng.

## 7. Localization keys

Dang co hoac can co:

```text
checkout
checkout_title
checkout_delivery_address
checkout_shipping_method
checkout_payment_method
checkout_order_summary
checkout_confirm_order
checkout_order_success_title
checkout_order_success_desc
checkout_back_home
checkout_items
checkout_shipping
checkout_total
checkout_empty_cart_error
checkout_submit_error
```

Neu them UI text moi, bat buoc them key cho `vi`, `en`, `ja`.

## 8. Cau truc code du kien

```text
lib/features/checkout/
  domain/
    entities/
    repositories/
  data/
    models/
    datasources/
    repositories/
  presentation/
    bloc/
    pages/
    widgets/
```

Neu chua dung backend, co the giu submit mock trong Bloc tam thoi, nhung nen tach khi co API.

## 9. Acceptance criteria

- [ ] Khong checkout khi cart rong.
- [ ] Summary tinh dung: `subtotal - discount + shipping`.
- [ ] Chon address/shipping/payment cap nhat state.
- [ ] Confirm order co loading state.
- [ ] Thanh cong clear cart.
- [ ] Error hien message ro rang.
- [ ] Text UI dung `context.tr()`.
- [ ] UI dung light/dark mode.

## 10. Ghi chu cho AI agent

- Checkout duoc phep doc `CartBloc`, nhung khong duoc sua product data.
- Tao order thuoc checkout; xem lich su order thuoc feature `orders`.
- Neu tach widget, uu tien `address_section.dart`, `shipping_section.dart`, `payment_section.dart`, `order_summary.dart`.

