# Camera Archive

> Collect virtual 1990s–2010s digital cameras and shoot real photos through simulated capture pipelines.

## Stack

- **Framework:** Flutter (Dart)
- **State management:** `provider`
- **Camera & media:** `camera`, `image`, `audioplayers`
- **Location:** `geolocator`, `geocoding`
- **Storage:** local JSON + files via `path_provider`
- **CI:** Codemagic

## Description

A Flutter app built around collecting virtual 1990s–2010s digital cameras and shooting real
photos through them. Each camera has its own simulated capture path — not just a filter — so
photos come out looking like they were taken on that specific device. See `instructions.md`,
`DESIGN.md`, and `PRODUCT.md` for the original concept and design docs.

## Features

- **11 distinct camera profiles** (`lib/data/camera_catalog.dart`), each with its own aspect
  ratio, resolution, color science, noise, sharpening, vignette, bloom, lens distortion, flash
  behavior, shutter lag, startup animation, battery drain, and storage capacity — including two
  easter-egg cameras (Mom's Camera, School Trip Camera).
- **A real per-shot pixel pipeline** (`lib/services/image_processor.dart`) that runs a captured
  photo through each camera's parameters on a background isolate — an actual simulated capture
  path, not a post filter.
- **Live viewfinder color grading** (`lib/services/live_preview_filter.dart`) so the camera
  already looks different before you shoot.
- **Camera collection & rarity-weighted discovery** (`lib/state/archive_store.dart`,
  `lib/screens/discover_screen.dart`) — Common → Legendary.
- **Photo rolls** with GPS-tagged location (reverse-geocoded), notes, and a photo grid/viewer.
- **Per-camera customization** — body color, strap, date-stamp format, flash mode — persisted
  per owned camera.
- **Local persistence** — one JSON state file plus a photos/thumbs directory in the app's
  documents directory (`lib/data/app_repository.dart`).

Built and tested primarily against **Android**. `camera_windows` is pulled in for secondary
desktop dev testing, but webcam "camera feel" isn't the tuning target.

## How to Build / Run

```bash
flutter pub get
flutter run -d <android-device-or-emulator>
```

The app needs camera and location permissions at first launch (location is optional — rolls
just won't get an auto-tagged place if denied).

### Tests

```bash
flutter test
```

`test/widget_test.dart` boots the app to the camera shelf without touching camera hardware
(the capture screen is never navigated to in the test).

### Regenerating shutter sounds

Shutter click sounds are synthesized, not sourced — see `tool/gen_sounds.py`:

```bash
python tool/gen_sounds.py
```

## License

Released under the [MIT License](LICENSE).
