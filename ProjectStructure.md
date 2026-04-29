# HaptiX — Project Structure

## Injection & Hooking Architecture

HaptiX is a MobileSubstrate (Substitute/libhooker/ElleKit) dylib that is injected by the jailbreak's process-injection daemon into every process whose bundle ID matches the filter declared in `HaptiX.plist`. The filter specifies `com.apple.UIKit` (catches all UIKit-linked apps) and `com.apple.springboard` (the home screen process).

At runtime the Logos `%ctor` constructor fires immediately after injection. It calls `loadPrefs()` to read the user's preferences via `CFPreferencesCopyAppValue`, which bypasses the app sandbox by communicating directly with `cfprefsd`. A Darwin notification observer is then registered on the `com.eolnmsuk.haptix/ReloadPrefs` channel so that changes made in Settings are applied live without a respring.

Two Logos `%group` blocks partition the hooks:

- **UIKitHooks** — installed unconditionally in every injected process. Hooks `UIKeyboardImpl`, `UIControl`, `UISwitch`, `UITableViewCell`, and `UIScrollView`.
- **SpringBoardHooks** — installed only when `bundleIdentifier == com.apple.springboard`. Hooks `SBVolumeControl`, `SBLockHardwareButton`, `SBLockScreenManager`, `SBIconView`, `SBHomeGesturePanGestureRecognizer`, and `SBFluidSwitcherViewController`.

Haptic feedback is delivered via `UIImpactFeedbackGenerator` on the main queue. A 50ms time-gate (`lastHapticTime`) prevents the Taptic Engine from double-firing when rapid sequential UI events occur.

The preferences bundle (`haptixprefs`) is a separate compiled target installed to `/Library/PreferenceBundles/haptixprefs.bundle`. PreferenceLoader discovers it via the `entry.plist` copied to `/Library/PreferenceLoader/Preferences/HaptiX.plist` by the root `Makefile`'s `internal-stage::` hook.

---

## Build System & CI Pipeline

Three `.deb` packages are produced per CI run by `.github/workflows/build.yml`:

| Package | `THEOS_PACKAGE_SCHEME` | `ARCHS` | AltList | Target |
|---------|------------------------|---------|---------|--------|
| `_iphoneos-arm.deb` (rootful) | *(unset)* | arm64 + arm64e | New (`vendor/AltList.framework`) | palera1n (rootful) |
| `_iphoneos-arm64.deb` (rootless) | `rootless` | arm64 + arm64e | New (`vendor/AltList.framework`) | Dopamine 2, RootHide, palera1n (rootless) |
| `_iphoneos-arm_legacy.deb` (legacy rootful) | *(unset)* | arm64 only | Old (swapped in-place) | Checkra1n, unc0ver, Electra |

CI is split into two parallel jobs: `build-modern` produces both rootful and rootless `.deb` files (iOS 15+, SDK 16.5); `build-legacy` produces the iOS 13–14 `.deb` (SDK 14.5). A `release` job waits on both via `needs:`, collects the artifacts, and opens a draft GitHub Release tagged `v{VERSION}-b{RUN_NUMBER}`.

All three builds use the root `Makefile` — `TARGET` and `ARCHS` are passed as CLI overrides. `Makefile.legacy` is provided only for local development convenience; CI always uses explicit CLI args.

The `build-legacy` job (and `build_all.sh` locally) swaps `vendor/AltList.framework` in-place: it copies `vendor/AltList_Old.framework` over `vendor/AltList.framework`, then runs `lipo -thin arm64` to produce an arm64-only binary. `AltList_Old.framework/AltList` contains an arm64e slice whose fat-header entry is labeled `arm64e` but whose slice data uses the old ABI (`arm64e.old`). Xcode 15/16 linkers validate all fat-header entries before extracting any slice, so even an arm64-only link hard-errors on the mismatch; `lipo -thin arm64` avoids this by discarding every other slice. `vendor/AltList.framework` is restored from `vendor/AltList_New.framework` after the legacy build completes.

Restricting the legacy build to `ARCHS="arm64"` is correct — iOS 13–14 legacy jailbreaks target A8–A11 (arm64) devices, and the Theos toolchain cannot produce valid arm64e binaries for iOS < 14.0.

`haptixprefs/Makefile` uses `-F$(THEOS_PROJECT_DIR)/vendor` hardcoded for the AltList framework search path. Because the vendor swap replaces the binary at that path in-place, all three builds resolve to the correct AltList binary without any per-build path variable. No `THEOS_PACKAGE_SCHEME` or `ALTLIST_FRAMEWORK_SEARCH_PATH` variables exist in any Makefile.

Theos's `aggregate.mk` propagates the root `-f Makefile.legacy` flag to every subproject sub-make (via `$(firstword $(MAKEFILE_LIST))`), so `haptixprefs/Makefile.legacy` must also exist when using `make -f Makefile.legacy` locally. Both prefs Makefiles are identical.

After each build, `rm -rf packages/*` runs alongside `make clean` because Theos does not remove `packages/` on clean, and accumulated `.deb` files from prior builds would cause the glob staging step to fail.

---

## File Tree

