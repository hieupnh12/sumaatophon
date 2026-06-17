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

## Error Format

Backend nen tra loi loi theo format:

```json
{
  "message": "Human readable error",
  "code": "ERROR_CODE"
}
```

