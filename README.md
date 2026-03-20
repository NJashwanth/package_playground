# package_playground

A Flutter sandbox for testing and iterating on packages — split into two independent apps:

1. **WiFi Credentials Verifier** — validates Wi-Fi SSID/password formats
2. **Genkit Playground** — integrates Google's [Genkit Dart](https://pub.dev/packages/genkit) with Gemini AI

---

## Project Structure

```
lib/
  main.dart                                  ← WiFi Credentials Verifier entry point
  main_genkit.dart                           ← Genkit Playground entry point
  wifi_credentials_verifier/
    wifi_credentials_verifier.dart           ← Wi-Fi credential validation logic
  genkit/
    genkit_app.dart                          ← Genkit UI + Gemini AI integration
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

## Dependencies

| Package | Purpose |
|---|---|
| `genkit: ^0.12.0` | Genkit core framework |
| `genkit_google_genai: ^0.2.3` | Gemini AI provider plugin |
| `flutter_dotenv: ^5.2.1` | Load API keys from `.env` |
| `flutter_mock_server: ^1.0.0` | In-app local mock HTTP server |
| `lifecycle_logger: ^0.0.4` | App/route/widget lifecycle logging |
| `http: ^1.5.0` | HTTP client |

---

## Getting Started

```bash
flutter pub get
cp .env.example .env   # add your GEMINI_API_KEY
```

Then use the **Run & Debug** panel in VS Code and pick either:
- `WiFi Credentials Verifier`
- `Genkit Playground`

---

## Web / Chrome Note

`genkit_google_genai` makes direct API calls — these will be blocked by CORS in a browser. For web/Chrome use, consider [`genkit_chrome`](https://pub.dev/packages/genkit_chrome) (Chrome Built-in Gemini Nano, no API key needed) or route calls through a backend proxy.

