# Feature: <Feature Name>

## 1. Muc tieu

Mo ta ngan gon feature nay dung de lam gi va phuc vu nguoi dung nao.

## 2. Pham vi

Bao gom:

- ...

Khong bao gom:

- ...

## 3. Luong nguoi dung

1. User ...
2. App ...
3. User ...

## 4. Hanh vi nghiep vu

- Quy tac 1.
- Quy tac 2.
- Dieu kien loi.
- Dieu kien thanh cong.

## 5. UI/UX

- Dung `AppColors`, `AppTheme`, `Theme.of(context)`.
- Ho tro light/dark mode.
- Khong hard-code text UI.
- Moi text dung `context.tr('key')`.
- Co empty/loading/error state neu phu hop.

## 6. Data/API/SQLite

API:

- Method: `GET/POST/PUT/DELETE`
- Endpoint: `/...`
- Request body:
- Response:

SQLite:

- Table:
- Columns:
- Local datasource:

Neu khong dung API/SQLite, ghi ro: `Khong dung`.

## 7. Localization keys

Bat buoc them vao `lib/core/l10n/app_localizations.dart` cho `vi`, `en`, `ja`.

```text
feature_title
feature_empty_title
feature_empty_desc
feature_error
```

## 8. Cau truc code du kien

```text
lib/features/<feature_name>/
  domain/
  data/
  presentation/
```

## 9. Acceptance criteria

- [ ] Dieu kien hoan thanh 1.
- [ ] Dieu kien hoan thanh 2.
- [ ] UI dung light/dark.
- [ ] Khong con user-facing text hard-code.
- [ ] `flutter analyze` khong co loi moi.

## 10. Ghi chu cho AI agent

- Khong sua file ngoai pham vi neu khong can.
- Khong thay doi style chung neu khong duoc yeu cau.
- Neu dac ta mau thuan voi code hien tai, hoi lai hoac neu ro gia dinh trong final.

