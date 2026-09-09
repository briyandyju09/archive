---
name: Camera Archive
description: A warm, amber-seeded collection shelf for virtual digicams that tightens into a black-and-LCD-orange chrome HUD the moment you shoot.
colors:
  digicam-amber: "#E08A2E"
  lcd-ember: "#FF8C1E"
  moss-common: "#4CAF6D"
  sky-uncommon: "#4C8DFF"
  orchid-rare: "#B16CFF"
  burnt-vintage: "#E0912F"
  ember-legendary: "#E0473F"
  matte-black-finish: "#2B2B2E"
  blush-pink-finish: "#E49AAE"
  steel-blue-finish: "#5C82C4"
  bone-white-finish: "#F2EFE9"
  brushed-silver-finish: "#B7BCC2"
  hud-scrim: "rgba(0,0,0,0.55)"
typography:
  display:
    fontFamily: "Manrope, sans-serif"
    fontSize: "28px"
    fontWeight: 800
    lineHeight: 1.15
  title:
    fontFamily: "Manrope, sans-serif"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.2
  body:
    fontFamily: "Manrope, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "Manrope, sans-serif"
    fontSize: "12.5px"
    fontWeight: 600
    lineHeight: 1.3
  lcd:
    fontFamily: "JetBrains Mono, monospace"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.02em"
rounded:
  pill: "999px"
  emphasis: "24px"
  card: "18px"
  control: "14px"
  thumbnail: "12px"
  chip: "10px"
  tight: "8px"
  lcd: "6px"
spacing:
  xs: "4px"
  sm: "8px"
  gutter: "12px"
  md: "16px"
  lg: "24px"
components:
  button-primary:
    backgroundColor: "{colors.digicam-amber}"
    rounded: "{rounded.control}"
    padding: "14px 20px"
  card:
    rounded: "{rounded.card}"
    padding: "16px"
  hud-pill:
    backgroundColor: "{colors.hud-scrim}"
    textColor: "#FFFFFF"
    typography: "{typography.lcd}"
    rounded: "{rounded.pill}"
    padding: "6px 10px"
  lcd-date-stamp:
    backgroundColor: "rgba(0,0,0,0.87)"
    textColor: "{colors.lcd-ember}"
    typography: "{typography.lcd}"
    rounded: "{rounded.lcd}"
    padding: "4px 10px"
---

# Design System: Camera Archive

## Overview

**Creative North Star: "The Camera Shelf"**

Camera Archive runs on two registers, and both are already in the code. At rest — browsing the shelf, a roll, a camera's spec sheet — the system is warm, nostalgic, and unpretentious: a single amber seed color, flat tonal cards, generous rounding, Manrope doing all the reading work. The moment a camera's viewfinder opens, the system tightens into something device-authentic and precise: black chrome HUD pills, a JetBrains Mono LCD readout glowing orange, battery and shot-counter telemetry exactly where a real digicam would put it. Neither register apologizes for the other — the shelf never tries to look like firmware, and the HUD never softens into the shelf's warmth.

The seed color is a deliberate, confirmed rejection of Material's default purple (`AppTheme`'s own comment: "instead of default Material purple"). Every themed surface — light and dark — is derived from that one amber, never hand-picked.

**Key Characteristics:**
- Amber-seeded Material 3 (`#E08A2E`), not default Material purple
- Flat, tonal-fill surfaces — zero drop shadows anywhere
- Two-register system: warm neutral "shelf" UI at rest, black/LCD-orange chrome HUD during capture
- Manrope carries every piece of reading text; JetBrains Mono is reserved entirely for LCD/HUD digits
- The rarity color ramp exists solely to signal collection status — never used as a decorative accent
- No sourced camera photography or icon packs — every camera glyph is drawn in code

## Colors

Almost the entire palette is one seed color plus Material's algorithmic derivations from it; the only hand-picked hexes are the LCD accent, the rarity ramp, and the camera body-finish swatches.

### Primary
- **Digicam Amber** (`#E08A2E`): the single seed color passed to `ColorScheme.fromSeed` for both light and dark themes. Every Material role — surface, primaryContainer, outline, and so on — is generated algorithmically from this seed and adapts automatically between light and dark. Don't hand-pick hex for those derived roles; change the system by changing the seed.

