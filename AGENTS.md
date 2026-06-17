# AI Agent Feature Playbook

File nay la quy chuan chung cho moi AI agent hoac developer khi them, sua, refactor feature trong project `sumaatophon`.

Muc tieu:

- Moi feature moi phai co cung mot cach to chuc code.
- UI phai bam theo design system hien co, khong moi nguoi mot kieu.
- Moi text hien thi tren UI phai di qua `core/l10n/app_localizations.dart`.
- Moi feature phai co dac ta tai `docs/features/<feature_name>/SPEC.md`.
- API MySQL phai di qua backend REST API, Flutter khong ket noi truc tiep MySQL.
- SQLite chi dung cho du lieu local tren may nguoi dung.
- Khong tron UI, BLoC, API, database vao cung mot file.

---

## 1. Doc truoc khi code

Truoc khi them feature, AI agent bat buoc doc cac file sau neu co lien quan:

- `lib/main.dart`
- `lib/core/design_system/app_colors.dart`
- `lib/core/design_system/app_theme.dart`
- `lib/core/l10n/app_localizations.dart`
- `lib/core/theme/language_cubit.dart`
- `docs/ARCHITECTURE.md`
- `docs/CONVENTIONS.md`
- `docs/features/<feature_name>/SPEC.md`
- Feature gan nhat co cung pattern, vi du:
  - `lib/features/products/`
  - `lib/features/auth/`
  - `lib/features/cart/`
  - `lib/features/checkout/`

Neu feature moi can API:

- Doc `lib/features/products/data/` de xem cach goi remote datasource.
- Doc `docs/API.md`.

Neu feature moi can SQLite:

- Doc `lib/features/auth/data/` hoac `lib/core/database/` neu da ton tai.
- Doc `docs/DATABASE.md`.

Khong duoc tao style moi khi pattern cu da dap ung duoc.

---

## 1.1. Tai lieu dac ta feature

Moi feature phai co file dac ta:

```text
docs/features/<feature_name>/SPEC.md
```

Feature moi phai tao SPEC tu template:

```text
docs/features/_TEMPLATE/SPEC.md
```

Khi code thay doi cac phan sau, phai cap nhat SPEC cung luc:

- Hanh vi nghiep vu.
- UI/UX.
- API endpoint/request/response.
- SQLite table/columns.
- Localization keys.
- Acceptance criteria.
- Cau truc file/thumuc cua feature.

Neu user yeu cau code feature nhung chua co SPEC:

1. Tao `docs/features/<feature_name>/SPEC.md`.
2. Ghi ro gia dinh va pham vi.
3. Sau do moi implement code.

Neu SPEC va code hien tai mau thuan:

- Uu tien hoi lai user neu anh huong lon.
- Neu la sai lech nho, sua code theo SPEC va neu ro trong final.

---

## 2. Kien truc chuan cho moi feature

Moi feature nen nam trong:

```text
lib/features/<feature_name>/
```

Feature day du nen co:

```text
lib/features/<feature_name>/
  domain/
    entities/
      <entity>.dart
    repositories/
      <feature_name>_repository.dart

  data/
    models/
      <entity>_model.dart
    datasources/
      <feature_name>_remote_datasource.dart
      <feature_name>_local_datasource.dart
    repositories/
      <feature_name>_repository_impl.dart

  presentation/
    bloc/
      <feature_name>_bloc.dart
    pages/
      <feature_name>_page.dart
    widgets/
      <feature_name>_section.dart
```

Khong phai feature nao cung bat buoc co tat ca thu muc:

- Chi hien thi UI tinh: co the chi can `presentation/`.
- Co logic state: can `presentation/bloc/`.
- Co entity dung lai nhieu noi: them `domain/entities/`.
- Co API hoac SQLite: bat buoc them `data/`.
- Co goi API MySQL: dung `remote_datasource`.
- Co luu local SQLite: dung `local_datasource`.

---

## 3. Vai tro tung tang

### `presentation/`

Chi chua UI va state presentation.

Duoc phep:

- `Page`
- `Widget`
- `Bloc`
- `Event`
- `State`
- Goi `context.read<Bloc>().add(...)`
- Doc text bang `context.tr('key')`
- Dung `Theme.of(context)` va `AppColors`

Khong duoc:

- Goi API truc tiep.
- Query SQLite truc tiep.
- Parse JSON truc tiep trong widget.
- Hard-code text UI.
- Viet business rule lon trong widget.

