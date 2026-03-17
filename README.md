# package_playground

Single-app Flutter sandbox for testing and iterating on your own packages:

- `flutter_mock_server`
- `lifecycle_logger`

## What Is Included

- `Mock Server` tab:
	- starts/stops an in-app local server with `flutter_mock_server`
	- writes a temporary `mock.yaml` config at runtime
	- sends a sample `GET /users?limit=3` request and displays the response
- `Lifecycle` tab:
	- enables app, route, and widget lifecycle logging with `lifecycle_logger`
	- stores events in-memory for quick inspection
	- includes controls to mount/unmount a probe widget and clear logs

## Run

```bash
flutter pub get
flutter run
```

For Chrome:

```bash
flutter run -d chrome
```

## Notes

- On desktop (macOS/Linux/Windows), the app can start its own local mock server.
- On web, the app can run in Chrome, but the local mock server cannot run inside the browser. Use an external mock server URL in the Mock Server tab instead.
- Add your own mock routes by editing `_sampleConfig` in `lib/main.dart`.
