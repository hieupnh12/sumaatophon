# Local Database

Project dung SQLite cho du lieu local tren thiet bi nguoi dung.

Database chung nen dat tai:

```text
lib/core/database/app_database.dart
```

Moi feature dung SQLite phai truy cap qua local datasource:

```text
lib/features/<feature>/data/datasources/<feature>_local_datasource.dart
```

Khong query SQLite truc tiep trong UI hoac BLoC.

## Users

Dung cho auth local neu chua co backend auth.

Table:

```text
users
```

Columns de xuat:

```text
id TEXT PRIMARY KEY
name TEXT NOT NULL
email TEXT NOT NULL UNIQUE
passwordHash TEXT NOT NULL
createdAt TEXT NOT NULL
updatedAt TEXT
```

Ghi chu:

- San pham that khong luu password plain text.
- Neu demo tam thoi, ghi ro trong SPEC cua `auth`.

## Sessions

Neu can luu phien dang nhap:

```text
sessions
```

Columns de xuat:

```text
id TEXT PRIMARY KEY
userId TEXT NOT NULL
token TEXT
createdAt TEXT NOT NULL
expiresAt TEXT
```

## Cart Items

Chi can neu muon giu cart sau khi tat app.

Table:

```text
cart_items
```

Columns de xuat:

```text
productId TEXT PRIMARY KEY
quantity INTEGER NOT NULL
createdAt TEXT NOT NULL
updatedAt TEXT NOT NULL
```

Product detail day du van nen lay tu API/cache product, cart chi nen luu id va quantity de tranh stale data.

## Favorites

Neu them feature yeu thich:

```text
favorites
```

Columns de xuat:

```text
productId TEXT PRIMARY KEY
createdAt TEXT NOT NULL
```

## Products Cache

Dung cho offline fallback sau khi da load san pham tu API.

Table:

```text
products_cache
```

Columns:

```text
id TEXT PRIMARY KEY
name TEXT NOT NULL
brand TEXT NOT NULL
price REAL NOT NULL
original_price REAL NOT NULL
image_url TEXT NOT NULL
gallery_images TEXT NOT NULL
rating REAL NOT NULL
review_count INTEGER NOT NULL
ram_rom_options TEXT NOT NULL
colors TEXT NOT NULL
specifications TEXT NOT NULL
is_new INTEGER NOT NULL DEFAULT 0
stock_quantity INTEGER NOT NULL DEFAULT 0
cached_at TEXT NOT NULL
```

Ghi chu: list/map field luu dang JSON string trong SQLite.

## Migration

Khi thay doi schema:

- Tang `databaseVersion`.
- Viet migration ro rang trong `app_database.dart`.
- Cap nhat file nay va SPEC cua feature lien quan.