### `domain/`

Chua logic nghiep vu doc lap framework.

Nen chua:

- Entity thuan Dart.
- Abstract repository.
- Use case neu feature phuc tap.

Khong import Flutter UI vao domain.

### `data/`

Chua implementation that su cua API/local database.

Nen chua:

- Model co `fromJson`, `toJson`, `fromMap`, `toMap`.
- Remote datasource goi REST API.
- Local datasource goi SQLite.
- Repository implementation noi datasource voi domain.

---

## 4. Quy tac API MySQL

Flutter khong ket noi truc tiep MySQL.

Dung luong dung:

```text
Flutter app
  -> REST API backend
  -> MySQL database
```

Vi du voi products:

```text
ProductBloc
  -> ProductRepository
  -> ProductRepositoryImpl
  -> ProductRemoteDataSource
  -> Backend API
  -> MySQL
```

File nen co:

```text
lib/core/network/api_client.dart
lib/core/network/api_endpoints.dart
lib/features/products/data/datasources/product_remote_datasource.dart
lib/features/products/data/models/product_model.dart
lib/features/products/data/repositories/product_repository_impl.dart
```

Quy tac:

- Endpoint dat trong `api_endpoints.dart`, khong rai URL trong UI.
- Convert JSON trong `model`, khong convert trong page.
- Repository tra ve entity/domain object cho BLoC.
- BLoC khong biet endpoint la gi.

---

## 5. Quy tac SQLite

SQLite dung cho du lieu local nhu:

- User dang ky/dang nhap local.
- Session local.
- Cart cache.
- Favorite cache.
- Recent search.

Nen dat database chung tai:

```text
lib/core/database/app_database.dart
```

Feature dung SQLite thi them:

```text
lib/features/<feature_name>/data/datasources/<feature_name>_local_datasource.dart
lib/features/<feature_name>/data/models/<entity>_model.dart
```

Quy tac:

- SQL query khong duoc viet trong UI.
- BLoC khong query SQLite truc tiep.
- Local datasource chiu trach nhiem insert/update/delete/select.
- Model chiu trach nhiem `fromMap` va `toMap`.

---

## 6. Quy tac BLoC

Dat file:

```text
lib/features/<feature_name>/presentation/bloc/<feature_name>_bloc.dart
```

Quy tac dat ten:

```dart
abstract class FeatureEvent extends Equatable {}

class LoadFeatureEvent extends FeatureEvent {}
class AddFeatureEvent extends FeatureEvent {}
class UpdateFeatureEvent extends FeatureEvent {}
class DeleteFeatureEvent extends FeatureEvent {}

abstract class FeatureState extends Equatable {}

class FeatureInitial extends FeatureState {}
class FeatureLoading extends FeatureState {}
class FeatureLoaded extends FeatureState {}
class FeatureError extends FeatureState {}
```

Voi feature co state form don gian, co the dung mot state class duy nhat co `copyWith`.

BLoC duoc phep:

- Goi repository/use case.
- Validate input don gian.
- Emit loading/success/error.

BLoC khong duoc:

- Dung `BuildContext`.
- Show dialog/snackbar.
- Format UI string phuc tap.
- Goi API client truc tiep neu da co repository.

---

## 7. Quy tac dependency injection

Moi datasource/repository/bloc moi phai dang ky trong `setupDependencyInjection()` cua `lib/main.dart`.

Thu tu dang ky:

```dart
// Datasources
sl.registerLazySingleton(() => FeatureRemoteDataSource(...));
sl.registerLazySingleton(() => FeatureLocalDataSource(...));

// Repositories
sl.registerLazySingleton<FeatureRepository>(
  () => FeatureRepositoryImpl(sl(), sl()),
);

// Blocs
sl.registerFactory(() => FeatureBloc(repository: sl()));
```

Neu feature can duoc share toan app, them vao `MultiBlocProvider`.

Neu Bloc chi dung trong mot page rieng, co the provide ngay tai page route.

---

## 8. Quy tac navigation

Hien project dang dung `Navigator.push` voi `MaterialPageRoute`.

