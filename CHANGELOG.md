# Changelog

All notable changes to HaptiX are documented here.

## [1.0.2] — 2026-04-28

### Added
- iOS 13.0 – 17.0 support: deployment target lowered from iOS 15.0 to iOS 13.0 in both `Makefile` targets.
- Rootful jailbreak support: preferences reset path resolved dynamically at runtime — detects `/var/jb` presence to choose between rootless and rootful path layouts, eliminating the hardcoded `/var/jb` prefix.
- Dual-package CI pipeline: `.github/workflows/build.yml` now produces two `.deb` artifacts per run — one rootless (`THEOS_PACKAGE_SCHEME=rootless`) and one rootful (scheme unset), staged to `dist/` with `-rootless` / `-rootful` suffixes. Both are uploaded as artifacts and attached to tagged GitHub Releases.

### Changed
- `control` description updated to reflect iOS 13–17 range and dual-package availability.
- `haptixprefs/Resources/Info.plist` `MinimumOSVersion` lowered from `15.0` to `13.0`.
- `depiction.json` compatibility field updated to `iOS 13.0 – 17.0`; architecture field updated to `iphoneos-arm64 (Rootless + Rootful)`.

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
