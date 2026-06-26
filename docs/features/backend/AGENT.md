# Backend & MySQL Agent Guide

File nay la huong dan dung chung cho **ket noi MySQL Aiven** va **them API endpoint moi** trong `backend/`.

Moi feature can du lieu MySQL (products, orders, auth, checkout...) deu doc file nay truoc, sau do doc `docs/features/<feature>/AGENT.md` neu co.

Lien quan:

- `AGENTS.md` (quy chuan chung project)
- `docs/API.md` (contract REST API)
- `docs/features/products/AGENT.md` (mau da implement day du)

---

## 1. Nguyen tac bat buoc

```text
Flutter app
  -> REST API (backend Express)
    -> MySQL Aiven (phoneShop)
```

- Flutter **khong** ket noi truc tiep MySQL.
- Credentials DB chi nam trong `backend/.env` — **KHONG commit**.
- Moi feature moi: them route trong backend + remote datasource + repository + bloc (giong products).
- SQLite tren Flutter chi dung cho du lieu local (cart, session...), khong thay MySQL.

---

## 2. Cau hinh database (Aiven)

### File `.env`

Dat tai `backend/.env` (copy tu `.env.example`):

```env
DB_HOST=mysql-xxxxx.e.aivencloud.com
DB_PORT=24714
DB_USER=avnadmin
DB_PASSWORD=<password_tu_aiven>
DB_NAME=phoneShop
PORT=3000
```

| Bien | Nguon tren Aiven |
|------|------------------|
| `DB_HOST` | Host |
| `DB_PORT` | Port |
| `DB_USER` | User (thuong `avnadmin`) |
| `DB_PASSWORD` | Password (Reset password neu can) |
| `DB_NAME` | Ten database (`phoneShop` hoac `defaultdb`) |
| `PORT` | Port backend local (mac dinh `3000`) |

### Luu y quan trong ve password

- `backend/db.js` dung `dotenv.config({ override: true })` de **file `.env` luon ghi de** bien moi truong Windows cu (neu co).
- Neu gap `Access denied` du password tren Aiven dung: kiem tra **Environment Variables** tren Windows co bien `DB_PASSWORD` cu khong → xoa hoac cap nhat.

### Chay backend

```bash
cd backend
npm install
npm start
```

Test:

- `http://localhost:3000/health` → `{"ok": true}`
- `http://localhost:3000/products` → JSON array

---

## 3. Pool MySQL dung chung — `backend/db.js`

**Moi endpoint moi chi can import pool, khong tao connection rieng.**

```javascript
const pool = require('./db');

app.get('/orders', async (_req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM orders WHERE ...');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'ORDERS_LIST_ERROR' });
  }
});
```

File `backend/db.js`:

- Doc `.env` voi `override: true`
- Tao `mysql2/promise` pool mot lan
- Export pool de cac route trong `backend/src/` dung lai

**Khong duoc:**

- Tao `createPool()` hoac `createConnection()` rieng trong tung route
- Hard-code host/password trong code
- Ket noi MySQL tu Flutter

---

## 3.1. Cau truc backend (Express)

Entry point van la `backend/server.js` (listen port). Logic nam trong `backend/src/`:

```text
backend/
  server.js              # npm start — tao app va listen
  db.js                  # MySQL pool dung chung
  src/
    app.js               # express + cors + json + dang ky routes
    config/firebase.js   # Firebase Admin, OTP cache
    routes/
      index.js           # gom tat ca router
      products.js        # GET /products, /products/:id, ...
      auth.js            # POST /auth/*
      profile.js         # PUT /profile
      addresses.js       # CRUD /api/addresses
      cart.js            # CRUD /api/cart
      orders.js          # POST /api/orders
      health.js          # GET /health
    services/            # query/helper dung lai (cart, product)
    utils/               # map JSON (productMappers, ...)
```

Them endpoint moi: sua hoac tao file trong `src/routes/`, roi dang ky trong `src/routes/index.js`.

---

## 4. Mau them endpoint backend moi

### Buoc 1 — Viet route trong `backend/src/routes/<feature>.js`

Vi du them `GET /orders` — tao hoac mo rong `src/routes/orders.js`:

```javascript
const express = require('express');
const pool = require('../../db');

const router = express.Router();

router.get('/orders', async (req, res) => {
  try {
    const userId = req.query.userId;
    const [rows] = await pool.query(
      `
      SELECT o.order_id, o.total_amount, o.status, o.created_at
      FROM orders o
      WHERE o.user_id = ?
      ORDER BY o.created_at DESC
      `,
      [userId],
    );
    res.json(rows.map(mapOrderRow));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'ORDERS_LIST_ERROR' });
  }
});

module.exports = router;
```

Dang ky trong `src/routes/index.js`:

```javascript
const ordersRouter = require('./orders');
app.use(ordersRouter);
```

### Buoc 2 — Quy tac route backend

| Quy tac | Chi tiet |
|---------|----------|
| Query SQL | Chi trong backend, dung `pool.query()` |
| Map JSON | Ham `mapXxxRow(row)` rieng, khong tra raw SQL row |
| Loi | `res.status(500).json({ message, code })` |
| Health check | Dung san `GET /health` |
| POST body | `req.body`, validate truoc khi INSERT |

### Buoc 3 — Cap nhat `docs/API.md`

Them endpoint moi: method, path, request, response, error code.

