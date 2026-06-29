# TECHNICAL REPORT: MOBILE ECOMMERCE APPLICATION

**Course:** Flutter Application Development  
**Team Size:** 5 Members  
**Project Name:** sumaatophon (phoneShop)  
**Repository:** `E:/Project/sumaatophon`  
**Version:** 1.0.0+1  
**Date:** June 29, 2026

---

## 1. Team Introduction

### 1.1. Team Members and Roles

| Full Name | Role | Main Responsibilities | Contribution |
|-----------|------|-----------------------|--------------|
| **Lê Mỹ Lộc** | Team Leader / Developer | Product List screen, Product Detail screen, product browsing UX, product data presentation | 20% |
| **Nguyễn Minh Hiếu** | Developer | Shopping Cart screen, Checkout/Billing screen, PayOS payment flow, cart/order API integration | 20% |
| **Nguyễn Nhất Sinh** | Developer | Login screen, Profile/Warranty screen, Firebase Auth integration, OTP phone login, biometric auth support | 20% |
| **Dương Trí Toàn** | Developer | Notifications screen, Messaging/Chat screen, FCM push notifications, Socket.IO chat behavior | 20% |
| **Trần Văn Tuấn Minh** | Developer | Store Location map screen, localization (vi/en/ja), star reviews UI integration and consistency | 20% |

### 1.2. Correct Screen-Level Assignment (Must-Match Matrix)

| No. | Screen / Feature | Assigned Member | Primary Files |
|-----|------------------|-----------------|---------------|
| 1 | Login screen | **Nguyễn Nhất Sinh (Sinh)** | `lib/features/auth/presentation/pages/login_page.dart` |
| 2 | Profile / Warranty screen | **Nguyễn Nhất Sinh (Sinh)** | `lib/features/profile/presentation/pages/profile_page.dart` |
| 3 | Map (Store Location) + Language (vi/en/ja) + Star reviews UI | **Trần Văn Tuấn Minh (Minh)** | `lib/features/store_locator/presentation/pages/store_location_page.dart`, `lib/core/theme/language_cubit.dart`, `lib/core/l10n/app_localizations_*.dart` |
| 4 | Product List screen | **Lê Mỹ Lộc (Loc)** | `lib/features/products/presentation/pages/product_list_page.dart` |
| 5 | Product Detail screen | **Lê Mỹ Lộc (Loc)** | `lib/features/products/presentation/pages/product_detail_page.dart` |
| 6 | Shopping Cart screen | **Nguyễn Minh Hiếu (Hieu)** | `lib/features/cart/presentation/pages/cart_page.dart` |
| 7 | Checkout/Billing screen | **Nguyễn Minh Hiếu (Hieu)** | `lib/features/checkout/presentation/pages/checkout_page.dart` |
| 8 | Notifications screen | **Dương Trí Toàn (Toan)** | `lib/features/notifications/presentation/pages/notifications_page.dart` |
| 9 | Messaging/Chat screen | **Dương Trí Toàn (Toan)** | `lib/features/chat/presentation/pages/chat_hub_page.dart` |

### 1.3. Team of 5 (Official Statement)

- **Lê Mỹ Lộc** — Team Leader; Product List + Product Detail.
- **Nguyễn Minh Hiếu** — Cart + Checkout + PayOS.
- **Nguyễn Nhất Sinh** — Login + Profile/Warranty + Firebase Auth OTP.
- **Dương Trí Toàn** — Notifications + Chat + FCM + Socket.IO.
- **Trần Văn Tuấn Minh** — Store Map + Localization + Review stars UI.

### 1.4. Collaboration Method

- The team follows a feature-first folder structure.
- Each owner is responsible for one feature end-to-end: UI, state, data flow, and acceptance tests.
- Shared standards are aligned with `AGENTS.md`, `docs/ARCHITECTURE.md`, and feature `SPEC.md` files.
- Localization is mandatory for all user-facing strings in three languages (`vi`, `en`, `ja`).
- Integration tasks (auth sync, cart APIs, order APIs, socket path, FCM token registration) are reviewed jointly.

---

## 2. Case Study

### 2.1. Project Title

**sumaatophon (phoneShop) — Premium smartphone shopping application on Flutter.**

### 2.2. Domain

**Domain:** Mobile E-commerce (online sales, order management, customer support, and post-sale service).

### 2.3. Problem Context

- Smartphone buyers often compare many models, colors, RAM/ROM versions, and promotions before deciding.
- Users expect a fast shopping flow from browse to checkout with clear stock and price visibility.
- Users also expect account convenience: social login, OTP verification, and secure re-login options.
- Support channels matter: in-app chat and timely notifications improve trust and conversion.
- Many users need partial offline browsing when network conditions are unstable.

### 2.4. Solution Overview

sumaatophon provides:

- Product browsing with search, filters, pagination, ratings, and detailed product pages.
- Cart and checkout connected to backend MySQL through REST APIs.
- Firebase Auth integration (Google Sign-In, OTP phone, and biometric re-auth support).
- Real-time customer support using Socket.IO messaging.
- Push/in-app notifications using Firebase Cloud Messaging.
- Partial offline support with SQLite `products_cache`.

### 2.5. Core Project Facts (Validated Against Codebase)

- Project name in repository and docs: **sumaatophon (phoneShop)**.
- Flutter architecture: **BLoC + get_it** dependency injection.
- The app does **not** use Provider as primary state management.
- Backend stack: **Node.js REST API + MySQL**.
- Cart persistence is on **MySQL** via API, **not SQLite**.
- SQLite is used for local `products_cache` data.
- Auth supports Firebase + Google + OTP + biometric.
- Chat supports Socket.IO.
- Notifications support FCM and local handling.
- Payment supports PayOS QR workflow.

### 2.6. Scope Boundaries

Included:

- Login/authentication journeys.
- Product list/detail browsing.
- Cart and checkout lifecycle.
- Notifications and chat.
- Store map screen and multilingual support.
- Warranty display in profile/order-related flow.

Not included:

- Full admin web dashboard implementation details.
- Production database migration scripts as primary deliverables.
- End-user hardware diagnostics or warranty claim processing portal.

---

## 3. Business Analysis / System Design

### 3.1. Requirements

#### 3.1.1. Functional Requirements

