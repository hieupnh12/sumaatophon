# Feature: Cart

## 1. Muc tieu

Quan ly gio hang cua nguoi dung truoc khi checkout.

## 2. Pham vi

Bao gom:

- Them san pham vao gio.
- Tang/giam so luong.
- Xoa san pham.
- Xoa toan bo gio hang.
- Ap dung/xoa ma giam gia.
- Tinh subtotal, discount, total truoc phi ship.
- Mo checkout khi gio hang co san pham.

Khong bao gom:

- Tao don hang.
- Xu ly thanh toan.
- Lich su don hang.

## 3. Luong nguoi dung

1. User bam add to cart tu product list/detail.
2. `CartBloc` them item hoac tang quantity neu san pham da ton tai.
3. User mo `CartPage`.
4. User thay doi quantity/xoa item/ap promo code.
5. User bam checkout de sang `CheckoutPage`.

## 4. Hanh vi nghiep vu

- Cung `product.id` thi tang quantity, khong tao duplicate item.
- Quantity <= 0 thi xoa item.
- Clear cart dua state ve gio hang rong.
- Promo code hop le cap nhat discount.
- Promo code sai hien error.
- Khong nen cho checkout neu cart rong.

## 5. UI/UX

- Empty cart co icon, title, description, action quay lai shop.
- Cart item co image, name, price, quantity controls.
- Swipe/delete hoac nut delete phai cap nhat `CartBloc`.
- Summary hien subtotal, discount, total.
- Checkout button ro rang, dung style app.
- Moi text UI phai dung `context.tr()`.

## 6. Data/API/SQLite

Hien tai cart co the nam trong memory bang `CartBloc`.

Neu can luu cart khi tat app:

- Them SQLite local datasource.
- Table du kien: `cart_items`
- Columns du kien: `productId`, `quantity`, `createdAt`, `updatedAt`
- File du kien:

```text
lib/features/cart/domain/entities/cart_item.dart
lib/features/cart/domain/repositories/cart_repository.dart
lib/features/cart/data/models/cart_item_model.dart
lib/features/cart/data/datasources/cart_local_datasource.dart
lib/features/cart/data/repositories/cart_repository_impl.dart
```

API:

- Khong can neu cart chi local.
- Neu backend sync cart theo user, dung remote datasource rieng.

## 7. Localization keys

Dang co hoac can co:

```text
cart
cart_empty_title
cart_empty_desc
explore_now
subtotal
discount
total
checkout
promo_hint
apply
cart_promo_applied
cart_remove_item
cart_clear
```

Neu them UI text moi, bat buoc them key cho `vi`, `en`, `ja`.

## 8. Cau truc code du kien

```text
lib/features/cart/
  domain/
    entities/
  data/
    models/
    datasources/
    repositories/
  presentation/
    bloc/
    pages/
    widgets/
```

Neu chua dung SQLite/API, co the chua can `data/`.

## 9. Acceptance criteria

- [ ] Add to cart tang quantity khi item da ton tai.
- [ ] Update quantity hoat dong dung.
- [ ] Remove/clear cart hoat dong dung.
- [ ] Promo code co success/error state.
- [ ] Total tinh dung: `subtotal - discount`.
- [ ] Khong checkout khi cart rong.
- [ ] Text UI dung `context.tr()`.
- [ ] UI dung light/dark mode.

## 10. Ghi chu cho AI agent

- `CartItem` nen dua ve `domain/entities` neu duoc dung boi checkout/orders.
- Cart khong tao order truc tiep; tao order thuoc checkout.
- Neu tach widget, uu tien `cart_item_tile.dart`, `cart_summary.dart`, `promo_code_box.dart`.

