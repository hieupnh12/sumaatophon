# Chat Feature SPEC

## Muc tieu

Chat 1-1 real-time giua **user** va **admin** qua backend Express + Socket.IO + MySQL.

## Kien truc

```text
Flutter (ChatBloc)
  -> REST: load threads / messages
  -> WebSocket (Socket.IO): send_message, new_message, threads_updated
    -> MySQL: chat_threads, chat_messages
```

## Vai tro

| Role | UI |
|------|-----|
| `user` | Tab Hỗ trợ → chat trực tiếp với support |
| `admin` | Tab Hỗ trợ → danh sách hội thoại → chọn user để trả lời |

## API

| Method | Path | Mo ta |
|--------|------|-------|
| GET | `/chat/threads?role=admin` | Admin: danh sach thread |
| GET | `/chat/threads/mine?userId=...` | User: lay/tao thread |
| GET | `/chat/threads/:id/messages?role=...` | Lich su tin nhan |

## WebSocket events

Client Flutter phai ket noi Socket.IO voi **origin** va **path** tach biet khi API co prefix Nginx:

| Moi truong | Origin | Path |
|------------|--------|------|
| Local / USB debug | `http://127.0.0.1:3000` | `/socket.io` |
| Production VPS | `https://maclenin.io.vn` | `/mobile/socket.io` |

Neu path sai (mac dinh `/socket.io` o root), client nhan HTML static site thay vi handshake Socket.IO.

Nginx can `Upgrade` / `Connection` headers — xem `backend/deploy/nginx-api-mobile.conf.example`.

**Quan trong:** bat `gzip off` trong block `/mobile/` — nginx gzip `text/plain` (handshake Socket.IO polling) lam `socket_io_client` treo timeout du preflight HttpClient van pass.

| Event | Huong | Mo ta |
|-------|-------|-------|
| `send_message` | Client → Server | Gui tin `{ threadId, text }` |
| `new_message` | Server → Client | Tin moi |
| `join_thread` | Admin → Server | Admin vao room thread |
| `threads_updated` | Server → Admin inbox | Cap nhat danh sach |

## Demo accounts

| Email | Role |
|-------|------|
| admin@phoneshop.com | admin |
| user@phoneshop.com | user |

Password: `password123`

## Test

Mo 2 trinh duyet (Chrome + Edge): dang nhap user va admin, gui tin tu user, admin thay trong inbox va tra loi real-time.