| ID | Requirement | Related Screens |
|----|-------------|-----------------|
| FR-01 | User can log in using Google, phone OTP, email/password fallback, and biometric re-entry | Login |
| FR-02 | User can view and manage profile, account preferences, and warranty-related info | Profile/Warranty |
| FR-03 | User can browse products, search, filter, and paginate through list | Product List |
| FR-04 | User can view product details, select variants, inspect specs, and reviews | Product Detail |
| FR-05 | User can add/update/remove cart items and apply promo code | Shopping Cart |
| FR-06 | User can complete checkout with shipping method and payment method including PayOS | Checkout/Billing |
| FR-07 | User can receive and manage notifications | Notifications |
| FR-08 | User can chat with support bot/staff in real-time | Messaging/Chat |
| FR-09 | User can locate physical stores on map screen | Store Location |
| FR-10 | User can switch language globally among vi/en/ja | Entire App |
| FR-11 | User can view star ratings and review snippets on key product interfaces | Product list/detail/review tile |

#### 3.1.2. Non-Functional Requirements

| ID | Requirement | Practical Response |
|----|-------------|--------------------|
| NFR-01 | Responsive product loading under normal network conditions | Pagination + shimmer loading + cache fallback |
| NFR-02 | Secure user identity and token handling | Firebase Auth + secure storage + backend sync |
| NFR-03 | Partial offline usability | SQLite `products_cache` fallback |
| NFR-04 | Maintainable and testable architecture | Feature-first + BLoC + repository pattern + get_it |
| NFR-05 | Multi-language consistency | `context.tr(...)` + vi/en/ja localization files |
| NFR-06 | Theme adaptability | Shared app theme and color system |
| NFR-07 | Reliability of chat and notifications | Socket.IO with proper Nginx path + FCM registration flow |

### 3.2. Application Architecture

#### 3.2.1. Layered Feature-First Structure

```text
presentation/
  pages + widgets + bloc
domain/
  entities + repository interfaces
data/
  models + datasources + repository implementations
```

#### 3.2.2. Data and Control Flow

```text
Page/Widget
  -> Bloc/Cubit
    -> Domain Repository (interface)
      -> RepositoryImpl
        -> Remote Data Source (REST / Socket.IO)
        -> Local Data Source (SQLite, when needed)
```

#### 3.2.3. Backend Interaction

```text
Flutter App
  -> Node.js REST API (Express routes)
    -> MySQL database
```

#### 3.2.4. Core Flutter Packages in Active Use

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | Predictable state management |
| `get_it` | Dependency injection |
| `http` | REST communication |
| `sqflite` | Local cache persistence |
| `firebase_auth` | Identity provider |
| `google_sign_in` | OAuth login |
| `firebase_messaging` | Push transport |
| `flutter_local_notifications` | Local display of push events |
| `socket_io_client` | Real-time chat connection |
| `local_auth` | Biometric verification |
| `pinput` | OTP input UI |
| `google_maps_flutter` | Store map capability (package available) |

### 3.3. Database Design

#### 3.3.1. MySQL (Primary System of Record)

##### A) Customers and Identity

| Column | Type | Constraint | Meaning |
|--------|------|------------|---------|
| `customer_id` | INT | PK AUTO_INCREMENT | MySQL customer identity |
| `firebase_uid` | VARCHAR | UNIQUE | Firebase identity bridge |
| `name` | VARCHAR | NOT NULL | Display name |
| `email` | VARCHAR | nullable | Account email |
| `phone` | VARCHAR | nullable | OTP phone number |
| `gender` | TINYINT | nullable | Profile metadata |
| `role` | VARCHAR | nullable | `user` or `admin` |

##### B) Product Catalog

| Table | Role |
|-------|------|
| `products` | Base product information |
| `product_versions` | Variant by color / RAM / ROM / price |
| `product_items` | IMEI-level inventory records |

##### C) Cart System

| Table | Key Columns | Notes |
|-------|-------------|-------|
| `carts` | `cart_id`, `customer_id`, `status` | One active cart per customer |
| `cart_items` | `cart_item_id`, `cart_id`, `product_version_id`, `quantity` | Quantity constrained by stock |

##### D) Orders and Warranty Logic

| Table | Purpose |
|-------|---------|
| `orders` | Order master information |
| `order_details` | Purchased product lines, quantity, pricing, warranty date |

Warranty is derived from product warranty period and purchase date.

##### E) Feedback and Ratings

| Column | Type | Meaning |
|--------|------|---------|
| `feedback_id` | INT | Primary key |
| `product_id` | INT | Target product |
| `customer_id` | INT | Reviewer |
| `rate` | DECIMAL | 1–5 stars |
| `content` | TEXT | Review text |
| `created_at` | DATETIME | Posted date |

##### F) Notifications

| Column | Type | Meaning |
|--------|------|---------|
| `id` | INT/VARCHAR | Notification id |
| `customer_id` | INT | Owner |
| `type` | VARCHAR | `product_new`, `order_status`, `chat_message` |
| `title` | TEXT | Title |
| `body` | TEXT | Body |
| `payload` | JSON | Navigation payload |
| `is_read` | BOOLEAN | Read state |
| `created_at` | DATETIME | Created date |

##### G) Chat Threads and Messages

| Table | Purpose |
|-------|---------|
| `chat_threads` | Conversation metadata |
| `chat_messages` | Individual chat messages |

#### 3.3.2. SQLite (Device-Local Cache)

##### `products_cache` table

| Column | Type | Constraint | Meaning |
|--------|------|------------|---------|
| `id` | TEXT | PRIMARY KEY | Product id |
| `name` | TEXT | NOT NULL | Product name |
| `brand` | TEXT | nullable | Product brand |
| `price` | REAL | nullable | Current price |
| `original_price` | REAL | nullable | Original price |
| `image_url` | TEXT | nullable | Thumbnail URL |
| `gallery_images` | TEXT | nullable | JSON image array |
| `ram_rom_options` | TEXT | nullable | JSON options |
| `colors` | TEXT | nullable | JSON colors |
| `specifications` | TEXT | nullable | JSON specs |
| `rating` | REAL | nullable | Average stars |
| `review_count` | INTEGER | nullable | Number of reviews |
| `is_new` | INTEGER | nullable | New badge flag |
| `stock_quantity` | INTEGER | nullable | Computed stock |
| `cached_at` | TEXT | nullable | Cache timestamp |

##### Important Clarification

- Cart data is **not** persisted in SQLite.
- Cart synchronization is API-driven and tied to MySQL customer identity.

### 3.4. New Technologies Beyond Core Syllabus

| Technology | Why It Matters | Evidence in Project |
|------------|----------------|---------------------|
| BLoC + get_it | Scalable state and DI | `main.dart` + `*_bloc.dart` files |
| Firebase Auth | Secure identity abstraction | `lib/features/auth/` |
| Google Sign-In | Fast login path | Auth data source/bloc flow |
| OTP Phone Login | Phone-based identity option | Auth flow + OTP pages/events |
| Biometric Auth | Convenient secure re-entry | `local_auth` integration |
| Socket.IO | Real-time support chat | Chat data source and backend socket setup |
| FCM | Push lifecycle communication | Push notification service |
| PayOS | QR payment support | Checkout payment flow |
| SQLite cache | Offline fallback | Product local data source |