Khi them page moi:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const FeaturePage()),
);
```

Khong tu y them package router moi neu project chua can.

Neu them tab moi vao main app:

- Sua `AppMainPage` trong `lib/main.dart`.
- Them page vao `IndexedStack`.
- Them item vao `BottomNavigationBar`.
- Them key l10n cho label tab.

---

## 9. Quy tac UI design

UI phai bam theo design system:

- Mau dung `AppColors`.
- Theme dung `Theme.of(context)`.
- Text style uu tien `theme.textTheme`.
- Button uu tien `ElevatedButton`, `OutlinedButton`, `IconButton`.
- Form dung `InputDecorationTheme` hien co.
- Icon dung Material Icons san co.
- Dark/light mode phai hoat dong.

Pattern mau:

```dart
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
```

Mau nen dung:

```dart
color: isDark ? AppColors.darkCard : AppColors.lightCard
border: Border.all(
  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
)
```

Quy tac giao dien:

- Khong hard-code palette moi neu `AppColors` da co mau phu hop.
- Khong tao UI qua lech style hien co.
- Border radius nen theo app hien tai: 12, 16, 20, 24.
- Page nen co `AppBar` neu la man rieng.
- List item nen tach thanh widget rieng trong `presentation/widgets`.
- Section lon trong checkout/cart/profile nen tach widget rieng de tranh page qua dai.
- Loading state nen co skeleton/shimmer neu feature la list san pham.
- Error state phai co message than thien va cach thu lai neu phu hop.
- Empty state phai co icon, title, description, action neu can.

Khong nen:

- Tao component trang tri qua nhieu mau.
- Tao text tieng Anh/Viet truc tiep trong widget.
- Tao card long card neu khong can.
- De text tran layout tren mobile.

---

## 10. Quy tac localization bat buoc

Moi text hien thi tren UI phai them key vao:

```text
lib/core/l10n/app_localizations.dart
```

Hien project dang co cac ngon ngu:

- `vi`
- `en`
- `ja`

Khi them text moi, bat buoc them du key cho tat ca ngon ngu dang co.

Dung trong UI:

```dart
Text(context.tr('feature_title'))
```

Khong dung:

```dart
Text('Feature Title')
```

Ngoai le duoc phep hard-code:

- Ten brand nhu `phoneShop`.
- Ma khuyen mai nhu `APPLE10`.
- Gia tri ky thuat nhu `8GB`, `256GB`.
- Placeholder tam thoi trong log/debug, khong hien thi cho user.

Quy tac dat key:

```text
<feature>_<screen/section>_<meaning>
```

Vi du:

```text
cart_empty_title
cart_empty_desc
checkout_address_title
checkout_shipping_title
checkout_payment_title
checkout_confirm_order
profile_logout
```

Khi them feature moi, tao block key rieng trong moi language:

```dart
// Checkout
'checkout_title': 'Thanh toan',
'checkout_address_title': 'Dia chi giao hang',
```

Checklist l10n:

- Them key vao `vi`.
- Them key vao `en`.
- Them key vao `ja`.
- Thay toan bo text trong UI bang `context.tr('key')`.
- Kiem tra khong con string UI hard-code trong file page/widget/bloc.
- Neu text co bien, ghep nhu sau:

```dart
Text('${context.tr('cart_items_count')}: ${state.totalItems}')
```

Neu can cau phuc tap hon, uu tien tao key ro nghia va ghep bien ngan gon.

---

## 11. Quy tac them feature moi tu A den Z

### Buoc 1: Xac dinh feature

Tra loi cac cau hoi:

- Feature ten gi?
- Co UI khong?
- Co BLoC state khong?
- Co API khong?
- Co SQLite khong?
- Co can l10n khong? Mac dinh la co neu hien text.
- Co can them vao bottom navigation khong?

### Buoc 2: Tao cau truc thu muc

Vi du feature `orders`:

```text
lib/features/orders/
  domain/
    entities/
      order.dart
    repositories/
      order_repository.dart
  data/
    models/
      order_model.dart
    datasources/
      order_remote_datasource.dart
    repositories/
      order_repository_impl.dart
  presentation/
    bloc/
      order_bloc.dart
    pages/
      order_list_page.dart
      order_detail_page.dart
    widgets/
      order_card.dart
      order_status_chip.dart
