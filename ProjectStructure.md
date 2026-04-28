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

| Package | Makefile | `THEOS_PACKAGE_SCHEME` | `ARCHS` | AltList | Target |
|---------|----------|------------------------|---------|---------|--------|
| `-rootless.deb` | `Makefile` | `rootless` | arm64 + arm64e | New (`vendor/AltList.framework`) | Dopamine 2, RootHide, palera1n (rootless) |
| `-rootful.deb` | `Makefile` | *(unset)* | arm64 + arm64e | New (`vendor/AltList.framework`) | palera1n (rootful) |
| `-rootful-legacy.deb` | `Makefile.legacy` | *(unset, exported)* | arm64 only | Legacy (`vendor/AltList_Old.framework`) | Checkra1n, unc0ver, Electra |

`Makefile.legacy` sets `ARCHS = arm64` (before `common.mk`) and exports `THEOS_PACKAGE_SCHEME =` (empty = rootful), `ALTLIST_FRAMEWORK_SEARCH_PATH = ../vendor/legacy`, and `ARCHS` into the sub-make environment. Restricting to arm64 is correct — iOS 13–14 legacy jailbreaks target A8–A11 (arm64) devices, and the Theos toolchain cannot produce valid arm64e binaries for iOS < 14.0.

Theos's `aggregate.mk` propagates the root `-f Makefile.legacy` flag to every subproject sub-make (via `$(firstword $(MAKEFILE_LIST))`), so `haptixprefs/Makefile.legacy` must also exist. Both prefs Makefiles use `?=` for `THEOS_PACKAGE_SCHEME` and `ALTLIST_FRAMEWORK_SEARCH_PATH` so they inherit the exported values.

The CI "Prepare Legacy AltList Framework" step copies `vendor/AltList_Old.framework` to `vendor/legacy/AltList.framework` and then runs `lipo -remove arm64e` on the binary. `AltList_Old.framework/AltList` contains an arm64e slice whose slice data uses the old ABI (`arm64e.old`) but whose fat-header entry is labeled `arm64e`. Xcode 15/16 linkers validate all fat-header entries before extracting any slice, so even an arm64-only link step hard-errors on the mismatch; stripping the slice before building avoids this. The main `vendor/AltList.framework` is never modified.

After each build, `rm -f packages/*.deb` runs alongside `make clean` because Theos does not remove `packages/` on clean, and accumulated `.deb` files from prior builds would cause the glob staging step to fail.

The workflow also extracts the version from `control`, creates a matching git tag, and opens a draft GitHub Release on every push to `main`.

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
├── Makefile                         # Root build for rootless + rootful packages;
│                                    # THEOS_PACKAGE_SCHEME=rootless (default);
│                                    # internal-stage:: copies entry.plist
│
├── Makefile.legacy                  # Root build for rootful-legacy package;
│                                    # ARCHS=arm64; exports THEOS_PACKAGE_SCHEME=
│                                    # (rootful), ALTLIST_FRAMEWORK_SEARCH_PATH=
│                                    # ../vendor/legacy, and ARCHS so haptixprefs
│                                    # sub-make inherits all three
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
│   │                                # THEOS_PACKAGE_SCHEME ?= rootless
│   │                                # ALTLIST_FRAMEWORK_SEARCH_PATH ?= ../vendor
│   │                                # Both use ?= so parent exports override them
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
│   ├── AltList.framework/           # New AltList — arm64 + arm64e universal;
│   │                                # default for rootless and rootful builds
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
│   ├── AltList_New.framework/       # Explicit copy of new AltList; kept for
│   │                                # reference — same architecture set as above
│   │
│   └── AltList_Old.framework/       # Legacy AltList — armv7 + arm64 + arm64e
│                                    # universal (arm64e slice uses old ABI /
│                                    # arm64e.old, which causes fat-header mismatch
│                                    # errors on Xcode 15/16 linkers). CI strips the
│                                    # arm64e slice via lipo before linking.
│                                    # Required for iOS 13–14 rootful legacy builds.
│
└── .github/
    └── workflows/
        └── build.yml                # GitHub Actions: Theos setup → rootless build
                                     # → rootful build → legacy rootful build
                                     # (lipo strips arm64e from AltList_Old before
                                     # linking) → upload 3 .deb artifacts →
                                     # create draft release with auto-tag from
                                     # control version
```
