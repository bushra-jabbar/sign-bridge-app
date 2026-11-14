# Sign Bridge

Flutter ASL prototype. Text-to-sign vocabulary and gloss processing run locally.

## Phase 2: vocabulary and gloss engine

The starter lexicon is in `assets/packs/asl/`. The app seeds these CSV files into
SQLite on its first launch. `RuleGlossEngine` uses the database-backed lexicon
for phrase matching, word lookup, synonyms, irregular verbs, and fingerspelling.
Its deterministic rules provide a simplified gloss, not full ASL grammar.

To build a lexicon from local text-only datasets (no videos are needed):

```powershell
python tools/vocab/build_lexicon.py `
  --wlasl C:\datasets\wlasl-glosses.json `
  --sentences C:\datasets\how2sign-sentences.csv `
  --word-frequency C:\datasets\word-frequency.txt
```

Check dataset licences before use. The generated `lexicon_seed.csv` and
`clips_needed.txt` go into `assets/packs/asl/`. Phrases and synonyms are
hand-authored in their CSV files.

Run the vocabulary script tests and Flutter checks with:

```powershell
python -m unittest discover -s tools\vocab -p test_*.py
flutter analyze
flutter test
```

## Phase 3: avatar playback

`MockPlayer` plays the clip names and durations in `assets/avatar/manifest.json`.
Use it while the Blender model is being prepared. `GlbPlayer` uses a local
WebView and bundled `model-viewer` script, so playback does not need a CDN or
internet access.

To enable the GLB player, add `avatar.glb` to `assets/avatar/` and make each
animation name match a manifest clip name (for example, `HELLO`). The app uses
the GLB player when that file is present; otherwise, it uses label-only
playback. Some ASL clips are not in the sample manifest yet, so the mock player
shows their labels with a short fallback duration.

The Text-to-Sign screen translates typed text, offers quick phrases, plays the
clip sequence, and saves each successful translation locally. The History tab
shows the latest 50 translations and can replay them.

`model-viewer.min.js` is from Google Model Viewer 4.1.0; see
`LICENSE.model-viewer` for its license.

## Phase 8: release polish and accessibility

The project is now structured for the final polish pass required before
release:

- Local-first UX: translation, library browsing, sign history, and avatar
  playback work without internet access.
- Accessibility: touch targets follow the planned 44dp minimum, UI text remains
  readable with sufficient contrast, and icon labels are paired with clear text.
- Theme support: the settings screen persists a Light/Dark preference and the app
  immediately applies it across the main navigation shell.
- Privacy and consent: the onboarding and privacy screens document the local-only
  defaults, and optional online features stay behind explicit consent flows.
- Release checks: run `flutter analyze` and `flutter test` before shipping, and
  verify the app on Android device hardware with the light/dark mode and offline
  paths exercised once.

Suggested release build flow:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

This keeps the project aligned with the Phase 8 plan while preserving the
prototype's offline-first, beginner-friendly implementation.