# Feature: Store Locator

## 1. Muc tieu

Cho phep nguoi dung tim cua hang phoneShop gan nhat tren ban do that, xem thong tin lien he, goi dien va mo chi duong.

## 2. Pham vi

Bao gom:

- Hien thi danh sach cua hang tu MySQL qua REST API.
- Ban do Google Maps voi marker tung cua hang.
- Tinh khoang cach tu vi tri nguoi dung (neu cap quyen).
- Chon cua hang tren ban do hoac carousel card.
- Goi dien (`tel:`) va chi duong (Google Maps).

Khong bao gom:

- Dat hang tai cua hang truc tiep tu man hinh nay.
- Tim kiem theo ten dia chi (phase sau).

## 3. Luong nguoi dung

1. User mo tab **Cua hang** (bottom nav).
2. App xin quyen vi tri (neu chua cap), goi `GET /stores?lat=&lng=`.
3. Ban do hien thi marker; card carousel o duoi hien thi chi tiet.
4. User vuot card hoac cham marker de chon cua hang.
5. User bam **Goi dien** hoac **Chi duong**.

## 4. Hanh vi nghiep vu

- Chi hien thi cua hang `is_active = 1`.
- Neu co `lat`/`lng`, backend sap xep theo khoang cach (km).
- Neu khong co vi tri, sap xep theo `store_id`.
- Khoang cach hien thi lam tron 1 chu so thap phan (vd. `1.2 km`).
- Nut goi/chi duong vo hieu neu thieu `phone` hoac toa do.

## 5. UI/UX

- Dung `AppColors`, `Theme.of(context)`.
- Ho tro light/dark mode.
- Co loading, error (retry), empty state.
- Moi text qua `context.tr(...)`.

## 6. Data/API/SQLite

API:

| Method | Path | Mo ta |
|--------|------|-------|
| GET | `/stores` | Danh sach cua hang |
| GET | `/stores?lat=10.77&lng=106.70` | Sap xep theo khoang cach |

Response mau:

```json
[
  {
    "id": "1",
    "name": "FShop",
    "address": "X6WQ+R5M, Khu đô thị FPT City, Ngũ Hành Sơn, Đà Nẵng 550000, Việt Nam",
    "phone": "0982481094",
    "latitude": 15.981042,
    "longitude": 108.254771,
    "openTime": "08:00 - 22:00",
    "distanceKm": 1.2
  }
]
```

SQLite: Khong dung.

Google Maps API key: dat trong AndroidManifest / iOS AppDelegate / `--dart-define=GOOGLE_MAPS_API_KEY=...` cho web.

## 7. Localization keys

```text
store_locator_search_hint
store_locator_open_hours
store_locator_call
store_locator_directions
store_locator_empty_title
store_locator_empty_desc
store_locator_error
store_locator_retry
store_locator_location_denied
store_locator_km
```

## 8. Cau truc code

```text
lib/features/store_locator/
  domain/entities/store_entity.dart
  domain/repositories/store_repository.dart
  data/models/store_model.dart
  data/datasources/store_remote_datasource.dart
  data/repositories/store_repository_impl.dart
  presentation/bloc/store_locator_bloc.dart
  presentation/pages/store_location_page.dart
  presentation/widgets/store_card.dart
  presentation/utils/store_locator_actions.dart
backend/src/routes/stores.js
backend/migrate-stores.js
```

## 9. Acceptance criteria

- [ ] Tab Cua hang load du lieu tu API, khong con mock trong bloc.
- [ ] Google Maps hien thi marker dung toa do.
- [ ] Goi dien va chi duong hoat dong.
- [ ] UI co loading/error/empty + l10n vi/en/ja.
- [ ] `flutter analyze` khong co loi moi.