---

## 4. Development Requirements

### 4.1. Implementation Details

#### 4.1.1. State Management Strategy

- `AuthBloc` handles auth lifecycle and user session.
- `ProductBloc` handles list/detail loading and filtering.
- `CartBloc` handles cart synchronization and summary calculations.
- `CheckoutBloc` handles information/payment steps and order submission.
- `NotificationBloc` handles list/read/delete/register-token interactions.
- `ChatBloc` handles thread loading, socket connect, send/receive lifecycle.
- `StoreLocatorBloc` handles map data and selected store index.
- `LanguageCubit` and `ThemeCubit` handle global app-level user preferences.

#### 4.1.2. Dependency Injection

- All major blocs, repositories, and data sources are registered through `get_it`.
- Registration order follows data source -> repository -> bloc factory.
- Screen-level providers obtain dependencies from service locator instead of manual wiring.

#### 4.1.3. Network and API Contract

- `ApiClient` and endpoint constants centralize URL/path definitions.
- UI does not call raw endpoints directly.
- Model mapping (`fromJson`, `toJson`) stays in data layer.

#### 4.1.4. Localization Requirement

- All user-visible strings are translated via `context.tr('key')`.
- Language options: Vietnamese (`vi`), English (`en`), Japanese (`ja`).
- Feature-based key naming conventions are followed.

#### 4.1.5. Design System Requirement

- Color usage follows app design tokens.
- Dialog confirmations use a shared component pattern.
- Dark/light compatibility is mandatory.

### 4.2. Testing Strategy

#### 4.2.1. Static Quality

- `flutter analyze` for compile/lint assurance.

#### 4.2.2. Unit and Logic Tests

- Cart total/discount calculations.
- Product JSON parsing and model conversion.
- Auth state transition behavior in normal and error scenarios.

#### 4.2.3. Widget Tests

- Product add-to-cart action visibility and button state.
- Cart empty state and checkout CTA behavior.
- Notification unread badge rendering.

#### 4.2.4. Manual Integration Validation

- User and admin chat exchange in real-time.
- Notification route redirection by payload type.
- PayOS transaction status polling flow.
- Offline fallback to local `products_cache`.

### 4.3. Deployment and Runtime Environment

| Area | Command / Detail |
|------|------------------|
| Android build | `flutter build apk --release` |
| iOS build | `flutter build ios --release` |
| Backend launch | `npm start` in `backend/` |
| Reverse proxy | Nginx config with Socket.IO path handling |
| Socket path (prod) | `/mobile/socket.io` |
| Critical proxy note | `gzip off` for mobile socket route |
| API base (example) | `https://maclenin.io.vn/mobile/` |

---

## 5. Demo of Functions (Detailed by Screen)

> This section follows real repository structure and implementation behavior.  
> Each screen includes goals, file structure, user flow, API usage, state management, UI/UX notes, and acceptance criteria.

---

### 5.1. Login Screen — Nguyễn Nhất Sinh (Sinh)

#### 5.1.1. Goals

- Provide secure sign-in paths for both convenience and reliability.
- Support multiple methods suitable for different user preferences.
- Ensure backend sync after identity verification to bind MySQL customer profile.
- Separate guest browsing from real authenticated customer sessions.
- Support returning users with biometric re-login.
- Keep login flow reusable when invoked from cart/checkout interruptions.

#### 5.1.2. File Structure

```text
lib/features/auth/
  domain/entities/user_entity.dart
  domain/repositories/auth_repository.dart
  data/models/user_model.dart
  data/datasources/auth_remote_datasource.dart
  data/datasources/auth_mock_datasource.dart
  data/repositories/auth_repository_impl.dart
  presentation/bloc/auth_bloc.dart
  presentation/pages/login_page.dart
  presentation/pages/register_page.dart
  presentation/pages/forgot_password_page.dart
  presentation/pages/link_phone_page.dart
```

#### 5.1.3. User Flow

1. App starts and triggers auth status check from secure storage/Firebase session.
2. If no valid real session exists, login page is shown.
3. User chooses one login path:
4. Path A: Google Sign-In.
5. Path B: Phone OTP request and verification.
6. Path C: Email/password (if enabled in environment).
7. Path D: Biometric re-login for a known local secure session.
8. Path E: Guest mode with limited capability.
9. After successful auth, app calls backend sync endpoint to map Firebase user to MySQL customer.
10. Authenticated state routes to main app.
11. If login started from cart gate, page returns to previous flow (`returnAfterAuth` behavior).
12. If phone linking is required, link phone page is shown before final success state.

#### 5.1.4. API Endpoints

| Method | Endpoint | Request | Response |
|--------|----------|---------|----------|
| POST | `/auth/sync` | Firebase ID token in header/body as required | User profile with customer id and role |
| POST | `/auth/request-otp` | Phone number payload | OTP delivery acknowledgement (dev OTP in non-prod) |
| POST | `/auth/verify-otp` | Phone + OTP code | Authenticated user payload |
| POST | `/auth/link-phone` | Phone + OTP + force option | Updated user profile |

#### 5.1.5. State Management

Primary state manager: `AuthBloc`.

Representative events:

- `CheckAuthStatusEvent`
- `GoogleLoginRequested`
- `OtpRequested`
- `OtpLoginSubmitted`
- `BiometricLoginRequested`
- `GuestLoginRequested`
- `LogoutRequested`

Representative states:

- `AuthInitial`
- `AuthLoading`
- `UnauthenticatedState`
- `AuthenticatedState`
- `AuthError`
- `AuthOtpRequired`
- `AuthPhoneLinkRequired`

#### 5.1.6. UI/UX Details

- Animated page transitions improve first impression and perceived smoothness.
- OTP input uses six-digit segmented visual format.
- Timer and resend behavior improve OTP usability.
- Error messages are contextual rather than generic whenever possible.
- Theme toggle availability follows app-level preference handling.
- Text content is localization-ready using keys.
- Guest path is clearly labeled so users understand limitations.
- Form controls and button loading states prevent duplicate submissions.
- Keyboard management and focus behavior are tuned for mobile entry.
- Visual contrast supports dark and light themes.

#### 5.1.7. Acceptance Criteria

