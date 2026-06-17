# Code Conventions

File nay gom quy uoc dat ten va to chuc code cho project.

## Naming

Feature folder:

```text
products
checkout
store_locator
```

Entity:

```text
Product
CartItem
Order
DeliveryAddress
```

Model:

```text
ProductModel
OrderModel
UserModel
```

Repository:

```text
ProductRepository
ProductRepositoryImpl
```

Datasource:

```text
ProductRemoteDataSource
AuthLocalDataSource
```

BLoC:

```text
ProductBloc
LoadProductsEvent
ProductLoaded
ProductError
```

Page:

```text
ProductListPage
ProductDetailPage
CheckoutPage
```

Widget:

```text
ProductCard
CartItemTile
OrderSummary
```

## File Names

Dung snake_case:

```text
product_repository.dart
product_repository_impl.dart
product_remote_datasource.dart
product_card.dart
checkout_page.dart
```

## Localization Keys

Dung tien to feature:

```text
checkout_title
checkout_confirm_order
cart_empty_title
products_not_found_title
```

Khong dat key qua chung chung neu chi dung trong mot feature.

## UI

- Dung `AppColors`.
- Dung `Theme.of(context)`.
- Dung `context.tr('key')`.
- Tach widget khi page qua dai.
- Khong goi API/SQLite trong widget.

## Comments

Chi comment khi logic kho hieu.

Khong comment kieu:

```dart
// Set name
name = value;
```

## Tests

Neu them logic tinh toan hoac repository, nen them test.

Vi du:

```text
test/features/cart/cart_bloc_test.dart
test/features/checkout/checkout_bloc_test.dart
```

