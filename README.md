# Ami-Track

Ami-Track is a Flutter student companion for Amity University, backed by FastAPI integrations for Amizone and NexAcad.

## Repository layout

- `lib/`: the active Flutter application.
- `backend/`: FastAPI service, Amizone parsers, NexAcad catalogue integration and backend tests.
- `test/`: Flutter tests.
- `.github/workflows/ami-track-v2.yml`: backend and Flutter CI.

The previous app was used only as a product reference during the rebuild. Its implementation has been removed from the working tree; it remains available in Git history.

## Run the backend

From the repository root:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export AMITRACK_TOKEN_SECRET="$(python -c 'import secrets; print(secrets.token_urlsafe(48))')"
uvicorn app.main:app --reload --host 0.0.0.0
```

Health check: http://127.0.0.1:8000/health

## Run on a USB-connected Android phone

Generate the Android runner once after cloning:

```bash
flutter create --platforms=android .
flutter pub get
adb devices
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=AMITRACK_API_URL=http://127.0.0.1:8000
```

Keep the backend running while testing. For iOS development, generate both runners with `flutter create --platforms=android,ios .`.

## Build an APK

A release APK must use a backend reachable by the phone over HTTPS:

```bash
flutter build apk --release --dart-define=AMITRACK_API_URL=https://YOUR-API-HOST
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

## Authentication and deployment

Amizone authentication happens in the official WebView and the user completes Cloudflare Turnstile. Ami-Track does not bypass the challenge or store the Amizone password. Session cookies are transferred to the API only after login.

The backend currently uses an in-memory session store for local development. Before multi-user deployment, replace it with encrypted durable storage and deploy behind HTTPS.
