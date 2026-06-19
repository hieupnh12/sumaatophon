# Product Feature Agent Guide

File nay la huong dan rieng cho feature `products`. Doc file nay truoc khi code/sua phan san pham.

Lien quan:

- `AGENTS.md` (quy chuan chung project)
- `docs/features/backend/AGENT.md` (ket noi MySQL + pool dung chung)
- `docs/features/products/SPEC.md` (dac ta nghiep vu)
- `docs/API.md` (contract API)

---

## 1. Muc tieu feature

Hien thi danh sach dien thoai tu MySQL (qua backend REST), tim kiem/loc tren UI, mo chi tiet, them vao cart.

**Quan trong:** Flutter **khong** ket noi truc tiep MySQL Aiven. Chi backend moi dung credentials DB.

---

## 2. Kien truc du lieu (MySQL phoneShop)

### 3 tang san pham

```text
products              → model chung (iPhone 15, Galaxy S24...)
  └── product_versions → bien the RAM/ROM/Color + export_price
        └── product_items → tung may vat ly (IMEI)
```

### Bang lookup (JOIN lay ten)

| Bang | Cot hien thi |
|------|--------------|
| `brands` | `brand_name` |
| `categories` | `category_name` |
| `rams` | `ram_size` |
| `roms` | `rom_size` |
| `colors` | `color_name` |
| `operating_systems` | `operating_system_name` |
| `origins` | `origin_name` |
| `warehouse_areas` | `area_name` |

### SQLite (local) — KHONG dung cho products

- SQLite chi dung cho `cart_items` (gio hang local).
- Products lay tu API, cart luu snapshot product khi add.

---

## 3. Luong GET danh sach product (da implement)

```text
ProductListPage
  → ProductBloc (LoadProductsEvent)
    → ProductRepository.getProducts()
      → ProductRepositoryImpl
        → ProductRemoteDataSource.getProducts()
          → ApiClient.get('/products')
            → Backend Express (server.js)
              → MySQL JOIN products + brands + product_versions + ...
                → JSON array
                  → ProductModel.fromJson()
                    → Product entity
                      → ProductLoaded state
                        → Grid UI
```

---

## 4. File da code & vai tro

### Backend (`backend/`)

Chi tiet ket noi MySQL, pool, `.env`: xem `docs/features/backend/AGENT.md`.

| File | Vai tro |
|------|---------|
| `db.js` | MySQL pool dung chung — feature moi `require('./db')` |
| `.env` | Host/port/user/password MySQL (KHONG commit) |
| `.env.example` | Mau cau hinh, khong co password that |
| `server.js` | Express API, endpoint `GET /products`, `GET /health` |
| `package.json` | Dependencies: express, mysql2, cors, dotenv |

**Chay backend:**

```bash
cd backend
npm install
npm start
```

Test: `http://localhost:3000/products` hoac `http://localhost:3000/health`

### Flutter — Core network

| File | Code gi |
|------|---------|
| `lib/core/network/api_endpoints.dart` | `baseUrl`, path `/products` |
| `lib/core/network/api_client.dart` | Ham `get()`, parse JSON, throw `ApiException` |

**baseUrl theo moi truong:**

| Moi truong | baseUrl |
|------------|---------|
| Android Emulator | `http://10.0.2.2:3000` |
| iOS Simulator | `http://localhost:3000` |
| May that | `http://<IP-may-dev>:3000` |

### Flutter — Products data layer

| File | Code gi |
|------|---------|
| `data/models/product_model.dart` | `fromJson()` + `toEntity()` |
| `data/datasources/product_remote_datasource.dart` | Goi API, tra `List<Product>` |
| `data/repositories/product_repository_impl.dart` | Noi repository interface voi remote datasource |
| `data/datasources/product_mock_datasource.dart` | Mock cu — giu de test offline, khong dung trong DI |

### Flutter — Khong can sua (neu JSON khop)

