# PFC App — Flutter

The mobile app for Palnadu Fried Chicken. Same backend, same APIs and the same
dark-and-red look as `pfc.maheshp.in`.

---

## 1. What talks to what

```
Flutter app
    |
    |  HTTPS + JWT  (dio)
    v
https://api.maheshp.in/api/      <- nginx
    |
    v
127.0.0.1:8003                   <- gunicorn (pfc.service)
    |
    v
Django + DRF  ->  MySQL
```

Login is the only thing that goes somewhere else first:

```
Phone number -> Firebase  -> SMS with 6-digit code
Code         -> Firebase  -> gives an id_token
id_token     -> Django /api/auth/firebase/  -> gives our JWT pair
```

**Django never sends the SMS.** If no code arrives, the problem is always in
the Firebase console, never on the Oracle server.

---

## 2. Run it — step by step

### Step 1 — Create the platform folders

The `lib/` code is complete, but the `android/` and `ios/` folders are not in
this zip (they are machine-specific). Generate them:

```bash
cd pfc_app
flutter create .
```

This adds `android/`, `ios/`, `web/` without touching `lib/` or `pubspec.yaml`.

### Step 2 — Install the packages

```bash
flutter pub get
```

### Step 3 — Connect Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pick the **same Firebase project** your website uses. This writes
`android/app/google-services.json` and `lib/firebase_options.dart`.

If `flutterfire` does not work, do it by hand:
1. Firebase console → Project settings → Add app → Android
2. Package name: `com.pfc.app` (or whatever `flutter create` used)
3. Download `google-services.json` → put it in `android/app/`

### Step 4 — Add the SHA-1 fingerprint (this is the one people forget)

Phone auth will **not** send real SMS without it.

```bash
cd android
./gradlew signingReport
```

Copy the **SHA1** and **SHA256** from the `debug` variant, then:
Firebase console → Project settings → Your Android app → **Add fingerprint**

### Step 5 — Allow internet access

Open `android/app/src/main/AndroidManifest.xml` and add this line **above**
the `<application>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Step 6 — Run

```bash
flutter run
```

---

## 3. Pointing at a different server

One line, in `lib/core/constants.dart`:

```dart
static const String baseUrl = 'https://api.maheshp.in';
```

For testing against a local Django on the same Wi-Fi, use your laptop's LAN IP
(not `localhost` — that means the phone itself):

```dart
static const String baseUrl = 'http://192.168.1.5:8003';
```

For plain `http` you also need, in `AndroidManifest.xml` inside `<application>`:

```xml
android:usesCleartextTraffic="true"
```

---

## 4. Folder map

```
lib/
├── main.dart                  app start, Firebase init, token load
├── core/
│   ├── constants.dart         baseUrl + EVERY endpoint path
│   └── theme.dart             colours, fonts, button styles
├── data/
│   ├── models/                one Dart class per DRF serializer
│   │   ├── parse.dart         safe JSON helpers (Django sends money as String)
│   │   ├── shop.dart          ShopSetting + Banner
│   │   ├── catalog.dart       Category, Product, Variant, HomeData
│   │   ├── cart.dart          Cart + CartItem + bill totals
│   │   ├── address.dart
│   │   ├── order.dart         Order + OrderItem + status flow
│   │   └── user.dart          AppUser + AuthResult
│   ├── services/
│   │   ├── token_store.dart   JWTs in the OS keychain
│   │   ├── api_client.dart    dio + auto token refresh + error messages
│   │   └── auth_service.dart  the Firebase -> Django login flow
│   └── repositories/          one file per backend resource
├── providers/                 Riverpod state (auth, home, cart, orders…)
├── screens/                   one file per screen
└── widgets/                   shared UI pieces
```

---

## 5. Endpoints the app calls

| Screen | Method | Path |
|---|---|---|
| Splash / Home | GET | `/api/home/` |
| Login | POST | `/api/auth/firebase/` |
| any (expired token) | POST | `/api/auth/refresh/` |
| Profile | GET / PATCH | `/api/auth/me/` |
| Menu search | GET | `/api/products/?search=&category=` |
| Cart | GET | `/api/cart/` |
| Add to cart | POST | `/api/cart/add/` |
| Change quantity | POST | `/api/cart/update/` |
| Remove line | POST | `/api/cart/remove/` |
| Empty cart | POST | `/api/cart/clear/` |
| Coupon | POST | `/api/coupons/apply/` |
| Addresses | GET / POST | `/api/addresses/` |
| One address | PATCH / DELETE | `/api/addresses/<id>/` |
| Place order | POST | `/api/checkout/place-order/` |
| Order list | GET | `/api/orders/` |
| One order | GET | `/api/orders/<id>/` |
| Cancel | POST | `/api/orders/<id>/cancel/` |

If a path on your server is different, change it in `lib/core/constants.dart`
only — nothing else needs touching.

---

## 6. Things the app does on purpose

**The server owns all the maths.** Every cart change sends a request and the
server returns the whole cart back, including delivery fee, GST and discount.
Nothing is calculated on the phone, so the app and the website can never show
different totals.

**Error messages come from Django.** When `/checkout/place-order/` answers 400
with `{"detail": "Cart is empty"}`, that exact sentence is what the user sees.
No guessing.

**Expired tokens fix themselves.** On any 401 the app calls `/auth/refresh/`
once and replays the original request. The user never notices.

**Missing product photos look deliberate.** Your products have `image: null`
right now, so each card falls back to a category emoji on a soft gradient
instead of a broken-image box. Upload photos in Django admin and they appear
with no app change.

---

## 7. When something breaks

| What you see | What it means | Fix |
|---|---|---|
| No OTP arrives | Firebase, not Django | Add SHA-1; remove test numbers; check Authorized domains |
| `No internet connection` | Phone can't reach the server | Check `baseUrl`; is `pfc.service` running? |
| Every call gives 401 | Token rejected | Log out and back in |
| `400` on place order | Server refused the order | The toast shows Django's own reason |
| Blank home screen | `/api/home/` failed | `curl https://api.maheshp.in/api/home/` on the server |

Handy server commands:

```bash
sudo systemctl status pfc       # is the backend up?
sudo systemctl restart pfc      # restart it
sudo journalctl -u pfc -n 50    # last 50 log lines
```

---

## 8. Building the release APK

```bash
flutter build apk --release
```

The file lands at `build/app/outputs/flutter-apk/app-release.apk`.

Before you publish, add the **release** SHA-1 to Firebase too — the debug one
only covers testing builds.
"# PFC" 
