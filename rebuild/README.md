# Ami-Track v2

A clean replacement architecture for Ami-Track. The existing app on `main` is untouched.

## Architecture
- `mobile/`: Flutter client (Android/iOS first). Amizone login remains in the official embedded browser so the user completes Cloudflare Turnstile.
- `backend/`: FastAPI API for server-side portal fetching, HTML parsing, session validation, sync and a separate NexAcad catalogue integration.
- Session cookies are never logged. The prototype uses an in-memory session store; deploy with an encrypted Redis/PostgreSQL store and HTTPS before real multi-user use.

## Start backend
```bash
cd rebuild/backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export AMITRACK_TOKEN_SECRET="$(python -c 'import secrets; print(secrets.token_urlsafe(48))')"
uvicorn app.main:app --reload
```
API docs: http://127.0.0.1:8000/docs

## Start mobile
```bash
cd rebuild/mobile
flutter pub get
flutter run
```
Set `AMITRACK_API_URL` with --dart-define for a non-local backend URL.

## Important
Amizone's login and anti-bot flow is performed by the actual portal in WebView. This app does not solve, emulate or bypass Turnstile. The backend receives only the session cookies that the user has already obtained after successful login.
