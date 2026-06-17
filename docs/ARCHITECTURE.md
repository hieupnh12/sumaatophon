# Architecture

Project `sumaatophon` dung Flutter theo huong feature-first va BLoC.

Luong phu thuoc chuan:

```text
Page/Widget
  -> Bloc
  -> Repository interface
  -> Repository implementation
  -> DataSource
  -> REST API / SQLite
```

## Layer

### Presentation

Nam trong:

```text
lib/features/<feature>/presentation/
```

Chua:

- `pages/`
- `widgets/`
- `bloc/`

Nhiem vu:

- Build UI.
- Lang nghe state.
- Gui event vao BLoC.
- Lay text bang `context.tr('key')`.
- Dung `AppColors`, `AppTheme`, `Theme.of(context)`.

Khong lam:

- Goi API.
- Query SQLite.
- Parse JSON.
- Hard-code user-facing text.

### Domain

Nam trong:

```text
lib/features/<feature>/domain/
```

Chua:

- Entity.
- Repository abstract.
- Use case neu feature phuc tap.

Domain khong phu thuoc Flutter UI.

### Data

Nam trong:

```text
lib/features/<feature>/data/
```

Chua:

- Model.
- Remote datasource.
- Local datasource.
- Repository implementation.

Data la noi duy nhat lam viec voi REST API hoac SQLite.

## Core

Thu muc `lib/core/` chua cac thanh phan dung chung:

```text
lib/core/
  database/
  network/
  errors/
  l10n/
  design_system/
  theme/
```

Neu thu muc chua ton tai, chi tao khi feature that su can.

## Dependency Injection

Project dung `get_it`, dang ky trong:

```text
lib/main.dart
```

Thu tu dang ky:

```text
DataSource -> Repository -> Bloc/Cubit
```

## Navigation

Hien tai project dung:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const FeaturePage()),
);
```

Khong them router package moi neu chua co nhu cau ro rang.

## Localization

Moi text hien thi tren UI phai nam trong:

```text
lib/core/l10n/app_localizations.dart
```

UI dung:

```dart
context.tr('key')
```

## Feature Specification

Moi feature phai co dac ta:

```text
docs/features/<feature>/SPEC.md
```

Khi code thay doi UI/API/SQLite/hang vi, cap nhat SPEC cung luc.

