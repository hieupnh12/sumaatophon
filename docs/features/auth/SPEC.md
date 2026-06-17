# Feature: Auth

## 1. Muc tieu

Cho phep nguoi dung dang ky, dang nhap, quen mat khau va quan ly trang thai xac thuc trong app.

## 2. Pham vi

Bao gom:

- Login.
- Register.
- Forgot password UI.
- Luu/kiem tra user local bang SQLite neu backend auth chua co.
- Cap nhat `AuthBloc` de dieu huong vao app sau khi dang nhap.

Khong bao gom:

- OAuth/social login neu chua co yeu cau rieng.
- Phan quyen admin.
- Reset password that qua email neu backend chua ho tro.

## 3. Luong nguoi dung

1. User mo app.
2. Neu chua authenticated, app hien onboarding hoac login.
3. User nhap email/password.
4. `AuthBloc` goi `AuthRepository`.
5. Repository dung SQLite local hoac backend tuy cau hinh.
6. Thanh cong thi emit authenticated state va vao `AppMainPage`.

## 4. Hanh vi nghiep vu

- Email khong duoc rong va nen dung dinh dang email.
- Password khong duoc rong.
- Register phai tranh trung email neu dung SQLite.
- Login sai phai hien error state/message.
- Logout phai dua app ve login/onboarding theo flow hien tai.

## 5. UI/UX

- Form dung `InputDecorationTheme`.
- Button dung `ElevatedButton`.
- Error hien bang snackbar/text phu hop.
- Moi label/hint/button phai dung `context.tr()`.
- Ho tro dark/light.

## 6. Data/API/SQLite

SQLite local user:

- Table du kien: `users`
- Columns du kien: `id`, `name`, `email`, `passwordHash`, `createdAt`
- Datasource: `auth_local_datasource.dart`

Neu co backend auth sau nay:

- Login: `POST /auth/login`
- Register: `POST /auth/register`
- Forgot password: `POST /auth/forgot-password`

File lien quan hien tai:

```text
lib/features/auth/domain/entities/user_entity.dart
lib/features/auth/domain/repositories/auth_repository.dart
lib/features/auth/data/datasources/auth_mock_datasource.dart
lib/features/auth/data/repositories/auth_repository_impl.dart
lib/features/auth/presentation/bloc/auth_bloc.dart
lib/features/auth/presentation/pages/login_page.dart
lib/features/auth/presentation/pages/register_page.dart
lib/features/auth/presentation/pages/forgot_password_page.dart
```

## 7. Localization keys

Dang co hoac can co:

```text
login_title
login_subtitle
email_hint
password_hint
login_btn
forgot_password
no_account
register
logout
```

Neu them UI text moi, bat buoc them key cho `vi`, `en`, `ja`.

## 8. Cau truc code du kien

```text
lib/features/auth/
  domain/
    entities/
    repositories/
  data/
    datasources/
    models/
    repositories/
  presentation/
    bloc/
    pages/
```

## 9. Acceptance criteria

- [ ] Login/register khong query SQLite truc tiep trong UI.
- [ ] Auth state dieu huong dung trong `main.dart`.
- [ ] Validation co message ro rang.
- [ ] Text UI dung `context.tr()`.
- [ ] UI dung light/dark mode.

## 10. Ghi chu cho AI agent

- Neu dung SQLite, khong luu password plain text trong san pham that.
- Neu project van la demo, co the giu mock datasource nhung phai giu repository boundary.
- Khong bo qua `AuthRepository` de goi datasource truc tiep tu Bloc neu pattern hien tai da co repository.

