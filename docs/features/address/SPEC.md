# Feature: Address

## 1. Muc tieu

Quan ly danh sach dia chi cua nguoi dung (So dia chi). Cho phep nguoi dung xem, them, sua, xoa dia chi nhan hang. Dia chi nay duoc su dung de hien thi tren Profile, va dung cho qua trinh thanh toan sau nay.

## 2. Pham vi

Bao gom:
- Hien thi danh sach dia chi hien co.
- Hien thi man hinh rong (empty state) neu chua co dia chi.
- Them moi dia chi (co form dien ten, SĐT, tinh/thanh, quan/huyen, phuong/xa, dia chi cu extreme, loai dia chi).
- Sua dia chi da co.
- Xoa dia chi.
- Chon dia chi mac dinh.
- Bottom sheet chon Tinh/Thanh pho, Quan/Huyen va Phuong/Xa (Lay data thuc tu API `provinces.open-api.vn`).

Khong bao gom:
- Tich hop truc tiep voi API van chuyen (Giao Hang Nhanh, Viettel Post, v.v.).

## 3. Luong nguoi dung

1. User vao Profile -> Chon "So dia chi".
2. App hien thi danh sach dia chi hoac empty state.
3. User chon "Them dia chi" hoac chon icon "+" tren AppBar.
4. App hien thi form nhap thong tin nhan hang.
5. User nhap thong tin.
6. Khi chon vi tri, bottom sheet lan luot yeu cau chon Tinh/Thanh pho -> Quan/Huyen -> Phuong/Xa (load tu API).
7. User bam "Them dia chi" -> Luu thanh cong xuong SQLite, quay lai danh sach.

## 4. Hanh vi nghiep vu

- Dia chi gom: Ten nguoi nhan, So dien thoai, Tinh/Thanh pho, Quan/Huyen, Phuong/Xa, Dia chi cu the, Loai (Nha/Van phong), IsDefault.
- Neu la dia chi dau tien, tu dong gan lam mac dinh.
- Moi luc chi co 1 dia chi mac dinh.
- Tat ca cac truong bat buoc phai nhap.

## 5. UI/UX

- Dung `AppColors`, `AppTheme`, `Theme.of(context)`.
- Ho tro light/dark mode.
- Khong hard-code text UI.
- Moi text dung `context.tr('key')`.
- Empty state voi hinh minh hoa dep mat.

## 6. Data/API/SQLite

API Hanh Chinh (Open API):
- Tinh/Thanh: `GET https://provinces.open-api.vn/api/p/`
- Quan/Huyen: `GET https://provinces.open-api.vn/api/p/{province_code}?depth=2`
- Phuong/Xa: `GET https://provinces.open-api.vn/api/d/{district_code}?depth=2`

SQLite:
- Table: `addresses`
- Columns: `id` (TEXT), `name` (TEXT), `phone` (TEXT), `province` (TEXT), `district` (TEXT), `ward` (TEXT), `street` (TEXT), `type` (TEXT), `is_default` (INTEGER)
- Local datasource: `AddressLocalDataSource` -> su dung `AppDatabase` co san neu duoc. Tuan thu file `AGENTS.md`.

## 7. Localization keys

Bat buoc them vao `lib/core/l10n/app_localizations.dart` cho `vi`, `en`, `ja`.

```text
address_title
address_empty_title
address_empty_desc
address_add_btn
address_add_title
address_edit_title
address_name_label
address_phone_label
address_province_label
address_ward_label
address_street_label
address_type_label
address_type_home
address_type_office
address_set_default
address_select_province
address_select_ward
address_search_placeholder
address_btn_edit
address_btn_delete
address_save_success
address_delete_success
address_delete_confirm_title
address_delete_confirm_desc
```

## 8. Cau truc code du kien

```text
lib/features/address/
  domain/
    entities/address.dart
    repositories/address_repository.dart
  data/
    models/address_model.dart
    datasources/address_local_datasource.dart
    repositories/address_repository_impl.dart
  presentation/
    bloc/address_bloc.dart
    pages/address_list_page.dart
    pages/address_form_page.dart
    widgets/address_card.dart
    widgets/location_picker_sheet.dart
```

## 9. Acceptance criteria

- [ ] Man hinh danh sach dia chi hoat dong dung UI.
- [ ] Form them dia chi hoat dong, co bottom sheet chon dia diem.
- [ ] Luu tru duoc dia chi local.
- [ ] UI dung light/dark va ho tro l10n.
- [ ] Tu dong hien thi empty state khi khong co du lieu.
