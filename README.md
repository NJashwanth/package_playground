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

## Notes

- This playground uses `dart:io` and local HTTP server behavior, so it is best for mobile/desktop testing rather than web.
- Add your own mock routes by editing `_sampleConfig` in `lib/main.dart`.