```

### Buoc 3: Viet entity

Entity nam trong `domain/entities`.

Quy tac:

- Dung `Equatable` neu entity can compare.
- Khong chua `fromJson`.
- Khong import UI.

### Buoc 4: Viet model

Model nam trong `data/models`.

Quy tac:

- Extend hoac convert sang entity.
- Co `fromJson` cho API.
- Co `toJson` neu can gui API.
- Co `fromMap`/`toMap` neu dung SQLite.

### Buoc 5: Viet datasource

Remote datasource:

- Goi API.
- Parse response thanh model.
- Throw exception neu loi.

Local datasource:

- Query SQLite.
- Convert map thanh model.

### Buoc 6: Viet repository

Repository interface nam trong `domain/repositories`.

Repository implementation nam trong `data/repositories`.

Bloc chi phu thuoc interface repository, khong phu thuoc datasource.

### Buoc 7: Viet BLoC

Them event/state can thiet.

Bat buoc co error state hoac error field neu co API/database.

### Buoc 8: Viet UI page

Page chi build UI va gui event.

Nen tach widget:

- List item
- Summary
- Form section
- Empty state
- Error state

### Buoc 9: Them l10n

Them tat ca text vao `app_localizations.dart`.

Khong merge neu chua co day du key cho `vi`, `en`, `ja`.

### Buoc 10: Dang ky DI

Sua `lib/main.dart`:

- Register datasource.
- Register repository.
- Register bloc.
- Them `BlocProvider` neu can global.

### Buoc 11: Ket noi navigation

Neu page duoc mo tu feature khac, them route bang `Navigator.push`.

Neu page la tab chinh, sua `AppMainPage`.

### Buoc 12: Verify

Chay:

```text
flutter analyze
flutter test
```

Neu co loi do dependency thieu:

```text
flutter pub get
```

---

## 12. Checklist truoc khi hoan thanh

AI agent phai tu kiem tra:

- Feature dung dung thu muc `features/<feature_name>`.
- Khong co API call trong page/widget.
- Khong co SQLite query trong page/widget/bloc.
- BLoC co loading/success/error phu hop.
- UI dung `AppColors`, `Theme.of(context)`, design system hien co.
- Tat ca user-facing text dung `context.tr(...)`.
- Da them l10n day du cho `vi`, `en`, `ja`.
- Neu them datasource/repository/bloc, da dang ky trong `main.dart`.
- Neu them dependency, da them vao `pubspec.yaml`.
- Khong sua file khong lien quan.
- Khong refactor lon neu user chi yeu cau feature nho.
- Chay `flutter analyze` neu co the.
- Chay `flutter test` neu co test lien quan.

---

## 13. Mau prompt cho AI agent khi them feature

Dung prompt nay cho agent khac:

```text
Hay them feature <ten_feature> theo dung quy chuan trong AGENTS.md.

Yeu cau:
- Giu cau truc feature-first.
- Neu co API, tao data/models, data/datasources, data/repositories, domain/repositories.
- Neu co SQLite, query chi nam trong local datasource.
- UI phai dung AppColors, AppTheme, Theme.of(context).
- Moi text UI phai them vao core/l10n/app_localizations.dart cho vi/en/ja va dung context.tr().
- Dang ky dependency trong main.dart neu them datasource/repository/bloc.
- Khong hard-code text hien thi trong page/widget.
- Khong doi style app neu khong duoc yeu cau.
- Chay flutter analyze sau khi sua neu co the.
```

---

## 14. Quy tac rieng cho cart va checkout

Cart nen chiu trach nhiem:

- Danh sach san pham trong gio.
- So luong.
- Xoa san pham.
- Ma giam gia.
- Tam tinh, giam gia, tong tien truoc ship.

Checkout nen chiu trach nhiem:

- Dia chi giao hang.
- Phuong thuc van chuyen.
- Phuong thuc thanh toan.
- Phi ship.
- Tao don hang.
- Submit order qua API neu co backend.

Khong nen de checkout sua truc tiep product list.
Khong nen de cart goi API tao don hang.

Neu co order history that:

```text
lib/features/orders/
```

Checkout submit thanh cong thi tao order, clear cart, sau do user co the xem trong orders.

---

## 15. Khi nao can mo them file?

Chi mo them file khi co ly do:

- Page qua dai tren 250-300 dong: tach widget.
- Entity dung o nhieu noi: dua vao `domain/entities`.
- Co API: them remote datasource/model/repository.
- Co SQLite: them local datasource/model.
- Bloc qua nhieu event/state: co the tach event/state thanh file rieng neu can.
- Text moi tren UI: bat buoc sua `app_localizations.dart`.

Khong mo them file chi de "cho dung clean architecture" neu feature rat nho va khong co API/local database.
