# Changelog

All notable changes to HaptiX are documented here.

## [1.0.1] — 2026-04-28

### Fixed
- Cooldown threshold corrected from 80ms to 50ms, matching documented behavior.
- Replaced `AudioServicesPlaySystemSound(1520)` with `UIImpactFeedbackGenerator` to match the iOS 16 native API advertised in the README.
- Corrected `control` file version from `3.0.0` to `1.0.1`; removed non-existent "Overdrive mode" from package description.
- Audited and resolved AltList per-app blacklist key storage mismatch between `Root.plist` (`blacklistedApps`) and `Tweak.x` preference reader.

### Added
- Five configurable Taptic Engine profiles: Light, Medium, Heavy, Soft, Rigid — selectable from Settings.
- `hapticStyle` integer preference key read via `readIntegerPref()` in `loadPrefs()`.
- `PSListItemsCell` specifier in `Root.plist` for the profile selector.
- `depiction.json` — native Sileo/Zebra package depiction page.
- `ProjectStructure.md` — annotated file tree with injection/hooking architecture overview.
- `CHANGELOG.md` — this file.
- Tag-triggered GitHub Release publishing in `.github/workflows/build.yml`.
- `pull_request` CI trigger added to build workflow.

### Changed
- `README.md` fully rewritten to accurately reflect the v1.0.1 implementation.
- Removed `AudioToolbox` from `HaptiX_FRAMEWORKS` in root `Makefile`.
- `build.yml` updated to trigger on PRs and version tags in addition to `main` pushes.