### Secondary — Rarity Signal Ramp
Five colors, one per collection-rarity tier, used only on rarity badges and rarity counts:
- **Moss Common** (`#4CAF6D`)
- **Sky Uncommon** (`#4C8DFF`)
- **Orchid Rare** (`#B16CFF`)
- **Burnt Vintage** (`#E0912F`)
- **Ember Legendary** (`#E0473F`)

Each renders as a 14%-alpha fill with a 35%-alpha border of the same hue behind full-opacity text (`RarityBadge`) — never a solid fill.

### Tertiary — Camera Body Finishes
Five colors, the customization options for an owned camera's body (`CameraIcon`, `BodyColor`):
- **Matte Black** (`#2B2B2E`)
- **Blush Pink** (`#E49AAE`)
- **Steel Blue** (`#5C82C4`)
- **Bone White** (`#F2EFE9`)
- **Brushed Silver** (`#B7BCC2`) — the default/fallback finish

### Neutral
- **Surface / on-surface / surfaceContainerHigh / onSurfaceVariant / outlineVariant**: Material 3 tonal roles derived algorithmically from Digicam Amber. No fixed hex is normative here by design.
- **LCD Ember** (`#FF8C1E`): the one accent color that lives outside the Material scheme entirely. Used only for the date-stamp digits and low-battery/low-shots warning states, always against a black or near-black chrome ground — it is calibrated for that contrast and nowhere else.
- **HUD Scrim** (`rgba(0,0,0,0.55)`): the translucent black background behind every capture-screen chrome pill.

### Named Rules
**The No-Purple Rule.** Nothing in this system derives from Material's default purple seed. If a screen needs a new themed surface, derive it from Digicam Amber — never introduce a second seed or a hand-picked Material role color.

**The Signal Ramp Rule.** The five rarity colors mean exactly one thing — collection rarity — and appear only on rarity badges and rarity counts. They are never repurposed as a general accent, button color, or decoration.

## Typography

**Display / Title / Body / Label Font:** Manrope (with system sans-serif fallback)
**LCD Font:** JetBrains Mono

**Character:** Manrope is a warm, rounded-geometric sans that carries every piece of reading UI — titles, body copy, captions, counts. JetBrains Mono never appears in that context; it exists solely to make a readout look like it's coming off a real device's LCD segment display.

### Hierarchy
- **Display** (w800, 28px, headlineMedium): the single big collection-count numeral on the "My Cameras" summary card.
- **Title** (w700, 22px, titleLarge): app bar titles ("My Cameras", "My Rolls").
- **Body** (w400, ~16px): descriptive prose — camera spec sheets, roll notes.
- **Label** (w600–w700, 11.5–13px): captions and meta text — megapixel counts, roll photo counts, rarity counts, card subtitles.
- **LCD** (w600, JetBrains Mono, 12–16px): HUD chrome-pill readouts and the LCD date-stamp digits.

### Named Rules
**The One Mono Rule.** JetBrains Mono is used exclusively inside dark/black chrome contexts (HUD pills, the LCD date-stamp box). It never appears as standard UI text, a heading, or body copy.

## Layout

A two-destination root shell (bottom `NavigationBar`: "Cameras" / "Rolls") over single-column, compact-width screens — no rail or drawer yet. The primary "My Cameras" screen is a `CustomScrollView`: a summary-card sliver, then a 2-column `SliverGrid` (`childAspectRatio: 0.78`, 12px main- and cross-axis gutters). List/detail screens (rolls, camera detail) are single-column scroll views.

Standard screen horizontal inset is 16px. Scrollable content that sits above the bottom `NavigationBar` and/or a `FloatingActionButton` reserves 100–120px of trailing padding so the last row never sits under system chrome. Each primary screen carries at most one `FloatingActionButton.extended`, reserved for that screen's single most important action (e.g. "Discover Cameras").

## Elevation & Depth

Flat by design, not by omission: `CardThemeData.elevation` and `AppBarTheme.elevation` are both explicitly `0`, and `surfaceTintColor` is explicitly `Colors.transparent` on both the app bar and the navigation bar. Depth is conveyed through tonal contrast (a `surfaceContainerHigh` card against the `surface` background) and alpha overlays (the rarity badge's 14%/35%-alpha fill and border, the HUD's 55%-alpha black scrim) — never through a `boxShadow`.

### Named Rules
**The Flat-By-Default Rule.** Surfaces do not lift. If a component needs to read as "above" its background, express that with a tonal fill or an alpha scrim, not a shadow.

