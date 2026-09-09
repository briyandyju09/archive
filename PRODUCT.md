# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

People who want the feel of shooting on a specific real digital camera from the 1990s–2010s, not a generic vintage filter — nostalgia-driven and hobbyist photographers. Public release on App Store / Play Store, so the audience is strangers discovering the app, not just the developer.

## Product Purpose

Camera Archive lets people take real photos through virtual recreations of specific historical digital cameras. Each virtual camera reproduces that camera's actual photographic behavior — lens characteristics, color science, noise, sharpening, bloom, lens distortion, flash behavior, shutter lag — so a photo taken with it looks and feels like it came out of that physical camera. Success means a photo is recognizable as "shot on the 2004 Point & Shoot," not "Instagram filter applied."

## Positioning

Every other nostalgia camera app works by applying a filter to whatever the phone's camera already captured. Camera Archive runs each shot through a real per-camera pixel pipeline on a background isolate (`lib/services/image_processor.dart`) plus live viewfinder color grading before the shutter even fires (`lib/services/live_preview_filter.dart`) — the simulated capture path is the product, not a preset. That, combined with a rarity-weighted collection/discovery layer over real historical (and a few fictional/easter-egg) cameras, is the mechanism a plain filter pack can't copy.

## Operating Context

- Mobile app (Flutter), used in the moment of taking a photo — phone in hand, real-world lighting, real subjects.
- Requires camera and location permissions at first launch; location is optional (rolls just skip auto-tagged place if denied).
- Users browse/discover cameras, open one, shoot, and organize results into photo rolls (GPS-tagged, noted).
- Built and tested primarily against Android so far; iOS and desktop (Windows via `camera_windows`) exist as secondary/dev targets, with iOS intended for a real native pass (see Platform below).

## Capabilities and Constraints

- 11 distinct camera profiles today (`lib/data/camera_catalog.dart`), each with its own aspect ratio, resolution, color science, noise, sharpening, vignette, bloom, lens distortion, flash behavior, shutter lag, startup animation, battery drain, and storage capacity — including two easter-egg cameras (Mom's Camera, School Trip Camera).
- Per-shot processing runs on a background isolate, not inline on the UI thread.
- Camera collection uses a rarity system (Common → Legendary) meant to encourage discovery without turning the app into a traditional game.
- Photo rolls hold camera-used, date, location, photos, and notes.
- Per-camera customization (body color, strap, date-stamp format, flash mode) persists per owned camera but must not alter the camera's core simulated characteristics.
- Persistence is local only today: one JSON state file plus a photos/thumbs directory in the app's documents directory — no backend/cloud sync yet.
- Shutter sounds are synthesized (`tool/gen_sounds.py`), not sourced recordings.

## Brand Commitments

- Name: **Camera Archive**.
- Existing theme (`lib/theme/app_theme.dart`): warm, paper-and-viewfinder palette — amber accent (`#E08A2E`, nodding to LCD date-stamp orange) on a neutral ground, deliberately not default Material purple. Manrope for UI text, JetBrains Mono for LCD/date-stamp/chrome accents.
- No other naming, tone, or reference commitments confirmed beyond these.

## Evidence on Hand

- No real sample photos, testimonials, press, or marketing content exist yet — future work must not fabricate any of these.
- Only real assets on hand are synthesized shutter-click sound files (`assets/sounds/`).

## Product Principles

1. Simulate a real capture path, never a post-hoc filter — the pixel pipeline and live viewfinder grading are the product.
2. Every camera must feel like a distinct physical object with its own quirks and limitations, not a shared preset with different numbers.
3. Collection and rarity should motivate people to actually go shoot, not become a separate game layer bolted onto the camera.
4. Honor era-authentic limitations (noise, shutter lag, blown highlights, red-eye) rather than glamorizing or smoothing them away.
5. Now that this is heading to public release, permissions framing, first-run clarity, and platform-native feel matter as much as the camera simulation itself.

## Accessibility & Inclusion

No specific accessibility standard or user need has been confirmed yet. Given public release, baseline accessibility (contrast, screen-reader labels, touch target sizing) is expected but not yet audited or committed to a standard.