| File | Ly do |
|------|-------|
| `domain/entities/product.dart` | Entity da du |
| `domain/repositories/product_repository.dart` | Interface `getProducts()` |
| `presentation/bloc/product_bloc.dart` | Da goi repository |
| `presentation/pages/product_list_page.dart` | UI da co |

### DI — `lib/main.dart`

```dart
sl.registerLazySingleton(() => ApiClient());
sl.registerLazySingleton(() => ProductRemoteDataSource(sl()));
sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(sl()));
```

---

## 5. JSON API `/products` (backend tra ve)

Moi phan tu:

```json
{
  "id": "115",
  "name": "Samsung Galaxy A07",
  "brand": "SamSung",
  "price": 5000,
  "originalPrice": 1000,
  "imageUrl": "https://...",
  "galleryImages": ["https://..."],
  "rating": 4.5,
  "reviewCount": 12,
  "ramRomOptions": ["8GB/256GB", "12GB/512GB"],
  "colors": ["Black", "Blue"],
  "specifications": {
    "Display": "6.7\"",
    "Chipset": "Snapdragon 8 Gen 3"
  },
  "isNew": true
}
```

Backend map tu SQL:

- `price` = `MIN(product_versions.export_price)`
- `originalPrice` = `MAX(import_price)` neu lon hon price
- `ramRomOptions` = GROUP_CONCAT ram/rom tu versions
- `colors` = GROUP_CONCAT color_name
- `rating` / `reviewCount` = AVG/COUNT tu bang `feedbacks.rate`

---

## 6. Checklist truoc khi chay app

- [ ] Backend dang chay (`npm start` trong `backend/`)
- [ ] `backend/.env` co dung thong tin Aiven
- [ ] Test browser: `http://localhost:3000/products` co JSON
- [ ] `api_endpoints.dart` dung baseUrl cho emulator/may that
- [ ] AndroidManifest co `INTERNET` + `usesCleartextTraffic="true"` (HTTP local)
- [ ] `flutter pub get` da chay

---

## 7. Loi thuong gap

| Trieu chung | Nguyen nhan | Cach sua |
|-------------|-------------|----------|
| Connection refused | Backend chua chay | `cd backend && npm start` |
| Access denied MySQL | Password cu trong Windows env hoac sai `.env` | Xem `docs/features/backend/AGENT.md` muc 7 |
| ApiException / timeout | Sai baseUrl | Doi `10.0.2.2` vs IP LAN |
| List trong | `products.status != 1` | Kiem tra DB hoac bo filter tam |
| Type cast error | JSON backend khac model | Sua `ProductModel.fromJson` |
| Cleartext not permitted | Thieu manifest | Them `usesCleartextTraffic` |

---

## 8. Buoc tiep theo (chua lam)

1. **GET /products/:id** — chi tiet + mang `versions[]` (product_version_id, ram, rom, color, price)
2. **Product detail page** — chon version truoc khi add cart
3. **Cart** — luu `product_version_id` thay vi chi product_id (khi can sync MySQL `cart_items`)
4. **Filter API** — truyen query `brand`, `minPrice` len backend thay vi filter local trong BLoC
5. **Cache offline** (tu chon) — SQLite cache products, khong bat buoc

---

## 9. Prompt mau cho AI agent

```text
Doc docs/features/backend/AGENT.md, docs/features/products/AGENT.md va SPEC.md truoc.
Implement <task> cho products theo dung luong:
Page -> Bloc -> Repository -> RemoteDataSource -> ApiClient -> Backend (pool.query) -> MySQL.
Khong query MySQL trong Flutter. Khong hard-code text UI.
Cap nhat AGENT.md neu thay doi API hoac file structure.
```

---

## 10. Lich su thay doi

| Ngay | Noi dung |
|------|----------|
| 2026-06-19 | Implement GET /products: backend server.js + Flutter remote datasource + ProductModel |
| 2026-06-19 | Tach `backend/db.js` pool dung chung; them `docs/features/backend/AGENT.md` |
