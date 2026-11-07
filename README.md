# CampusTrack

A Flutter app for Amity students: it signs in to [Amizone](https://s.amizone.net/),
scrapes attendance and internal marks, and pairs them with the study material from
[NexAcad](https://nexacad.pages.dev/).

## How the app starts

1. **Session check** – on launch the app looks for a stored Amizone session and
   validates it against the portal.
2. **Login** – without a valid session it opens the sign-in screen. The password
   is kept in memory for that sign-in only and is never written to disk.
3. **Amizone verification** – the portal guards its login form with a Cloudflare
   Turnstile check, and plain HTTP logins are rejected server-side (verified: the
   POST redirects back to `/` and `/Home` to `/Login/logout`). So the app opens the
   portal's own login page in an in-app WebView, pre-filled with the credentials
   just typed, and the student taps LOGIN once. When the page lands on `/Home` the
   app harvests the session cookies and closes the WebView.

   The portal's own Login button does nothing: its `onsubmit` handler calls
   `document.getElementById("loginForm")` while the form's id is lowercase
   `loginform`, so it throws before submitting. The WebView installs a capture
   listener that posts the form itself once Turnstile has issued a token. Note
   that Amizone answers any failed sign-in with the same generic
   "Please check your credential !!" text, so a rejection in the WebView does not
   by itself prove the password is wrong.
4. **Scraping** – attendance comes from `/Home`, internal assessment marks from
   `/Academics/MyCourses`. The NexAcad library is scraped from
   `/pages/resources.html` and its hashed `js/course_catalog.*.js` bundle, then
   filtered to the subjects the student is actually enrolled in.
5. **Dashboard** – the scraped data is cached locally so the app still works
   offline. Sync again from the header icon, or sign out from the menu.

## Data sources

| Source | What is scraped |
| --- | --- |
| `https://s.amizone.net/` | Attendance (attended/held), course names, internal assessment marks |
| `https://nexacad.pages.dev/` | Course resources (notes, PYQs, books, labs) and their Google Drive links |

The bundled index in `lib/data/nexacad_library_data.dart` is only a fallback for
the first launch when the live catalogue cannot be reached.

## Running

```bash
flutter pub get
flutter run            # Android/iOS
```

The Amizone WebView and cookie-based scraping target Android and iOS. On Flutter
web the portal blocks cross-origin requests, so sign-in only works on a device.

## Tests

```bash
flutter test
```

`test/amizone_parser_test.dart` and `test/nexacad_catalog_parser_test.dart` cover
the HTML and catalogue parsing against real page markup.
