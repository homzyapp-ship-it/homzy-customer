# Homzy Customer App — Production Setup & Release Guide

| Item | Value |
|---|---|
| App name | Homzy |
| Android package / iOS bundle ID | `com.homzy.customer` |
| Backend API | `https://api.homzyapp.in/api/` (`lib/config/constant.dart`) |
| Firebase project | `homzy-31dbf` |
| App version | `1.0.0+1` (`pubspec.yaml`) |
| Toolchain verified | Flutter 3.47.5 / Dart 3.13.4, JDK 21, Android SDK 36/37, AGP 8.12.3, Gradle 8.14 |
| minSdk / targetSdk / compileSdk | 24 / 36 / 37 |

---

## 1. Launch checklist (status)

| # | Item | Status | Where |
|---|---|---|---|
| 1 | Firebase Android options filled from `google-services.json` | ✅ Done | `lib/firebase_options.dart` |
| 2 | HTTP Inspector disabled in release builds | ✅ Done | `lib/main.dart` |
| 3 | `.gitignore` added (keystore, `key.properties`, `local.properties`, `env/*.json`) | ✅ Done | `.gitignore` |
| 4 | Release upload keystore generated + `key.properties` | ✅ Done — **back it up!** (§3) | `android/app/upload-keystore.jks` |
| 5 | Google Maps API key | ⚠️ **You must add** | `android/local.properties` → `MAPS_API_KEY` |
| 6 | Google Places API key | ⚠️ **You must add** | `env/prod.json` → `PLACES_API_KEY` |
| 7 | Release SHA‑1/SHA‑256 added to Firebase (Google Sign‑In, Phone Auth) | ⚠️ **You must add** | Firebase console (§4) |
| 8 | Backend settings: payment gateway **live** keys | ⚠️ Verify | Admin panel (§6) |
| 9 | iOS: `GoogleService-Info.plist`, Google Client IDs | ⚠️ Needed only for iOS | §8 |
| 10 | Play Console listing, privacy policy, Data Safety form | ⚠️ To do | §9 |

---

## 2. One-time machine setup

```bash
flutter doctor --android-licenses   # accept all (doctor flagged this)
flutter doctor                      # Android toolchain must be ✓
```

---

## 3. Release signing (keystore)

A new **upload keystore** was generated:

- File: `android/app/upload-keystore.jks` (alias `upload`, RSA 2048, valid ~27 years)
- Passwords: in `android/key.properties`
- Fingerprints:
  - SHA‑1: `43:28:75:C2:38:76:88:28:11:84:A5:E4:18:A9:E5:4F:C7:7E:BD:43`
  - SHA‑256: `2D:94:61:7C:F9:5C:B0:B3:03:58:F3:51:C1:EB:7D:70:8D:18:62:DF:C1:33:AF:97:66:F9:AA:A0:F8:98:67:F2`

> **CRITICAL:** Copy `upload-keystore.jks` **and** `key.properties` to a password manager / secure offline storage now. Both are git-ignored. Without them you cannot publish updates (unless you use Play App Signing and request an upload-key reset, which takes days).

`android/key.properties` format (paths are relative to `android/app/`):

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=upload-keystore.jks
```

When you upload the first AAB, **enroll in Play App Signing** (default). Google then holds the real app-signing key; this file is only the upload key.

View fingerprints any time:

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

---

## 4. Firebase

Already configured for Android (`android/app/google-services.json`, project `homzy-31dbf`).

**Required before launch** — Firebase console → Project settings → Android app `com.homzy.customer` → *Add fingerprint*:

1. Upload key SHA‑1 + SHA‑256 (§3) — for sideloaded/test APKs.
2. **Play App Signing key** SHA‑1 + SHA‑256 — from Play Console → *Test and release → App integrity* after the first upload. **Without this, Google Sign‑In and Phone OTP fail for Play Store installs.**

Then download the updated `google-services.json` and replace `android/app/google-services.json`.

Also verify in Firebase:
- Authentication → Sign-in methods enabled (Phone, Google, Apple as used).
- Cloud Messaging → backend has the server credentials (service account) for push.
- Phone auth: Play Integrity API enabled in the Google Cloud project.

If you ever change Firebase project, regenerate options with:
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<project-id> --platforms=android,ios
```

---

## 5. API keys (Google Maps & Places)

Create keys in Google Cloud Console (project `homzy-31dbf` recommended). Enable: **Maps SDK for Android**, **Places API (New)**, **Geocoding API**.

