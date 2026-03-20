# package_playground

A Flutter sandbox for testing and iterating on packages — split into three independent apps:

1. **WiFi Credentials Verifier** — validates Wi-Fi SSID/password formats
2. **Genkit Playground** — integrates Google's [Genkit Dart](https://pub.dev/packages/genkit) with Gemini AI
3. **Mock Server Demo** — full CRUD UI backed by a local [flutter_mock_server](https://pub.dev/packages/flutter_mock_server) instance

---

## Project Structure

```
lib/
  main.dart                                  ← WiFi Credentials Verifier entry point
  main_genkit.dart                           ← Genkit Playground entry point
  main_mock_server_demo.dart                 ← Mock Server Demo entry point
  wifi_credentials_verifier/
    wifi_credentials_verifier.dart           ← Wi-Fi credential validation logic
  genkit/
    genkit_app.dart                          ← Genkit UI + Gemini AI integration
  flutter_mock_server_demo/
    models/
      user.dart                              ← User data model
    services/
      mock_server_service.dart               ← FlutterMockServer lifecycle singleton
      users_api_service.dart                 ← HTTP CRUD client (GET/POST/PUT/DELETE)
    screens/
      users_screen.dart                      ← Material 3 user list with swipe-to-delete
      user_form_screen.dart                  ← Add / edit user form
mock.yaml                                    ← Mock server route & store config
test/
  wifi_credentials_verifier_test.dart
  widget_test.dart
  flutter_mock_server_core_test.dart
```

---

## Apps

### 1. WiFi Credentials Verifier

Validates Wi-Fi SSID and password input using custom Dart logic.

**Run:**
```bash
flutter run -t lib/main.dart
```

---

### 2. Genkit Playground

A chat-style Flutter app powered by [Genkit](https://pub.dev/packages/genkit) and [Google AI (Gemini)](https://pub.dev/packages/genkit_google_genai).

**Features:**
- Type a prompt and generate a response from Gemini 2.5 Flash
- Loading indicator during generation
- Inline error display
- Scrollable, selectable response output

**Setup — add your Gemini API key:**

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Paste your key (get one free at [aistudio.google.com](https://aistudio.google.com/app/apikey)):
   ```
   GEMINI_API_KEY=your_key_here
   ```

**Run:**
```bash
flutter run -t lib/main_genkit.dart
```

> **Note:** `.env` is git-ignored — your API key will never be committed.

---

### 3. Mock Server Demo

A full CRUD app that spins up a real in-process HTTP server (`flutter_mock_server`) and drives it with a live Material 3 UI.

**Features:**
- Auto-starts `FlutterMockServer` on `http://localhost:8080` using `mock.yaml`
- Play / Stop button to toggle the server at runtime
- User list with role-coloured avatars (admin / member / viewer)
- Swipe left to delete, tap to edit
- Animated role selector in the add/edit form
- Supports filtering, sorting, and pagination via `mock.yaml` query params

**Run:**
```bash
flutter run -t lib/main_mock_server_demo.dart
```

You can also start the server standalone (CLI) for testing with curl or Postman:
```bash
dart run flutter_mock_server start
```

**CRUD endpoints (all served from `mock.yaml`):**

| Method | Path | Action |
|---|---|---|
| `GET` | `/users` | List all users |
| `GET` | `/users/:id` | Get one user |
| `POST` | `/users` | Create user |
| `PUT` | `/users/:id` | Update user |
| `DELETE` | `/users/:id` | Delete user |

---

## Dependencies

| Package | Purpose |
|---|---|
| `genkit: ^0.12.0` | Genkit core framework |
| `genkit_google_genai: ^0.2.3` | Gemini AI provider plugin |
| `flutter_dotenv: ^5.2.1` | Load API keys from `.env` |
| `flutter_mock_server: ^1.0.0` | In-app local mock HTTP server |
| `http: ^1.5.0` | HTTP client |
| `path: ^1.9.0` | Path resolution utilities |
| `lifecycle_logger: ^0.0.4` | App/route/widget lifecycle logging |

---

## Getting Started

```bash
flutter pub get
cp .env.example .env   # add your GEMINI_API_KEY
```

Then use the **Run & Debug** panel in VS Code and pick one of:
- `WiFi Credentials Verifier`
- `Genkit Playground`
- `Mock Server Demo`

---

## Web / Chrome Note

`genkit_google_genai` makes direct API calls — these will be blocked by CORS in a browser. For web/Chrome use, consider [`genkit_chrome`](https://pub.dev/packages/genkit_chrome) (Chrome Built-in Gemini Nano, no API key needed) or route calls through a backend proxy.