- [ ] No direct API call from widget layer.
- [ ] Successful login always produces a backend-synced customer profile for real users.
- [ ] Guest mode never receives privileged customer actions.
- [ ] OTP flow enforces code validation and timeout rules.
- [ ] Biometric path fails gracefully when unavailable.
- [ ] Login interruption from cart can return correctly.
- [ ] All labels and messages are available in vi/en/ja.
- [ ] Role information is preserved for downstream access decisions.

---

### 5.2. Profile / Warranty Screen — Nguyễn Nhất Sinh (Sinh)

#### 5.2.1. Goals

- Provide a single personal center for account actions.
- Show user identity and quick links to order-related pages.
- Expose warranty information through purchase/order details.
- Centralize settings for language and theme.
- Ensure guest users see onboarding prompts instead of private data.

#### 5.2.2. File Structure

```text
lib/features/profile/presentation/pages/profile_page.dart
lib/features/profile/presentation/pages/account_info_page.dart
lib/features/orders/presentation/pages/order_list_page.dart
lib/features/orders/presentation/pages/order_detail_page.dart
lib/features/address/presentation/pages/address_list_page.dart
lib/core/design_system/app_confirm_dialog.dart
```

#### 5.2.3. User Flow

1. User opens Profile tab from the main navigation.
2. App checks auth state and branches guest/real-user UI.
3. Guest users see benefits and login CTA.
4. Authenticated users see account summary card and shortcuts.
5. User can open account info page.
6. User can open address list page.
7. User can open order history and order detail.
8. Warranty period is visible from order detail data.
9. User can open language selection and switch vi/en/ja.
10. User can toggle dark mode.
11. User can request logout and confirm in project-standard dialog.

#### 5.2.4. API and Data Dependencies

Profile page itself is mostly state-driven from auth and existing data.

Related backend interactions include:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/orders?customerId=...` | Retrieve order list |
| GET | `/orders/:id` | Retrieve order detail including warranty date |
| PATCH/PUT | account profile endpoint (if enabled) | Update profile fields |

#### 5.2.5. State Management

- Uses `AuthBloc` as primary source of current user identity.
- Reacts to auth changes through bloc builder/listener pattern.
- Theme and language states come from dedicated cubits.
- Warranty display depends on order domain data in order features.

#### 5.2.6. UI/UX Details

- Guest body explains value of logging in without exposing restricted actions.
- Authenticated body groups actions by intent (orders, account, settings).
- Confirmation dialogs follow app design system conventions.
- Language switch is immediate and visible across app text.
- Warranty concept is phrased clearly to avoid confusion with return policy.
- Icons and color contrast follow global design language.
- Navigation is concise and avoids deep nested steps.

#### 5.2.7. Acceptance Criteria

- [ ] Guest users do not see private customer/order details.
- [ ] Authenticated users can access account and order pages.
- [ ] Warranty information appears in order detail after purchase.
- [ ] Language switch updates profile and other tabs consistently.
- [ ] Logout requires explicit confirmation.
- [ ] UI text is localization-key based.

---

### 5.3. Map (Store Location) + Language + Star Reviews UI — Trần Văn Tuấn Minh (Minh)

This assignment includes three connected responsibilities:

- Store location interface.
- Multilingual behavior.
- Star-based review visual consistency.

---

#### 5.3.1. Map (Store Location) Screen

##### Goals

- Allow users to discover nearby/available physical stores.
- Present store cards with practical details for contact and decision-making.
- Provide clear visual mapping between selected card and map marker.

##### File Structure

```text
lib/features/store_locator/
  domain/entities/store_location_entity.dart
  data/models/store_location_model.dart
  presentation/bloc/store_locator_bloc.dart
  presentation/pages/store_location_page.dart
  presentation/widgets/store_location_card.dart
```

##### User Flow

1. User opens store location screen from profile or checkout context.
2. Bloc loads predefined/mock store list (current implementation).
3. Map area and store card carousel are rendered.
4. User swipes card and sees selected marker highlight update.
5. User taps marker and sees card focus update.
6. User views details: name, address, hours, distance (if available).
7. User taps call/action button for quick contact.

##### API

Current implementation can use local/mock data.

Planned endpoint model:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/stores` | List active stores with coordinates and metadata |

##### State Management

- `LoadStoresEvent` initializes list.
- `SelectStoreEvent` updates current selected index/store.
- State carries list, selected id/index, and loading/error indicators.

##### UI/UX

- Store cards are readable with concise key information.
- Map and card are synchronized for trust and orientation.
- Calls-to-action are reachable with one tap.
- Empty/error state still provides recovery guidance.

##### Acceptance Criteria

- [ ] Map and card selection remain synchronized.
- [ ] Store list is scrollable and stable.
- [ ] User can trigger contact action from store card.
- [ ] Text is localized and theme-compatible.

---

#### 5.3.2. Language (vi / en / ja) System

##### Goals

- Provide consistent multilingual experience across all features.
- Ensure all user-facing text can switch at runtime.
- Keep translation keys maintainable and feature-scoped.

##### File Structure

```text
lib/core/l10n/app_localizations.dart
lib/core/l10n/app_localizations_vi.dart
lib/core/l10n/app_localizations_en.dart
lib/core/l10n/app_localizations_ja.dart
lib/core/theme/language_cubit.dart
lib/main.dart
```

##### User Flow

1. App starts with default locale.
2. Material app listens to `LanguageCubit` state.
3. User opens language selector in profile settings.
4. User chooses `vi`, `en`, or `ja`.
5. Cubit emits new locale and UI rebuilds.
6. Review date/text formatting adapts by locale pattern.

##### API

No remote API is required for local language switching.

##### State Management

- `LanguageCubit` state stores locale code.
- UI reads translated strings through `context.tr('key')`.
- Missing keys are considered defects and must be fixed in all languages.

##### UI/UX

- Labels for language options are human-readable.
- Current language is visibly indicated in selector.
- Transition is immediate with no app restart.
- Right-to-left handling is not required for current languages.

##### Acceptance Criteria

- [ ] Every new localization key exists in vi/en/ja.
- [ ] No hard-coded user-facing text remains in updated features.
- [ ] Date formatting in review UI follows locale conventions.
- [ ] Language change updates all currently visible screens.

---

#### 5.3.3. Star Reviews UI

##### Goals

- Show product quality indicators quickly in list and detail screens.
- Keep rating visualization consistent across reusable widgets.
- Support review date/name/content display with localization sensitivity.

##### File Structure

```text
lib/features/products/domain/entities/product_feedback.dart
lib/features/products/data/models/product_feedback_model.dart
lib/features/products/presentation/widgets/product_review_tile.dart
lib/features/products/presentation/widgets/product_card.dart
lib/features/products/presentation/pages/product_detail_page.dart
```

