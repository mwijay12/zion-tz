# Zion Mobile

The Flutter member app for Zion Jerusalem Church, Mbagala. It brings together the Bible, Tenzi za Rohoni hymns, sermons, Christian radio, notes, events, prayer, and discipleship growth.

## Run

```bash
flutter pub get
dart analyze lib
flutter test
flutter run
```

The optional Gemini feature is disabled unless a local key is supplied:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_local_key
```

Never commit a real key. Production must use a server-side proxy.

## Status

This is a working prototype, not a production release. Authentication, real offline audio downloads, lock-screen playback, cross-device sync, and engagement features are still being implemented.

See the root [README](../README.md) for the complete project overview and [PLAN.md](../PLAN.md) for the prioritized engineering plan.
