# Changelog

All notable changes to HaptiX are documented here.

## [1.0.3] — 2026-04-28

### Build
- **Three-package CI pipeline**: `build.yml` now produces three `.deb` artifacts per run — `HaptiX-{version}-rootless.deb` (iOS 15+, new AltList), `HaptiX-{version}-rootful.deb` (iOS 15+, new AltList), and `HaptiX-{version}-rootful-legacy.deb` (iOS 13–14, legacy AltList). All three are uploaded as artifacts and attached to each draft GitHub Release with a selection table.
- **Auto-tagging and draft releases**: `build.yml` extracts the version from `control` at build time, creates a matching git tag, and opens a draft GitHub Release on every push to `main`. No manual tag push required. The draft body contains a plain-language table and decision guide for choosing the correct `.deb`.
- **Package directory cleanup**: Added `rm -f packages/*.deb` alongside every `make clean` step. Theos's `make clean` does not remove `packages/`; without this the `cp packages/*.deb dist/…` glob accumulates `.deb` files from prior builds and fails on the second and third package.
- **`Makefile.legacy`**: New root-level Makefile for the legacy rootful build. Sets `THEOS_PACKAGE_SCHEME =` (rootful) and exports both `THEOS_PACKAGE_SCHEME` and `ALTLIST_FRAMEWORK_SEARCH_PATH = ../vendor/legacy` so `haptixprefs/Makefile` inherits the correct scheme and framework path through the sub-make without any in-place framework file swapping.
- **`haptixprefs/Makefile`**: `THEOS_PACKAGE_SCHEME = rootless` changed to `?=` (conditional assignment) so the value is inherited from a parent export or command-line override instead of being hardcoded. Added `ALTLIST_FRAMEWORK_SEARCH_PATH ?= ../vendor` using the same pattern — defaults to the new AltList framework; overridden to `../vendor/legacy` when `Makefile.legacy` is the entry point.

### Fixed
- **Reset button** (`resetSettings`): Replaced `NSFileManager removeItemAtPath:` with the CFPreferences API (`CFPreferencesCopyKeyList` → `CFPreferencesSetAppValue(key, NULL, domain)` → `CFPreferencesAppSynchronize`). The old file-deletion approach left cfprefsd's in-memory cache intact, so `reloadSpecifiers` re-displayed stale values. The new approach removes keys through the daemon, flushing both the cache and the backing plist atomically. Also inherently rootless/rootful agnostic — no `/var/jb` path detection required.
- **Feedback Style cell**: Added missing `<key>detail</key><string>PSListItemsController</string>` to the `PSListItemsCell` specifier in `Root.plist`. Without this key the Preferences framework had no controller to push, rendering the cell as an inert grey label with no selectable options.

### Added
- **Adaptive settings banner**: `viewDidLoad` in `HaptixPrefsRootListController.m` now installs a `UIImageView` as `tableHeaderView` above all specifiers. Loads `banner.png` (Dark Mode) or `banner2.png` (Light Mode) from the bundle using `pathForResource:ofType:` (explicit file path, not asset catalog). Height is computed from the image's natural aspect ratio relative to the screen width so it scales correctly on all device sizes. `traitCollectionDidChange:` swaps the image live whenever the user switches appearance — no relaunch required. Place `banner.png` and `banner2.png` in `haptixprefs/Resources/`.
- **Settings app icon**: Added `<key>icon</key><string>icon.png</string>` to `haptixprefs/entry.plist`. PreferenceLoader resolves this relative to the bundle resources directory and scales for `@2x`/`@3x` variants automatically. Place `icon.png` (29×29), `icon@2x.png` (58×58), and `icon@3x.png` (87×87) in `haptixprefs/Resources/`.
- **Sileo/Zebra package icon**: Added `Icon:` field to `control` pointing to `icon@2x.png` on GitHub. Package managers derive this from the repository's `Packages` index.
- **Sileo depiction icon**: Populated `headerImage` and added `packageIcon` in `depiction.json`, both referencing `icon@2x.png` on GitHub. Place a 512×512 `icon@2x.png` in the repository root and push to the `main` branch.

### Documentation
- `README.md`: Added **⚠️ Required iOS Settings** section clarifying that System Haptics must be **ON** and Keyboard Feedback → Haptic must be **ON** (when the keyboard hook is enabled). Added targeted troubleshooting bullets for both scenarios. Corrected a misleading tip that instructed users to disable Apple's native keyboard haptics (the opposite of what is required).
- `COMPATIBILITY.md`: Added **Required iOS Settings** table under System Conflicts marking System Haptics as **REQUIRED — ON** and Keyboard Feedback → Haptic as **REQUIRED — ON** (for the keyboard hook). Corrected the prior table row that labelled System Haptics as optional.

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