```
HaptiX/
│
├── Tweak.x                          # All hook logic, prefs loading, haptic engine
│   ├── readBoolPref() / readIntegerPref()  # Sandbox-bypassing CFPreferences readers
│   ├── loadPrefs()                  # Reads all pref keys; sets isBlacklisted
│   ├── triggerHaptic()              # UIImpactFeedbackGenerator dispatch; 50ms gate
│   ├── %group UIKitHooks            # UIKit process hooks (all injected apps)
│   └── %group SpringBoardHooks      # SpringBoard-only hardware hooks
│
├── Makefile                         # Root build; exports ARCHS ?= arm64 arm64e
│                                    # and TARGET ?= iphone:clang:16.5:15.0;
│                                    # no THEOS_PACKAGE_SCHEME default (rootful
│                                    # by absence); internal-stage:: copies entry.plist
│
├── Makefile.legacy                  # Root build for legacy package (local use);
│                                    # exports ARCHS ?= arm64 and
│                                    # TARGET ?= iphone:clang:14.5:13.0;
│                                    # no THEOS_PACKAGE_SCHEME (rootful by absence);
│                                    # requires in-place vendor swap before use
│
├── build_all.sh                     # Local full build script; mirrors CI exactly:
│                                    # swaps AltList in-place, builds all 3 .deb
│                                    # packages, restores vendor/AltList.framework
│
├── HaptiX.plist                     # Substrate filter: com.apple.UIKit +
│                                    # com.apple.springboard
│
├── control                          # Debian package metadata (version, deps, arch)
├── depiction.json                   # Sileo/Zebra native depiction page
├── icon@2x.png                      # 512×512 repo-root icon for Sileo depiction
│                                    # and package manager listing (referenced in
│                                    # control Icon: field and depiction.json)
├── LICENSE                          # Project license
├── CHANGELOG.md                     # Version history
├── COMPATIBILITY.md                 # Device/jailbreak matrix, conflict guide
├── ProjectStructure.md              # This file
├── README.md                        # User-facing documentation
├── CLAUDE.md                        # Claude Code project instructions
│
├── haptixprefs/                     # PreferenceBundle target
│   ├── Makefile                     # BUNDLE_NAME=haptixprefs;
│   │                                # -F$(THEOS_PROJECT_DIR)/vendor for AltList;
│   │                                # TARGET ?= iphone:clang:16.5:13.0 (overridable)
│   ├── Makefile.legacy              # Identical to Makefile; required because Theos
│   │                                # aggregate.mk re-passes -f <name> to sub-makes,
│   │                                # so make -f Makefile.legacy at root causes Theos
│   │                                # to invoke make -f Makefile.legacy in haptixprefs/
│   ├── entry.plist                  # PreferenceLoader entry point (copied to
│   │                                # /Library/PreferenceLoader/Preferences/ at build)
│   ├── HaptixPrefsRootListController.h
│   ├── HaptixPrefsRootListController.m  # resetSettings() — clears prefs via
│   │                                    # CFPreferences API; posts ReloadPrefs notify;
│   │                                    # viewDidLoad installs adaptive banner header;
│   │                                    # traitCollectionDidChange: swaps banner live
│   └── Resources/
│       ├── Info.plist               # Bundle metadata for the PreferenceBundle
│       ├── Root.plist               # Declarative Settings UI (PSSpecifiers):
│       │                            # enabled, hapticStyle (5 profiles), 10 hook
│       │                            # toggles, AltList exclusion list, Reset button
│       ├── icon.png                 # Settings app icon — 29×29 (@1x)
│       ├── icon@2x.png              # Settings app icon — 58×58 (@2x)
│       ├── icon@3x.png              # Settings app icon — 87×87 (@3x)
│       ├── iconRaw.png              # Uncompressed source for icon variants
│       ├── banner.png               # Settings pane header — Dark Mode
│       ├── banner2.png              # Settings pane header — Light Mode
│       ├── bannerRaw.png            # Uncompressed source for banner.png
│       └── banner2Raw.png           # Uncompressed source for banner2.png
│
├── vendor/
│   ├── AltList.framework/           # Active AltList for current build; swapped
│   │                                # in-place by CI and build_all.sh — new AltList
│   │                                # for rootful/rootless, Old (stripped) for legacy
│   │   ├── AltList                  # Framework binary
│   │   ├── Info.plist
│   │   ├── Headers/                 # Public Objective-C headers
│   │   │   ├── ATLApplicationListMultiSelectionController.h
│   │   │   ├── ATLApplicationListSelectionController.h
│   │   │   ├── ATLApplicationListControllerBase.h
│   │   │   ├── ATLApplicationListSubcontroller.h
│   │   │   ├── ATLApplicationListSubcontrollerController.h
│   │   │   ├── ATLApplicationSection.h
│   │   │   ├── ATLApplicationSelectionCell.h
│   │   │   ├── ATLApplicationSubtitleCell.h
│   │   │   ├── ATLApplicationSubtitleSwitchCell.h
│   │   │   └── LSApplicationProxy+AltList.h
│   │   └── *.lproj/                 # Localizations (ar, de, en, fr, it, ja, ko,
│   │                                # nl, pl, pt, ru, sk, tr, zh, zh-Hant)
│   │
│   ├── AltList_New.framework/       # New AltList — arm64 + arm64e universal;
│   │                                # source for rootful/rootless builds; restored
│   │                                # to vendor/AltList.framework after legacy build
│   │
│   └── AltList_Old.framework/       # Legacy AltList — armv7 + arm64 + arm64e
│                                    # universal (arm64e slice uses old ABI /
│                                    # arm64e.old, causing fat-header mismatch on
│                                    # Xcode 15/16 linkers). CI and build_all.sh
│                                    # copy it in-place then run lipo -thin arm64
│                                    # to strip to arm64-only before linking.
│
└── .github/
    └── workflows/
        └── build.yml                # GitHub Actions: parallel build-modern job
                                     # (rootful + rootless, SDK 16.5) and
                                     # build-legacy job (iOS 13-14, SDK 14.5,
                                     # in-place AltList swap + lipo -thin arm64);
                                     # release job waits on both, uploads 3 .deb
                                     # artifacts, opens draft release
```
