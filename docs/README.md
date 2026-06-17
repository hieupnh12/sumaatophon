# Project Documentation

Thu muc nay chua dac ta chuc nang de AI agent va developer lam viec thong nhat.

Quy tac su dung:

- `AGENTS.md` o root la luat chung cho toan bo project.
- `docs/ARCHITECTURE.md` mo ta kien truc tong the.
- `docs/API.md` mo ta contract API backend.
- `docs/DATABASE.md` mo ta schema SQLite local.
- `docs/CONVENTIONS.md` mo ta quy uoc dat ten/code style.
- `docs/features/<feature_name>/SPEC.md` la dac ta rieng cua tung feature.
- Truoc khi code feature nao, doc `AGENTS.md` va `SPEC.md` cua feature do.
- Neu them/sua hanh vi, UI, API, SQLite, localization cua feature, cap nhat `SPEC.md` cung luc voi code.
- Feature moi phai tao `docs/features/<feature_name>/SPEC.md` tu template.

Template:

```text
docs/features/_TEMPLATE/SPEC.md
```

Vi du prompt cho AI agent:

```text
Doc AGENTS.md va docs/features/checkout/SPEC.md truoc.
Sau do implement checkout dung theo dac ta.
Moi text UI phai them vao core/l10n/app_localizations.dart va dung context.tr().
Khong tu y doi style app.
```
