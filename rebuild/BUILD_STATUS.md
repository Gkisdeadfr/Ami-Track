# Build status

This branch is the isolated Ami-Track v2 implementation.

- Backend: FastAPI parser and API tests are run by GitHub Actions.
- Mobile: Flutter SDK is pinned to 3.41.2 for CI and runs analyzer plus widget tests.
- Existing application remains on `main`.
- Amizone login continues in the official WebView so the student completes Cloudflare Turnstile.
- Before multi-user deployment, replace the in-memory session store with encrypted durable storage and deploy behind HTTPS.
