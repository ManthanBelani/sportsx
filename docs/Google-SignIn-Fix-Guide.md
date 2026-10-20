# Google Sign-In Troubleshooting & Fix Guide — SportX India

This guide details the complete configuration required to make **"Continue with Google"** work reliably across the Flutter mobile app and Laravel backend.

---

## 1. Overview of the Flow

```
┌─────────────────┐                       ┌──────────────────┐               ┌────────────────┐
│   Flutter App   │                       │  Laravel Backend │               │ Google Servers │
└────────┬────────┘                       └────────┬─────────┘               └───────┬────────┘
         │                                         │                                 │
         │ 1. GoogleSignIn(serverClientId: ...)    │                                 │
         │    Requests account picker with scope   │                                 │
         ├─────────────────────────────────────────┼────────────────────────────────►│
         │                                         │                                 │
         │ 2. Returns GoogleSignInAuthentication   │                                 │
         │    with ID Token                        │                                 │
         │◄────────────────────────────────────────┼─────────────────────────────────┤
         │                                         │                                 │
         │ 3. POST /api/v1/auth/google             │                                 │
         │    { "id_token": "..." }                │                                 │
         ├────────────────────────────────────────►│                                 │
         │                                         │ 4. Verify ID Token signature   │
         │                                         │    against Google JWKS keys     │
         │                                         │ 5. Match 'aud' == CLIENT_ID     │
         │                                         │ 6. Issue Sanctum token          │
         │ 7. Return user + Sanctum Auth Token     │                                 │
         │◄────────────────────────────────────────┤                                 │
```

---

## 2. Issues Found & Applied Fixes

### Issue A: Missing `serverClientId` in Flutter App (Fixed in Code)
* **Problem**: In `sportx_app/lib/features/auth/presentation/widgets/google_sign_in_button.dart`, `serverClientId` was only read from `--dart-define=GOOGLE_SERVER_CLIENT_ID`. When not provided via command line, `serverClientId` was `null`.
* **Impact**: On Android, Google Play Services **never generates an `idToken`** if `serverClientId` is omitted. As a result, `auth.idToken` returned `null` and the app showed:
  > *"Google sign-in is not configured on this device build yet."*
* **Fix Applied**: Updated `google_sign_in_button.dart` and `sportx_app/.env` to:
  1. Check `--dart-define` first.
  2. Check `dotenv.env['GOOGLE_SERVER_CLIENT_ID']`.
  3. Fall back automatically to the project's canonical Web Client ID:
     `241021895160-6ei8d3apdg08od7veagg052scpsg0hfp.apps.googleusercontent.com`

---

## 3. Required Firebase Console Settings (Action Required)

### 1. Register Release SHA-1 & SHA-256 Fingerprints

Your app's release build signs with `d:\SportX Project\my-release-key.jks`. If the release fingerprint is not in Firebase Console, Google returns **`ApiException: 10`** (Developer Error) on physical release builds.

1. Open **[Firebase Console ➔ Project Settings](https://console.firebase.google.com/project/sportx-8e0ec/settings/general)**.
2. Scroll down to **Your apps** ➔ select **Android app (`com.sportx.application`)**.
3. Under **SHA certificate fingerprints**, click **Add fingerprint**:
   - **Release SHA-1**:
     ```
     4B:11:8A:D3:86:13:27:0F:70:15:AC:A9:E3:10:A8:75:3A:A4:16:50
     ```
   - **Release SHA-256**:
     ```
     D1:AD:C6:A2:BE:52:92:24:4E:7B:8A:24:A3:60:17:B6:CC:FF:FC:F2:68:6A:4F:BE:87:3A:31:86:C3:AB:61:2F
     ```
4. Verify that the **Debug SHA-1** is also present:
   - **Debug SHA-1**: `12:00:1D:B2:33:06:38:4D:F1:FC:5D:C8:30:14:E0:81:CC:A2:77:3F`
   - **Debug SHA-256**: `FF:78:EE:9B:5A:82:D9:83:97:B0:5A:D0:B1:83:D4:2F:A6:75:87:05:BB:C6:31:57:9B:B5:71:BE:85:D1:BF:21`
5. Click **Save**.
6. Download the updated `google-services.json` and replace `sportx_app/android/app/google-services.json`.

---

### 2. Enable Google Sign-In Provider

1. In Firebase Console, go to **Build** ➔ **Authentication** ➔ **Sign-in method** tab.
2. Click on **Google**.
3. Toggle **Enable** to **ON**.
4. Set the **Project support email** (choose your admin email).
   > *Note: If the Project support email is left blank, Google Sign-In will fail silently.*
5. In the **Web SDK configuration** section:
   - Ensure the Web Client ID matches:
     `241021895160-6ei8d3apdg08od7veagg052scpsg0hfp.apps.googleusercontent.com`
6. Click **Save**.

---

### 3. Google Cloud OAuth Consent Screen

If testing with external Google accounts:
1. Open **[Google Cloud OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent?project=sportx-8e0ec)**.
2. If the user type is **External** and in **Testing** status:
   - Under **Test users**, click **+ ADD USERS**.
   - Add the Gmail addresses you are testing with.
   *(Or publish the app to Production status if ready for public testing)*.

---

## 4. Backend Configuration Check (`sportx-api`)

Ensure your `sportx-api/.env` file contains:

```dotenv
# Google Sign-In (ID-token verification)
GOOGLE_CLIENT_ID=241021895160-6ei8d3apdg08od7veagg052scpsg0hfp.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=
GOOGLE_ALLOW_SIGNUP=true
GOOGLE_DEFAULT_ROLE=athlete
GOOGLE_ALLOWED_ROLES=athlete,coach,academy,organizer,sponsor,scout,talent_scout
```

Verify backend configuration:
```powershell
D:\php84\php.exe artisan tinker --execute="echo 'Google Client ID: ' . config('sportx.google.client_id') . PHP_EOL;"
```

---

## 5. Mobile App Configuration (`sportx_app`)

In `sportx_app/.env`:
```dotenv
GOOGLE_SERVER_CLIENT_ID=241021895160-6ei8d3apdg08od7veagg052scpsg0hfp.apps.googleusercontent.com
```

### Running the App:
Do a clean build so new Gradle signing configs and environment definitions are applied:
```powershell
flutter clean
flutter pub get
flutter run
```

---

## 6. Summary Checklist

| # | Item | Status |
|---|------|--------|
| 1 | Web Client ID in `sportx_app/lib/features/auth/presentation/widgets/google_sign_in_button.dart` | ✅ Fixed |
| 2 | `GOOGLE_SERVER_CLIENT_ID` in `sportx_app/.env` | ✅ Added |
| 3 | `GOOGLE_CLIENT_ID` in `sportx-api/.env` | ✅ Configured |
| 4 | Support Email set in Firebase Console | ⚠️ Verify in Firebase Console |
| 5 | Google Provider enabled in Firebase Auth | ⚠️ Verify in Firebase Console |
| 6 | Release Keystore SHA-1 (`4B:11:8A:...`) added to Firebase | ⚠️ Add in Firebase Console |