##### User Flow

1. Product list card shows average star rating.
2. User opens product detail and sees rating summary.
3. User scrolls to review section.
4. Review tiles display avatar, name, stars, date, and text.
5. Empty review state uses localized fallback message.

##### API

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/products/{id}/feedbacks` | Retrieve review list for a product |

##### State Management

- Product detail loads reviews as part of detail data pipeline.
- UI recalculates visible aggregates from fetched values if needed.
- Error and empty states are explicit to avoid silent failures.

##### UI/UX

- Star icon color and fill behavior are standardized.
- Numeric rating and count are presented together for context.
- Review tile layout balances readability and vertical density.
- Date formatting follows current locale.

##### Acceptance Criteria

- [ ] Star rating appears on list and detail pages.
- [ ] Review tile correctly reflects integer/decimal rating values.
- [ ] Empty and loading states are visible and localized.
- [ ] Review section remains visually consistent in dark/light themes.

---

### 5.4. Product List Screen — Lê Mỹ Lộc (Loc)

#### 5.4.1. Goals

- Provide a fast and attractive entry point to product discovery.
- Support search, filter, sorting/pagination-ready list behavior.
- Encourage conversion through clear pricing and rating visibility.
- Maintain smooth scrolling and responsive interactions on mobile devices.

#### 5.4.2. File Structure

```text
lib/features/products/presentation/pages/product_list_page.dart
lib/features/products/presentation/pages/product_search_page.dart
lib/features/products/presentation/widgets/product_card.dart
lib/features/products/presentation/widgets/shimmer_product_card.dart
lib/features/products/presentation/bloc/product_bloc.dart
lib/features/products/domain/repositories/product_repository.dart
lib/features/products/data/repositories/product_repository_impl.dart
lib/features/products/data/datasources/product_remote_datasource.dart
lib/features/products/data/datasources/product_local_datasource.dart
lib/core/network/api_endpoints.dart
```

#### 5.4.3. User Flow

1. User opens Shop tab.
2. Page dispatches initial product load event.
3. Loading skeleton appears.
4. Product grid renders two-column cards.
5. User scrolls; when threshold reached, load-more event triggers.
6. User opens search page and enters keyword.
7. User applies filters (brand, price range, RAM, ROM).
8. Grid updates to filtered result set.
9. User opens cart icon or notifications icon from top area.
10. User taps product card to open detail screen.

#### 5.4.4. API

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/products?search=&brand=&minPrice=&maxPrice=&ram=&rom=&page=&limit=` | Product list with query filters |

#### 5.4.5. State Management

Primary state manager: `ProductBloc`.

Common events:

- `LoadProductsEvent`
- `LoadMoreProductsEvent`
- `SearchProductsEvent`
- `ApplyFilterEvent`
- `RefreshProductsEvent`

Common states:

- `ProductInitial`
- `ProductLoading`
- `ProductLoaded`
- `ProductLoadingMore`
- `ProductEmpty`
- `ProductError`

#### 5.4.6. UI/UX

- Product card includes thumbnail, badge, title, brand, price, and star rating.
- Discount display keeps original and discounted prices visually distinct.
- New badge is minimal but visible.
- Search entry point is clearly placed for quick use.
- Filter controls are simple and mobile-friendly.
- Infinite loading indicator appears only when needed.
- Retry option appears for recoverable failures.
- Empty state includes actionable hint text.
- Cart and notification shortcuts remain visible.

#### 5.4.7. Acceptance Criteria

- [ ] Two-column grid remains stable on all standard mobile widths.
- [ ] Pagination does not trigger duplicate API calls during active loading.
- [ ] Filters combine correctly (brand + price + memory).
- [ ] Search keyword updates are reflected in API query.
- [ ] Product cards render rating, price, and image correctly.
- [ ] Offline cache can supply fallback list when API fails.
- [ ] All text labels use localization keys.

---

### 5.5. Product Detail Screen — Lê Mỹ Lộc (Loc)

#### 5.5.1. Goals

- Present complete product information for purchase decisions.
- Support variant selection before cart actions.
- Show review quality and specifications in one continuous screen.
- Enable direct conversion via add-to-cart and buy-now actions.

#### 5.5.2. File Structure

```text
lib/features/products/presentation/pages/product_detail_page.dart
lib/features/products/presentation/widgets/product_color_option_tile.dart
lib/features/products/presentation/widgets/product_review_tile.dart
lib/features/products/domain/entities/product_entity.dart
lib/features/products/domain/entities/product_version.dart
lib/features/products/domain/entities/product_feedback.dart
lib/features/products/presentation/bloc/product_bloc.dart
lib/features/cart/presentation/bloc/cart_bloc.dart
```

#### 5.5.3. User Flow

1. User opens detail screen from product card.
2. Screen receives product id and optional hero image context.
3. Detail load event fetches product info and feedback list.
4. Hero image and carousel are shown.
5. User selects variant color.
6. User selects RAM/ROM option.
7. Price and stock update according to selected variant.
8. User scrolls to description and specifications section.
9. User scrolls to review summary and tiles.
10. User taps Add to Cart or Buy Now.
11. If user is not real-authenticated, auth gate triggers.
12. Buy-now path continues to checkout with selected variant.