### Maps key (Android map widget)
Add to `android/local.properties` (git-ignored):
```properties
MAPS_API_KEY=AIza....
```
Restrict it: *Android apps* → package `com.homzy.customer` + SHA‑1 of upload key **and** Play App Signing key.

### Places key (address search, called over HTTP from Dart)
Edit `env/prod.json` (git-ignored; template in `env/example.json`):
```json
{ "PLACES_API_KEY": "AIza...." }
```
Restrict it by **API** (Places API, Geocoding API only) and set quotas/budget alerts — this key ships inside the app.

> If a key is missing the app still builds, but the map shows blank and location search fails.

---

## 6. Backend / admin panel checks

The app reads payment gateway keys and app settings from the backend settings API at runtime (`lib/model/settings_model/settings_model.dart`) — nothing is hard-coded. Before launch confirm in the admin panel:

- Payment gateways switched from **test → live** keys (Razorpay, Stripe, Paystack, etc.); disable gateways you don't use.
- Server URL is production: `https://api.homzyapp.in/api/` (change `AppConstant.baseUrl` if not).
- Support contacts, privacy policy & terms URLs, delivery zones, currency, and minimum-order settings are correct.
- Firebase server key / service account configured for push notifications.

---

## 7. Building

```bash
flutter clean
flutter pub get

# APK (direct install / testing)
flutter build apk --release --dart-define-from-file=env/prod.json
# -> build/app/outputs/flutter-apk/app-release.apk

# Smaller per-ABI APKs
flutter build apk --release --split-per-abi --dart-define-from-file=env/prod.json

# AAB (required for Google Play)
flutter build appbundle --release --dart-define-from-file=env/prod.json
# -> build/app/outputs/bundle/release/app-release.aab
```

**Always pass `--dart-define-from-file=env/prod.json`**, otherwise the Places key is empty.

Install on a device: `adb install -r build/app/outputs/flutter-apk/app-release.apk`

### Versioning
Bump `version:` in `pubspec.yaml` for every Play upload — `1.0.0+1` → `1.0.1+2`. The number after `+` (versionCode) must always increase.

### Smoke test the release APK
- [ ] App opens, splash → home, no crash
- [ ] Phone OTP login + Google Sign‑In
- [ ] Location permission, map renders, address search works
- [ ] Browse stores/products, add to cart, apply promo
- [ ] Checkout with each enabled gateway (small real amount) + COD + wallet
- [ ] Push notification received (foreground & background)
- [ ] Order tracking, ratings, deep link `homzy://products/<slug>` (and legacy `hyperlocal://`)
- [ ] Language switch & dark mode

---

## 8. iOS (when needed)

Bundle ID is already `com.homzy.customer`. Still required:
1. Firebase console → add iOS app `com.homzy.customer` → download `GoogleService-Info.plist` into `ios/Runner/` (add via Xcode).
2. Run `flutterfire configure` (fills the `ios` block of `lib/firebase_options.dart`, currently placeholders).
3. `ios/Runner/Info.plist`: replace `Your_Google_Client_ID` (×2) with the iOS client ID, and `com.googleusercontent.apps.Encoded_app_id` with its `REVERSED_CLIENT_ID`.
4. Xcode → Signing & Capabilities: team, Push Notifications, Background Modes (remote notifications), Sign in with Apple.
5. Upload APNs auth key (.p8) to Firebase → Cloud Messaging.
6. `flutter build ipa --release --dart-define-from-file=env/prod.json`

---

## 9. Google Play launch steps

1. Create the app in Play Console (`com.homzy.customer`).
2. Store listing: name, short/full description, 512×512 icon, 1024×500 feature graphic, ≥2 phone screenshots.
3. **Privacy policy URL** (mandatory — app uses location, microphone, camera/photos, contacts by phone).
4. **Data safety** form: location, phone number, name/email, purchase history, device IDs (FCM), photos (attachments), audio (voice search).
5. Content rating questionnaire, target audience, ads declaration (no ads; `AD_ID` permission is removed in the manifest).
6. Permissions declarations: `CALL_PHONE`, `RECORD_AUDIO`, foreground service — justify each or remove unused ones in `AndroidManifest.xml`.
7. Upload `app-release.aab` to **Internal testing** → test → Closed testing (new personal accounts need 12 testers × 14 days) → Production.
8. After first upload: copy App Signing SHA‑1/256 into Firebase and the Maps key restriction (§4, §5).

---

## 10. Changes made in this setup pass

