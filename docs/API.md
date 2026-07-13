# API Contract

Flutter app khong ket noi truc tiep MySQL. Moi du lieu MySQL phai di qua backend REST API.

Base URL nen dat trong:

```text
lib/core/network/api_endpoints.dart
```

API client nen dat trong:

```text
lib/core/network/api_client.dart
```

## Products

### List products

```text
GET /products
```

Query optional:

```text
search
brand
minPrice
maxPrice
ram
rom
```

Response mau:

```json
[
  {
    "id": "iphone-15-pro",
    "name": "iPhone 15 Pro",
    "brand": "Apple",
    "price": 999,
    "originalPrice": 1099,
    "imageUrl": "https://example.com/iphone.png",
    "galleryImages": [],
    "rating": 4.8,
    "reviewCount": 120,
    "ramRomOptions": ["8GB/256GB"],
    "colors": ["#000000", "#FFFFFF"],
    "specifications": {
      "Display": "6.1 inch"
    },
    "isNew": true
  }
]
```

### Product detail

```text
GET /products/{id}
```

Response: mot object product nhu tren.

### Product feedback status

```text
GET /products/{id}/feedback-status?customerId={customerId}
```

Response:

```json
{
  "canReview": true,
  "hasReviewed": false
}
```

- `canReview`: khach da mua san pham trong don `DELIVERED`/`COMPLETED` va chua danh gia.
- `hasReviewed`: khach da co feedback hop le cho san pham nay.

### Submit product feedback

```text
POST /products/{id}/feedbacks
```

Request:

```json
{
  "customerId": 12,
  "rate": 5,
  "content": "San pham rat tot, giao hang nhanh."
}
```

Response `201`: feedback vua tao (id, rate, content, date, customerName).

Loi thuong gap:

- `FEEDBACK_NOT_ELIGIBLE` — chua mua hoac don chua hoan tat.
- `FEEDBACK_ALREADY_EXISTS` — da danh gia san pham nay.
- `FEEDBACK_INVALID_RATE` — rate ngoai 1-5.
- `FEEDBACK_INVALID_CONTENT` — noi dung qua ngan (< 3 ky tu).

### List product feedbacks

```text
GET /products/{id}/feedbacks
```

Response: mang feedback (rate, content, date, customerName).

## Auth

Neu auth van dung SQLite local thi cac endpoint nay chua bat buoc.

### Login

```text
POST /auth/login
```

Request:

```json
{
  "email": "user@example.com",
  "password": "secret"
}
```

Response:

```json
{
  "user": {
    "id": "user-1",
    "name": "User",
    "email": "user@example.com"
  },
  "token": "jwt-token"
}
```

### Register

```text
POST /auth/register
```

Request:

```json
{
  "name": "User",
  "email": "user@example.com",
  "password": "secret"
}
```

## Orders / Checkout

### Create order

```text
POST /orders
```

Request:

```json
{
  "userId": "user-1",
  "items": [
    {
      "productId": "iphone-15-pro",
      "quantity": 1,
      "price": 999
    }
  ],
  "address": "123 Nguyen Van Linh, District 7, Ho Chi Minh City",
  "shippingMethod": "standard",
  "shippingCost": 5,
  "paymentMethod": "cod",
  "subtotal": 999,
  "discount": 0,
  "total": 1004
}
```

Response:

```json
{
  "id": "order-1",
  "status": "pending",
  "total": 1004,
  "createdAt": "2026-06-17T08:00:00Z"
}
```

### List orders

```text
GET /orders?userId={userId}
```

### Order detail

```text
GET /orders/{id}
```

## Stores

### List stores

```text
GET /stores
GET /stores?lat=10.7769&lng=106.7008
```

Query optional:

```text
lat
lng
```

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

`distanceKm` chi co khi truyen `lat` va `lng`.

## Error Format

Backend nen tra loi loi theo format:

```json
{
  "message": "Human readable error",
  "code": "ERROR_CODE"
}
```