#### 5.5.4. API

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/products/{id}` | Product detail and variant data |
| GET | `/products/{id}/feedbacks` | Product review details |

#### 5.5.5. State Management

Detail behavior can be managed by product-related bloc state:

- `LoadProductByIdEvent`
- `SelectProductColorEvent`
- `SelectProductRamRomEvent`
- `ProductDetailLoaded`
- `ProductDetailError`

Cross-feature interaction:

- Add-to-cart action dispatches events to `CartBloc`.
- Buy-now action can enqueue cart item then open checkout context.

#### 5.5.6. UI/UX

- Hero transition reinforces continuity from list to detail.
- Variant selectors provide clear selected state visuals.
- Stock-out variants are visibly disabled.
- Specification layout favors readability over visual clutter.
- Review summary uses stars + count for quick trust estimation.
- Bottom action bar is persistent and thumb-reachable.
- Loading skeleton avoids abrupt content shifts.
- Error state provides retry action.

#### 5.5.7. Acceptance Criteria

- [ ] Product detail fetch succeeds and binds correct product id.
- [ ] User cannot add invalid or unavailable variant.
- [ ] Stock-out variants are not purchasable.
- [ ] Review section handles empty and populated states.
- [ ] Add-to-cart updates cart state and feedback message.
- [ ] Buy-now opens checkout with selected product context.
- [ ] All product detail labels are localized.

---

### 5.6. Shopping Cart Screen — Nguyễn Minh Hiếu (Hieu)

#### 5.6.1. Goals

- Provide reliable MySQL-synced cart management.
- Keep quantity, stock, and price calculations consistent.
- Let users select subset of items for checkout.
- Support promo logic and accurate summary display.

#### 5.6.2. File Structure

```text
lib/features/cart/presentation/pages/cart_page.dart
lib/features/cart/presentation/widgets/cart_item_tile.dart
lib/features/cart/presentation/widgets/cart_summary.dart
lib/features/cart/presentation/bloc/cart_bloc.dart
lib/features/cart/presentation/cart_auth_helper.dart
lib/features/cart/domain/entities/cart_item_entity.dart
lib/features/cart/domain/repositories/cart_repository.dart
lib/features/cart/data/repositories/cart_repository_impl.dart
lib/features/cart/data/datasources/cart_remote_datasource.dart
```

#### 5.6.3. User Flow

1. User opens cart tab or cart shortcut.
2. App checks if user is real-authenticated for server cart access.
3. Guest users are prompted to log in.
4. Authenticated users trigger cart sync by `customerId`.
5. Cart list appears with image, title, variant, quantity controls, and selection checkbox.
6. User increases/decreases quantity.
7. Quantity update validates against available stock.
8. User removes an item or clears all.
9. User applies promo code.
10. Summary updates subtotal, discount, shipping estimate, and final total preview.
11. User proceeds to checkout with selected items only.

#### 5.6.4. API

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/cart?customerId=` | Retrieve enriched cart |
| POST | `/api/cart/items` | Add item by product version |
| PUT | `/api/cart/items/:productVersionId` | Update quantity |
| DELETE | `/api/cart/items/:productVersionId` | Remove item |
| DELETE | `/api/cart?customerId=` | Clear cart |

#### 5.6.5. State Management

Main bloc: `CartBloc`.

Key events:

- `SyncCartCustomerEvent`
- `AddToCartEvent`
- `UpdateQuantityEvent`
- `ToggleCartItemSelectionEvent`
- `ApplyPromoCodeEvent`
- `RemoveCartItemEvent`
- `ClearCartEvent`

Key state fields:

- `items`
- `selectedVersionIds`
- `subtotal`
- `discountAmount`
- `total`
- `isLoading`
- `isUpdating`
- `error`

#### 5.6.6. UI/UX

- Selection checkbox is explicit for checkout scope control.
- Quantity controls are easy to tap and visually balanced.
- Price updates are immediate after quantity/promo changes.
- Empty state includes CTA to explore products.
- Promo input gives clear success/failure message.
- Cart summary remains anchored and readable.
- Guest restrictions are explained before forcing navigation.
- Cart list supports long-product names without layout breakage.

#### 5.6.7. Acceptance Criteria

- [ ] Cart sync always uses backend API and customer id.
- [ ] No SQLite cart fallback is used.
- [ ] Quantity never exceeds available stock.
- [ ] Negative or zero quantity is not accepted.
- [ ] Selected items determine checkout payload.
- [ ] Promo code calculation is reproducible and accurate.
- [ ] Empty state appears when no items remain.
- [ ] Localization is complete for all user-facing cart strings.

---

### 5.7. Checkout / Billing Screen — Nguyễn Minh Hiếu (Hieu)

#### 5.7.1. Goals

- Convert selected cart items into valid orders.
- Collect delivery information with validation.
- Support pickup and shipping paths.
- Offer multiple payment options including PayOS QR.
- Ensure post-order cleanup and user feedback.

#### 5.7.2. File Structure

```text
lib/features/checkout/presentation/pages/checkout_page.dart
lib/features/checkout/presentation/pages/payos_qr_payment_page.dart
lib/features/checkout/presentation/widgets/checkout_info_tab.dart
lib/features/checkout/presentation/widgets/checkout_payment_tab.dart
lib/features/checkout/presentation/widgets/checkout_bottom_bar.dart
lib/features/checkout/presentation/bloc/checkout_bloc.dart
lib/features/checkout/domain/entities/checkout_order_entity.dart
lib/features/checkout/domain/repositories/checkout_repository.dart
lib/features/checkout/data/repositories/checkout_repository_impl.dart
lib/features/checkout/data/datasources/checkout_remote_datasource.dart
lib/features/checkout/data/datasources/payment_remote_datasource.dart
```

#### 5.7.3. User Flow

1. User opens checkout from cart with selected items.
2. Initial event pre-fills customer data from auth context.
3. User validates recipient name, phone, and contact details.
4. User chooses delivery method: pickup or shipping.
5. If shipping is chosen, user inputs address hierarchy and detail.
6. User sets optional order note and invoice preferences.
7. User switches to payment tab.
8. User selects COD, transfer, or PayOS QR.
9. User reviews summary values.
10. User submits order.
11. App calls order API and handles loading state.
12. If PayOS selected, app opens QR page and polls payment status.
13. On success, cart selection is cleared and user receives success feedback.
14. Optional notification event is generated for order status.

#### 5.7.4. API

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/orders` | Create order and commit inventory/order lines |
| GET | `/api/payments/payos/status/:orderId` | Poll payment status |

#### 5.7.5. State Management

Main bloc: `CheckoutBloc`.

Representative events:

- `InitializeCheckoutEvent`
- `SetCheckoutStepEvent`
- `SetDeliveryMethodEvent`
- `UpdateShippingAddressEvent`
- `UpdatePaymentMethodEvent`
- `SubmitOrderEvent`
- `CompletePayOsPaymentEvent`

Representative state fields:

- `step`
- `deliveryMethod`
- `paymentMethod`
- `shippingAddress`
- `selectedItems`
- `subtotal`
- `discount`
- `shippingCost`
- `total`
- `isProcessing`
- `submitError`
- `submitSuccess`

#### 5.7.6. UI/UX

- Two-step layout makes complex forms easier to complete.
- Validation messages are immediate and specific.
- Total summary is always visible at the bottom.
- Payment option cards are clear and tappable.
- PayOS QR page communicates timeout/poll status clearly.
- Success dialog confirms order completion and next actions.
- Failure states include retry and back navigation options.
- Theme and localization support remain consistent.

#### 5.7.7. Acceptance Criteria

- [ ] Checkout cannot submit with empty selected cart list.
- [ ] Required shipping fields are validated before submission.
- [ ] Total formula is accurate: `subtotal - discount + shipping`.
- [ ] Loading state prevents duplicate submit taps.
- [ ] PayOS polling updates transaction state correctly.
- [ ] Successful checkout clears selected cart lines.
- [ ] Error states use user-friendly localized messages.

---

### 5.8. Notifications Screen — Dương Trí Toàn (Toan)

#### 5.8.1. Goals

- Keep users aware of product updates, order progress, and chat messages.
- Provide centralized in-app notification history.
- Support read/unread state and quick navigation to relevant screens.
- Bridge push events with in-app list management.

#### 5.8.2. File Structure

```text
lib/features/notifications/presentation/pages/notifications_page.dart
lib/features/notifications/presentation/bloc/notification_bloc.dart
lib/features/notifications/presentation/notification_helpers.dart
lib/features/notifications/presentation/widgets/notification_badge_icon.dart
lib/features/notifications/data/datasources/notification_remote_datasource.dart
lib/features/notifications/data/repositories/notification_repository_impl.dart
lib/core/notifications/push_notification_service.dart
backend/src/routes/notifications.js
```

#### 5.8.3. User Flow

1. User taps notification icon from product list or app bar.
2. If not logged in, app shows login CTA.
3. If logged in, page loads user notifications by `customerId`.
4. Notifications are grouped (product updates, order/chat related).
5. User taps one notification.
6. Item is marked as read.
7. App navigates using payload:
8. Product notification -> product detail.
9. Order notification -> order detail.
10. Chat notification -> chat tab/thread.
11. User can swipe to delete individual items.
12. User can mark all as read from menu action.

#### 5.8.4. API

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/notifications?customerId=` | Get list + unread count |
| PATCH | `/notifications/:id/read` | Mark one as read |
| POST | `/notifications/read-all` | Mark all as read |
| DELETE | `/notifications/:id` | Remove one notification |
| POST | `/notifications/register-token` | Register FCM token |