| File | Change |
|---|---|
| `lib/firebase_options.dart` | Android options filled from `google-services.json` (previously placeholders → Firebase init would crash on Android). |
| `lib/main.dart` | `HttpInspector.setup()` only in `kDebugMode` (it captured all traffic incl. auth tokens in release). |
| `lib/config/constant.dart` | Places key now `String.fromEnvironment('PLACES_API_KEY')` instead of placeholder literal. |
| `android/app/build.gradle` | `MAPS_API_KEY` manifest placeholder read from `local.properties`. |
| `android/app/src/main/AndroidManifest.xml` | Maps key → `${MAPS_API_KEY}`. |
| `android/key.properties`, `android/app/upload-keystore.jks` | New upload key (previous `key.properties` had placeholders). |
| `.gitignore`, `env/example.json`, `env/prod.json` | New. |

## 11. App identity & naming standard (Homzy family)

The package name / bundle ID is **permanent** once published — it can never be changed on Play Store or App Store. Use one consistent scheme across all three apps:

| | Customer (this app) | Seller | Delivery partner |
|---|---|---|---|
| Android applicationId / iOS bundle ID | `com.homzy.customer` ✅ | `com.homzy.seller` ✅ (already in Firebase) | `com.homzy.delivery` (recommended) |
| Store / launcher name | **Homzy** | Homzy Seller (or "Homzy Partner") | Homzy Delivery |
| Deep-link scheme | `homzy://` | `homzyseller://` | `homzydelivery://` |
| Firebase project | `homzy-31dbf` (shared, one app entry per package) | same | same |
| Notification channel IDs | unique per app is fine (separate packages) | | |

Rules: lowercase reverse-domain, no `example`/`hyperlocal`/template names, no version numbers, customer app gets the plain brand name (users search "Homzy"), partner apps get a suffix so they're never confused in the store.

### Verified correct in this app
- `applicationId` / `namespace` = `com.homzy.customer` (`android/app/build.gradle`)
- `MainActivity.kt` package = `com.homzy.customer`
- Android launcher label = `Homzy`; iOS bundle ID = `com.homzy.customer`
- `AppConstant.packageName` / `appName` = `com.homzy.customer` / `Homzy`

### Fixed in this pass
| Where | Before | After |
|---|---|---|
| iOS home-screen name (`CFBundleDisplayName`) | Hyperlocal - Multivendor App | Homzy |
| `appName` / `appTitle` in all 6 languages | Hyper Local (+ transliterations) | Homzy |
| Wallet texts (all languages) | Hyperlocal Wallet | Homzy Wallet |
| OSM map tile user-agent (tracking & delivery maps) | `com.hyperlocal.app` | `com.homzy.customer` (OSM policy requires real app ID) |
| Android notification channel name (visible in system settings) | Custom Sound Notifications | Order Updates (channel ID unchanged) |
| Deep-link scheme | `hyperlocal://` only | `homzy://` added; `hyperlocal://` kept for now |
| pubspec description, web manifest/title, README title | Hyper Local / hyper_local | Homzy |

### Still to do (outside the code)
- **Backend share page:** the product share link (`<customerWebUrl>/share/products/<slug>`) redirects into the app. Change its redirect to `homzy://products/<slug>`, then remove the `hyperlocal` intent filter (Android) and URL scheme (iOS). Make sure the seller/delivery apps do **not** register `hyperlocal://` or `homzy://`.
- **Admin panel:** set the system setting *App name* to `Homzy` (used in referral share text).
- **Firebase:** the `com.yourpackage.name` iOS bundle in `google-services.json` disappears once you register the real iOS app `com.homzy.customer` (§8).
- **Delivery app:** register `com.homzy.delivery` in the same Firebase project before its first build.
- **iOS permission texts** in `Info.plist` are generic template text (mention calls, QR codes, background location). Apple rejects vague/unused purpose strings — rewrite them for what Homzy actually does before App Store submission.

Intentionally **not** renamed: the Dart package `hyper_local` (internal import name, never shown to users, renaming touches every file) and asset filenames. Desktop targets (`linux/`, `macos/`, `windows/`) still use `com.example` — they are not shipped.

## 12. Known follow-ups (not blocking Android launch)

- `flutter_http_inspector` is a git dependency from a third-party repo — consider pinning a commit (`ref:`) or removing it for reproducible builds.
- `build_runner`, `hive_generator`, `change_app_package_name` are in `dependencies`; move them to `dev_dependencies`.
- Deep link uses custom schemes (`homzy://`, legacy `hyperlocal://`). `autoVerify` only works for `https` App Links, so it does nothing here. For shareable web links, add an `https://homzyapp.in` intent filter + `assetlinks.json`.
- Consider adding Firebase Crashlytics for production crash reporting (currently errors only go to `debugPrint`).