---

## 5. Luong Flutter (giong products)

Moi feature MySQL moi **bat buoc** theo dung thu tu:

```text
FeaturePage
  -> FeatureBloc (LoadXxxEvent)
    -> FeatureRepository.getXxx()
      -> FeatureRepositoryImpl
        -> FeatureRemoteDataSource.getXxx()
          -> ApiClient.get('/xxx')   // hoac post()
            -> Backend Express
              -> pool.query(...)
                -> JSON
                  -> XxxModel.fromJson()
                    -> Xxx entity
                      -> FeatureLoaded state
                        -> UI
```

### File can tao/sua (Flutter)

| Tang | File mau |
|------|----------|
| Endpoint | `lib/core/network/api_endpoints.dart` |
| HTTP | `lib/core/network/api_client.dart` (da co san) |
| Model | `lib/features/<feature>/data/models/<entity>_model.dart` |
| Remote DS | `lib/features/<feature>/data/datasources/<feature>_remote_datasource.dart` |
| Repository | `lib/features/<feature>/data/repositories/<feature>_repository_impl.dart` |
| Domain | `lib/features/<feature>/domain/repositories/<feature>_repository.dart` |
| Bloc | `lib/features/<feature>/presentation/bloc/<feature>_bloc.dart` |
| DI | `lib/main.dart` — register datasource, repository, bloc |

### Mau RemoteDataSource

```dart
class OrderRemoteDataSource {
  final ApiClient apiClient;

  OrderRemoteDataSource(this.apiClient);

  Future<List<Order>> getOrders(String userId) async {
    final data = await apiClient.get('${ApiEndpoints.orders}?userId=$userId');
    return (data as List)
        .map((json) => OrderModel.fromJson(json).toEntity())
        .toList();
  }
}
```

### Mau DI trong `main.dart`

```dart
sl.registerLazySingleton(() => ApiClient()); // chi register 1 lan
sl.registerLazySingleton(() => OrderRemoteDataSource(sl()));
sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl()));
sl.registerFactory(() => OrderBloc(repository: sl()));
```

### baseUrl theo moi truong

| Moi truong | baseUrl trong `api_endpoints.dart` |
|------------|-------------------------------------|
| Android Emulator | `http://10.0.2.2:3000` |
| iOS Simulator | `http://localhost:3000` |
| May that | `http://<IP-LAN-may-dev>:3000` |

---

## 6. Checklist feature moi (backend + Flutter)

### Backend

- [ ] Route moi trong `backend/src/routes/` (pool tu `../../db`)
- [ ] Da dang ky router trong `src/routes/index.js` neu file route moi
- [ ] SQL dung bang/cot trong database `phoneShop`
- [ ] Response JSON khop `docs/API.md`
- [ ] Error tra `{ message, code }`
- [ ] Test browser/Postman endpoint moi

### Flutter

- [ ] Them path vao `api_endpoints.dart`
- [ ] Tao model `fromJson` / `toEntity`
- [ ] Remote datasource goi `ApiClient`, khong goi MySQL
- [ ] Repository impl noi datasource voi domain
- [ ] Bloc goi repository, co loading/success/error
- [ ] UI dung `context.tr()`, `AppColors`, `Theme.of(context)`
- [ ] Register DI trong `main.dart`
- [ ] Cap nhat `docs/features/<feature>/SPEC.md`

---

## 7. Loi thuong gap

| Trieu chung | Nguyen nhan | Cach sua |
|-------------|-------------|----------|
| `EADDRINUSE :3000` | Backend cu con chay | `netstat -ano \| findstr :3000` → `taskkill /PID <pid> /F` |
| `Access denied` (password dung tren Aiven) | Windows env `DB_PASSWORD` cu ghi de `.env` | Xoa bien User env hoac da co `override: true` trong `db.js` |
| `Access denied` (password sai) | Password Aiven doi | Reset password tren Aiven, cap nhat `.env`, restart |
| `Cannot GET /` | Khong co route `/` | Dung `/health` hoac `/products` — binh thuong |
| `/health` ok nhung Flutter loi | Sai `baseUrl` | Doi `10.0.2.2` vs IP LAN |
| Connection refused | Backend chua chay | `cd backend && npm start` |
| Cleartext not permitted | Thieu manifest Android | `usesCleartextTraffic="true"` + `INTERNET` |

---

## 8. Prompt mau cho AI agent (feature moi can MySQL)

```text
Doc docs/features/backend/AGENT.md va docs/features/<feature>/SPEC.md truoc.
Implement <task> theo dung luong:
Page -> Bloc -> Repository -> RemoteDataSource -> ApiClient -> Backend (pool.query) -> MySQL.

Backend:
- Dung pool tu backend/db.js, khong tao connection rieng.
- Them route trong backend/src/routes/ va dang ky trong src/routes/index.js.
- Cap nhat docs/API.md.

Flutter:
- Khong query MySQL trong UI/BLoC.
- Khong hard-code text UI.
- Register DI trong main.dart.
- Cap nhat SPEC.md va feature AGENT.md neu co.
```

---

## 9. Lich su thay doi

| Ngay | Noi dung |
|------|-------------|
| 2026-06-26 | Tach backend: routes/services trong `backend/src/`, `server.js` chi entry |
| 2026-06-19 | Tao guide: db.js pool dung chung, dotenv override, luong backend + Flutter giong products |
