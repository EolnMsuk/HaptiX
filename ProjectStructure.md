# HaptiX — Project Structure

## Injection & Hooking Architecture

HaptiX is a MobileSubstrate (Substitute/libhooker) dylib that is injected by the jailbreak's process-injection daemon (bootstrapd / substrated) into every process whose bundle ID matches the filter declared in `HaptiX.plist`. The filter specifies `com.apple.UIKit` (catches all UIKit-linked apps) and `com.apple.springboard` (the home screen process).

At runtime the Logos `%ctor` constructor fires immediately after injection. It calls `loadPrefs()` to read the user's preferences via `CFPreferencesCopyAppValue`, which bypasses the app sandbox by communicating directly with `cfprefsd`. A Darwin notification observer is then registered on the `com.eolnmsuk.haptix/ReloadPrefs` channel so that changes made in Settings are applied live without a respring.

Two Logos `%group` blocks partition the hooks:

- **UIKitHooks** — installed unconditionally in every injected process. Hooks `UIKeyboardImpl`, `UIControl`, `UISwitch`, `UITableViewCell`, and `UIScrollView`.
- **SpringBoardHooks** — installed only when `bundleIdentifier == com.apple.springboard`. Hooks `SBVolumeControl`, `SBLockHardwareButton`, `SBLockScreenManager`, `SBIconView`, `SBHomeGesturePanGestureRecognizer`, and `SBFluidSwitcherViewController`.

Haptic feedback is delivered via `UIImpactFeedbackGenerator` on the main queue. A 50ms time-gate (`lastHapticTime`) prevents the Taptic Engine from double-firing when rapid sequential UI events occur.

The preferences bundle (`haptixprefs`) is a separate compiled target installed to `/Library/PreferenceBundles/haptixprefs.bundle`. PreferenceLoader discovers it via the `entry.plist` copied to `/Library/PreferenceLoader/Preferences/HaptiX.plist` by the root `Makefile`'s `internal-stage::` hook.

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
├── Makefile                         # Root build; TARGET=iphone:clang:16.5:13.0;
│                                    # THEOS_PACKAGE_SCHEME=rootless (default, overridable);
│                                    # internal-stage:: copies entry.plist
│
├── HaptiX.plist                     # Substrate filter: com.apple.UIKit +
│                                    # com.apple.springboard
│
├── control                          # Debian package metadata (version, deps, arch)
├── depiction.json                   # Sileo/Zebra native depiction page
├── plan.md                          # v1.0.1 remediation roadmap
├── CHANGELOG.md                     # Version history
├── ProjectStructure.md              # This file
├── README.md                        # User-facing documentation
├── LICENSE                          # License terms
├── CLAUDE.md                        # Claude Code project instructions
│
├── haptixprefs/                     # PreferenceBundle target
│   ├── Makefile                     # BUNDLE_NAME=haptixprefs; links AltList via -F../vendor
│   ├── entry.plist                  # PreferenceLoader entry point (copied to
│   │                                # /Library/PreferenceLoader/Preferences/ at build)
│   ├── HaptixPrefsRootListController.h
│   ├── HaptixPrefsRootListController.m  # resetSettings() — deletes plist; posts ReloadPrefs
│   └── Resources/
│       ├── Info.plist               # Bundle metadata for the PreferenceBundle
│       └── Root.plist               # Declarative Settings UI (PSSpecifiers):
│                                    # enabled, hapticStyle (5 profiles), 10 hook toggles,
│                                    # AltList exclusion list, Reset button
│
├── vendor/
│   └── AltList.framework/           # Vendored; linked only by haptixprefs
│       ├── AltList                  # Framework binary (arm64)
│       ├── Info.plist
│       ├── Headers/                 # Public Objective-C headers
│       │   ├── ATLApplicationListMultiSelectionController.h
│       │   ├── ATLApplicationListSelectionController.h
│       │   ├── ATLApplicationListControllerBase.h
│       │   ├── ATLApplicationListSubcontroller.h
│       │   ├── ATLApplicationListSubcontrollerController.h
│       │   ├── ATLApplicationSection.h
│       │   ├── ATLApplicationSelectionCell.h
│       │   ├── ATLApplicationSubtitleCell.h
│       │   ├── ATLApplicationSubtitleSwitchCell.h
│       │   └── LSApplicationProxy+AltList.h
│       └── *.lproj/                 # Localizations (ar, de, en, fr, it, ja, ko,
│                                    # nl, pl, pt, ru, sk, tr, zh, zh-Hant)
│
└── .github/
    └── workflows/
        └── build.yml                # GitHub Actions: Theos setup → rootless build
                                     # → rootful build → upload both .deb artifacts
```
