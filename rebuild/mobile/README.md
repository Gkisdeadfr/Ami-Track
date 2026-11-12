# Ami-Track mobile client

This folder contains the Flutter source package. Generate platform runners once:

```bash
cd rebuild/mobile
flutter create --platforms=android,ios .
flutter pub get
flutter run --dart-define=AMITRACK_API_URL=https://YOUR-API-HOST
```

For Android Emulator during local backend development, the default API URL is `http://10.0.2.2:8000`. For a physical device, use a reachable HTTPS backend URL via `--dart-define`.

The Amizone login is opened in the official WebView. The user completes Turnstile themselves. After the portal redirects to `/Home`, the app transfers the cookie jar to the API and receives a short-lived Ami-Track bearer token. Passwords are not persisted. The bearer token is stored using the OS secure-storage plugin.