## Shapes

A pill-or-rectangle form language: anything transient or chrome-like (HUD pills, rarity badges, the collection progress bar) is fully rounded (`999px`); anything that holds content (cards, the discover CTA) is a rounded rectangle, 18–24px. The camera glyph itself is drawn in code as a `CustomPainter` silhouette (rounded body, circular lens, rounded-square flash) rather than sourced photography or an icon-pack asset — a deliberate constraint so the collection can grow without commissioning new art per camera.

## Components

### Buttons
- **Shape:** rounded rectangle, 14px (`{rounded.control}`)
- **Primary:** `FilledButton`, background = Digicam Amber (via theme primary), 20px horizontal / 14px vertical padding
- **Icon buttons:** unthemed system default; used sparingly (back, flash toggle) inside dark HUD contexts on white/accent icon color

### Cards
- **Corner style:** 18px (`{rounded.card}`) by default; the Discover screen's single emphasis card/CTA escalates to 24px (`{rounded.emphasis}`) to read as more important
- **Background:** `surfaceContainerHigh` (tonal fill, not a border)
- **Shadow strategy:** none — see Elevation & Depth
- **Internal padding:** 16px for content cards (`_CollectionSummary`); the denser `CameraShelfCard` grid tile uses a tighter 14px inset to fit the icon + two text lines

### Rarity Badge
- **Style:** rectangular bezel (AppRadii.tight), charcoal fill, 50%-alpha rarity-color border, full-opacity rarity-color text, small drawn status-LED square leading (never an emoji)
- **Compact variant:** smaller padding/font for dense contexts (shelf grid tiles)

### HUD Chrome Pill
- **Style:** pill (999px), `HUD Scrim` background, white icon + JetBrains Mono label by default
- **State color:** swaps to `#FFB74D` (caution) or `#EF5350` (critical) for low-battery and low-shots-remaining states — the only place those two colors appear
- **Used for:** battery level, shot counter, back button, flash-mode indicator on the capture screen

### LCD Date Stamp
- **Style:** near-black (`rgba(0,0,0,0.87)`) box, 6px corners (`{rounded.lcd}`), JetBrains Mono text in LCD Ember
- **Purpose:** the one place LCD Ember appears outside a warning state — deliberately mimics a real digicam's orange digit readout

### Camera Icon (signature component)
Code-drawn digicam silhouette (`CustomPainter`): rounded body + viewfinder bump in the selected body-finish color, dark lens rings, rounded-square flash. A locked/undiscovered camera renders in `outlineVariant` gray with a padlock arc instead of its real finish — the visual is the primary "you haven't found this one yet" signal, with no separate lock icon or overlay needed.

### Navigation
- **Style:** bottom `NavigationBar`, 2 destinations, `surfaceTintColor: transparent`, selected indicator = `primaryContainer`
- **States:** outlined icon unselected, filled icon selected; label always visible

## Do's and Don'ts

### Do:
- **Do** derive every themed surface from the Digicam Amber seed via `ColorScheme.fromSeed` — change the seed to change the system, never hand-pick a Material role's hex.
- **Do** keep JetBrains Mono confined to LCD/HUD chrome contexts; everything else is Manrope.
- **Do** keep `Card`, `AppBar`, and `NavigationBar` at elevation 0 with `surfaceTintColor: transparent`; convey depth with tonal fill or alpha scrim, not shadow.
- **Do** use the rarity ramp only to signal collection rarity — badges and rarity counts, nothing else.
- **Do** use fully-rounded (pill) shapes for transient/chrome elements and 18–24px rounded rectangles for content containers.
- **Do** draw new camera glyphs in code (`CustomPainter`), consistent with the existing collection, rather than sourcing photography or an icon pack.

### Don't:
- **Don't** reintroduce Material's default purple or any second seed color — the amber seed is a confirmed, explicit rejection of that look.
- **Don't** add drop shadows to lift cards or bars — flat + tonal fill is the system's entire depth model.
- **Don't** use LCD Ember outside a black/near-black chrome ground — it's calibrated for that contrast only and reads wrong on light surfaces.
- **Don't** stack more than one `FloatingActionButton`, or give a single screen more than one primary action.
- **Don't** repurpose the camera body-finish colors (Matte Black, Blush Pink, Steel Blue, Bone White, Brushed Silver) as general UI accents — they belong to camera customization only.