#### 5.8.5. State Management

Main bloc: `NotificationBloc`.

Typical events:

- `LoadNotificationsEvent`
- `MarkNotificationReadEvent`
- `MarkAllNotificationsReadEvent`
- `DeleteNotificationEvent`
- `RegisterNotificationTokenEvent`
- `ClearNotificationsEvent`

Typical state fields:

- `items`
- `unreadCount`
- `isLoading`
- `isMutating`
- `error`

#### 5.8.6. UI/UX

- Unread badge communicates urgency without overwhelming UI.
- Notification tile design prioritizes type icon + concise text + time.
- Swipe-to-delete interaction keeps list manageable.
- Type-based tabs/filters reduce cognitive load.
- Empty state clarifies that no notifications are pending.
- Deep-link transitions preserve context.
- Localization ensures category labels remain clear in all languages.

#### 5.8.7. Acceptance Criteria

- [ ] Unread badge count matches backend value.
- [ ] Tapping an item marks it as read and navigates correctly.
- [ ] Mark-all action updates UI and backend state.
- [ ] Swipe delete removes item consistently.
- [ ] Token registration runs after login and refresh cycles.
- [ ] Guest mode does not attempt private notification fetch.
- [ ] Notification labels and messages are localized.

---

### 5.9. Messaging / Chat Screen — Dương Trí Toàn (Toan)

#### 5.9.1. Goals

- Provide real-time customer support channel in-app.
- Separate AI assistance and human-staff channels.
- Maintain stable Socket.IO connectivity across local and production.
- Connect chat actions with notification ecosystem.

#### 5.9.2. File Structure

```text
lib/features/chat/presentation/pages/chat_hub_page.dart
lib/features/chat/presentation/pages/chat_conversation_page.dart
lib/features/chat/presentation/pages/admin_inbox_page.dart
lib/features/chat/presentation/bloc/chat_bloc.dart
lib/features/chat/domain/entities/chat_message_entity.dart
lib/features/chat/domain/entities/chat_thread_entity.dart
lib/features/chat/data/datasources/chat_remote_datasource.dart
lib/features/chat/data/repositories/chat_repository_impl.dart
lib/features/chatbot/presentation/pages/chatbot_page.dart
backend/chat.js
backend/src/routes/chat
```

#### 5.9.3. User Flow

1. User opens support tab (`ChatHubPage`).
2. User sees two support channels:
3. Channel A: bot assistant.
4. Channel B: staff chat.
5. Bot channel works for quick FAQ-like interactions.
6. Staff channel requires real authenticated user.
7. User starts/opens thread.
8. App initializes thread list and socket connection.
9. User sends message.
10. Server broadcasts message through thread room.
11. User receives real-time replies.
12. Admin can join from inbox and reply in same thread.
13. Notifications can be generated for new incoming messages.

#### 5.9.4. REST API

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/chat/threads/mine?userId=` | User thread bootstrap |
| GET | `/chat/threads?role=admin` | Admin inbox listing |
| GET | `/chat/threads/:id/messages` | Message history |

#### 5.9.5. Socket.IO Contract

| Environment | Origin | Path |
|------------|--------|------|
| Local | `http://127.0.0.1:3000` | `/socket.io` |
| Production | `https://maclenin.io.vn` | `/mobile/socket.io` |

| Event | Direction | Payload |
|-------|-----------|---------|
| `send_message` | Client -> Server | `{ threadId, text }` |
| `new_message` | Server -> Client | Message entity |
| `join_thread` | Admin -> Server | Thread room info |
| `threads_updated` | Server -> Admin | Updated thread list |

#### 5.9.6. State Management

Main bloc: `ChatBloc`.

Representative events:

- `InitChatEvent`
- `OpenThreadEvent`
- `SendMessageEvent`
- `ReceiveSocketMessageEvent`
- `LoadThreadMessagesEvent`
- `ReconnectSocketEvent`
- `DisconnectChatEvent`

Representative state fields:

- `threads`
- `activeThread`
- `messages`
- `isLoading`
- `isSending`
- `isConnected`
- `error`

#### 5.9.7. UI/UX

- Chat hub simplifies entry with clear two-tab mental model.
- Message bubbles clearly distinguish sender roles.
- Sending state is visible and prevents accidental repeats.
- Connection errors include practical retry hints.
- Admin inbox supports quick thread switching.
- Chat text is readable in both theme modes.
- Keyboard and input area behavior is mobile-first.

#### 5.9.8. Acceptance Criteria

- [ ] Guest users cannot access privileged staff channel.
- [ ] Real-time two-way chat works between user and admin clients.
- [ ] Chat reconnect logic handles temporary disconnects.
- [ ] Socket path configuration works in production route.
- [ ] New staff replies can trigger notification items.
- [ ] Message rendering remains stable for long conversation history.
- [ ] All user-facing text is localized.

---

## 6. Conclusion and Discussion

### 6.1. Pros

