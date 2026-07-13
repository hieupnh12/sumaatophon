# Feature: Products

## 1. Muc tieu

Hien thi danh sach san pham dien thoai, tim kiem, loc theo hang/thong so va mo man chi tiet san pham.

## 2. Pham vi

Bao gom:

- Load danh sach san pham.
- Tim kiem san pham.
- Loc theo brand va bo loc nang cao.
- Hien thi product card.
- Hien thi product detail.
- Them san pham vao cart tu list/detail.

Khong bao gom:

- Tao/sua/xoa san pham tu app mobile.
- Quan ly ton kho.
- Dat hang, phan nay thuoc `checkout`.

## 3. Luong nguoi dung

1. User dang nhap thanh cong va vao tab shop.
2. App load products qua `ProductBloc`.
3. User tim kiem/loc san pham.
4. User bam product card de xem detail.
5. User bam add to cart hoac buy now.

## 4. Hanh vi nghiep vu

- Neu load thanh cong, hien thi grid products.
- Neu dang load, hien thi shimmer/skeleton.
- Neu loi API, hien thi error state.
- Neu loi API nhung da co cache SQLite, hien thi du lieu cache (offline).
- Neu khong co ket qua, hien thi empty state.
- Add to cart phai gui `AddToCartEvent` vao `CartBloc`.

## 5. UI/UX

- Product list dung grid 2 cot nhu hien tai.
- Product card giu style card, image, badge discount/new.
- Detail page giu hero image, carousel, color/storage selector.
- Badge cart phai cap nhat theo `CartBloc.totalItems`.
- Moi text UI phai dung `context.tr()`.

## 6. Data/API/SQLite

API san pham lay tu backend MySQL, Flutter khong ket noi truc tiep MySQL.

Du kien:

- Method: `GET`
- Endpoint: `/products`
- Query optional: `search`, `brand`, `minPrice`, `maxPrice`, `ram`, `rom`

File lien quan:

```text
lib/features/products/domain/entities/product.dart
lib/features/products/domain/repositories/product_repository.dart
lib/features/products/data/models/product_model.dart
lib/features/products/data/datasources/product_remote_datasource.dart
lib/features/products/data/datasources/product_local_datasource.dart
lib/features/products/data/repositories/product_repository_impl.dart
lib/features/products/presentation/bloc/product_bloc.dart
```

SQLite:

- Dung bang `products_cache` de luu snapshot san pham sau moi lan load API thanh cong.
- Khi mat mang / API loi, repository doc cache local va van hien thi list/detail neu da tung load truoc do.
- Lan dau mo app khi offline va chua co cache → van hien thi error state.

Table `products_cache`:

```text
id TEXT PRIMARY KEY
name, brand, price, original_price, image_url
gallery_images, ram_rom_options, colors, specifications (JSON string)
rating, review_count, is_new, stock_quantity, cached_at
```

## 7. Localization keys

Dang co hoac can co:

```text
search_hint
price_range
million
ram
rom
not_found_title
not_found_desc
add_to_cart
added_to_cart
buy_now
color
storage
specifications
reviews
reviews_based_on
product_review_write
product_review_submit
product_review_rate_label
product_review_content_hint
product_review_content_min
product_review_success
product_review_error
product_review_already
product_review_not_eligible
product_review_done
description
```

## 7.1. Danh gia san pham (sau don hoan tat)

- API `GET /products/{id}/feedback-status?customerId=` tra `canReview`, `hasReviewed`.
- API `POST /products/{id}/feedbacks` body `{ customerId, rate, content }`.
- Chi duoc danh gia neu da mua trong don `DELIVERED`/`COMPLETED` va chua danh gia.
- UI: nut "Viết đánh giá" tren product detail; bottom sheet nhap sao + noi dung.
- Tu order detail (don `completed`): nut "Đánh giá" mo truc tiep bottom sheet danh gia (khong qua product detail).

Neu them UI text moi trong product list/detail, bat buoc them key cho `vi`, `en`, `ja`.

## 8. Cau truc code du kien

```text
lib/features/products/
  domain/
    entities/
    repositories/
  data/
    datasources/
    models/
    repositories/
  presentation/
    bloc/
    pages/
    widgets/
```

## 9. Acceptance criteria

- [ ] Products load tu repository, khong goi API trong UI.
- [ ] Search/filter khong pha layout.
- [ ] Add to cart cap nhat badge cart.
- [ ] Empty/loading/error state day du.
- [ ] Text UI dung `context.tr()`.
- [ ] UI dung light/dark mode.

## 10. Ghi chu cho AI agent

- Khong hard-code endpoint trong page/widget.
- Neu chuyen tu mock sang API that, giu interface `ProductRepository`.
- Neu backend response khac entity hien tai, map trong `ProductModel`, khong sua UI theo JSON.