- The project uses a maintainable feature-first architecture with clear layering.
- BLoC + get_it keeps state management predictable and scalable.
- Backend-driven MySQL cart/order handling aligns with e-commerce integrity needs.
- SQLite cache improves resilience for product browsing when connectivity is unstable.
- Multi-auth strategy (Google, OTP, biometric) improves accessibility and convenience.
- Real-time chat and notifications enhance customer engagement.
- PayOS integration adds practical real-world payment behavior.

### 6.2. Cons

- Store map UI may still rely on mock presentation in some flows instead of full live-map integration.
- Warranty information is primarily surfaced through order detail and may need a fully dedicated screen.
- Some feature areas require more automated test coverage for regression prevention.
- Production chat reliability depends on strict proxy configuration discipline.

### 6.3. Learning Outcomes

- Coordinating Firebase identity with backend customer records is critical in commerce apps.
- Keeping cart and order truth in MySQL avoids offline conflict complexity.
- Splitting remote/local data sources simplifies fallback behavior and debugging.
- Socket transport through reverse proxy requires careful operational settings.
- Localization discipline from the start prevents expensive refactor later.

### 6.4. Future Improvements

- Full Google Maps live coordinates and nearest-store routing support.
- Dedicated warranty lookup by IMEI/serial and QR scan.
- Expanded review workflow with verified-purchase posting from app.
- Better recommendation and personalization layer.
- Admin dashboard for inventory, order status, and support analytics.
- More integration tests for checkout, chat, and notification deep links.

---

## 7. Contribution Table

### 7.1. Section-Level Shared Work

| Topic | Effort | Lê Mỹ Lộc | Nguyễn Minh Hiếu | Nguyễn Nhất Sinh | Dương Trí Toàn | Trần Văn Tuấn Minh |
|-------|--------|-----------|------------------|------------------|----------------|---------------------|
| Case Study Analysis | 100% | 20% | 20% | 20% | 20% | 20% |
| Business Analysis | 100% | 20% | 20% | 20% | 20% | 20% |
| System Design | 100% | 20% | 20% | 20% | 20% | 20% |
| Testing & Deployment Validation | 100% | 20% | 20% | 20% | 20% | 20% |
| Documentation Finalization | 100% | 20% | 20% | 20% | 20% | 20% |

### 7.2. Screen Ownership (Exact 100% Assignment per Screen)

| Screen / Feature | Effort | Lê Mỹ Lộc (Loc) | Nguyễn Minh Hiếu (Hieu) | Nguyễn Nhất Sinh (Sinh) | Dương Trí Toàn (Toan) | Trần Văn Tuấn Minh (Minh) |
|------------------|--------|-----------------|---------------------------|--------------------------|------------------------|----------------------------|
| Login screen | 100% | — | — | **100%** | — | — |
| Profile / Warranty screen | 100% | — | — | **100%** | — | — |
| Map + Language + Star reviews UI | 100% | — | — | — | — | **100%** |
| Product List screen | 100% | **100%** | — | — | — | — |
| Product Detail screen | 100% | **100%** | — | — | — | — |
| Shopping Cart screen | 100% | — | **100%** | — | — | — |
| Checkout/Billing screen | 100% | — | **100%** | — | — | — |
| Notifications screen | 100% | — | — | — | **100%** | — |
| Messaging/Chat screen | 100% | — | — | — | **100%** | — |

### 7.3. Team Assignment Statement

- The above matrix is the official and correct assignment map for this submission.
- Each listed screen is fully owned (`100%`) by the assigned member.
- Shared sections remain equally distributed among all five members.

---

## 8. References

### 8.1. External Technical References

| Source | URL |
|--------|-----|
| Flutter Documentation | [https://docs.flutter.dev/](https://docs.flutter.dev/) |
| flutter_bloc package | [https://pub.dev/packages/flutter_bloc](https://pub.dev/packages/flutter_bloc) |
| get_it package | [https://pub.dev/packages/get_it](https://pub.dev/packages/get_it) |
| sqflite package | [https://pub.dev/packages/sqflite](https://pub.dev/packages/sqflite) |
| Firebase Authentication docs | [https://firebase.google.com/docs/auth](https://firebase.google.com/docs/auth) |
| Google Sign-In docs | [https://developers.google.com/identity/sign-in](https://developers.google.com/identity/sign-in) |
| Firebase Cloud Messaging docs | [https://firebase.google.com/docs/cloud-messaging](https://firebase.google.com/docs/cloud-messaging) |
| Socket.IO docs | [https://socket.io/docs/v4/](https://socket.io/docs/v4/) |
| socket_io_client Dart package | [https://pub.dev/packages/socket_io_client](https://pub.dev/packages/socket_io_client) |
| local_auth package | [https://pub.dev/packages/local_auth](https://pub.dev/packages/local_auth) |
| PayOS docs | [https://pay.payos.vn/web4c/docs/](https://pay.payos.vn/web4c/docs/) |
| google_maps_flutter package | [https://pub.dev/packages/google_maps_flutter](https://pub.dev/packages/google_maps_flutter) |

### 8.2. Internal Project References

| Document / File | Path |
|-----------------|------|
| Architecture guideline | `docs/ARCHITECTURE.md` |
| Coding conventions | `docs/CONVENTIONS.md` |
| API contract | `docs/API.md` |
| Database notes | `docs/DATABASE.md` |
| Feature specifications | `docs/features/*/SPEC.md` |
| Chat feature spec | `docs/features/chat/SPEC.md` |
| Agent team playbook | `AGENTS.md` |
| Main app bootstrap and DI | `lib/main.dart` |
| Login screen | `lib/features/auth/presentation/pages/login_page.dart` |
| Profile screen | `lib/features/profile/presentation/pages/profile_page.dart` |
| Store location screen | `lib/features/store_locator/presentation/pages/store_location_page.dart` |
| Product list screen | `lib/features/products/presentation/pages/product_list_page.dart` |
| Product detail screen | `lib/features/products/presentation/pages/product_detail_page.dart` |
| Cart screen | `lib/features/cart/presentation/pages/cart_page.dart` |
| Checkout screen | `lib/features/checkout/presentation/pages/checkout_page.dart` |
| Notifications screen | `lib/features/notifications/presentation/pages/notifications_page.dart` |
| Chat hub screen | `lib/features/chat/presentation/pages/chat_hub_page.dart` |
| Nginx socket deployment config | `backend/deploy/nginx-maclenin.docker.conf` |
| Chat remote datasource | `lib/features/chat/data/datasources/chat_remote_datasource.dart` |

---

### Final Note

This English technical report is prepared for `sumaatophon` based on the section 1–8 structure of `docPrmTemp.md`, with corrected team ownership assignments and implementation-aligned technical content.
