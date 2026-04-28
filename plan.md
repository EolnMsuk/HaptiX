# HaptiX v1.0.1 — Remediation & Release Roadmap

## Audit Findings

The following discrepancies were found between `README.md` claims and the actual codebase. Each is cross-referenced to the task that resolves it.

| # | File | Claimed | Actual | Resolved by |
|---|------|---------|--------|-------------|
| 1 | `Tweak.x:66` | 50ms cooldown | 80ms (`0.08`) | Task 1 |
| 2 | `Tweak.x:71` | `UIImpactFeedbackGenerator` | `AudioServicesPlaySystemSound(1520)` | Task 2 |
| 3 | `Tweak.x` / `Root.plist` | 5 haptic profiles (Light/Medium/Heavy/Soft/Rigid) | None — single hardcoded sound | Task 2 & 3 |
| 4 | `README.md` | 3 trigger categories listed | 10 toggles implemented; SpringBoard hooks not documented | Task 10 |
| 5 | `control:4` | `Version: 3.0.0` | Target release is v1.0.1; "Overdrive mode" in description does not exist | Task 5 |
| 6 | `Root.plist:198` | `key: blacklistedApps` (PSLinkListCell) | `Tweak.x:56` reads top-level bundle ID keys — potential AltList storage mismatch | Task 4 |
| 7 | — | `depiction.json` expected by Sileo/Zebra | Missing | Task 6 |
| 8 | — | `CHANGELOG.md` | Missing | Task 8 |
| 9 | — | `ProjectStructure.md` | Missing | Task 7 |
| 10 | `README.md:39` | Valid clone URL | Placeholder `YOUR_USERNAME`; broken fenced code block | Task 10 |

---

## Task List

Tasks are sequential. Do not begin a task until its predecessor is complete and verified.

---

### Task 1 — Fix Cooldown: 80ms → 50ms

**File:** `Tweak.x`

In `triggerHaptic()` at line 66, change the cooldown threshold from `0.08` to `0.05`:

```objc
// Before
if (currentTime - lastHapticTime < 0.08) return;

// After
if (currentTime - lastHapticTime < 0.05) return;
```

Also update the inline comment at line 64 to read:
```objc
// 50ms cooldown eliminates the "tick tick" double-fire glitch
```

**Verification:** `grep -n "0.05" Tweak.x` must return line 66.

---

### Task 2 — Replace AudioToolbox with UIImpactFeedbackGenerator

**File:** `Tweak.x`

This is the largest single refactor. The goal is to replace the legacy `AudioServicesPlaySystemSound(1520)` call with Apple's `UIImpactFeedbackGenerator`, and to make the feedback style user-configurable via a new `hapticStyle` preference integer (0–4).

#### 2a — Remove the AudioToolbox import

Delete this line:
```objc
#import <AudioToolbox/AudioToolbox.h>
```

#### 2b — Add a hapticStyle preference variable

In the preferences variables block (after `isBlacklisted`), add:
```objc
static NSInteger hapticStyle = 0; // 0=Light 1=Medium 2=Heavy 3=Soft 4=Rigid
```

#### 2c — Read hapticStyle in loadPrefs()

Add a reader for the new integer key. Because `CFPreferencesCopyAppValue` returns a `CFPropertyListRef`, cast it to `NSNumber` the same way `readBoolPref` does:

```objc
static NSInteger readIntegerPref(NSString *key, NSInteger fallback) {
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key, CFSTR("com.eolnmsuk.haptix"));
    if (value) {
        NSInteger result = [(__bridge NSNumber *)value integerValue];
        CFRelease(value);
        return result;
    }
    return fallback;
}
```

Add a call inside `loadPrefs()`:
```objc
hapticStyle = readIntegerPref(@"hapticStyle", 0);
```

#### 2d — Rewrite triggerHaptic()

Replace the entire body of `triggerHaptic()`. The generator must be instantiated on the main thread. Map `hapticStyle` to the corresponding `UIImpactFeedbackStyle`:

```objc
static void triggerHaptic() {
    if (!enabled || isBlacklisted) return;

    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime - lastHapticTime < 0.05) return;
    lastHapticTime = currentTime;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackStyle style;
        switch (hapticStyle) {
            case 1:  style = UIImpactFeedbackStyleMedium; break;
            case 2:  style = UIImpactFeedbackStyleHeavy;  break;
            case 3:  style = UIImpactFeedbackStyleSoft;   break;
            case 4:  style = UIImpactFeedbackStyleRigid;  break;
            default: style = UIImpactFeedbackStyleLight;  break;
        }
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
        [gen prepare];
        [gen impactOccurred];
    });
}
```

`UIImpactFeedbackStyleSoft` and `UIImpactFeedbackStyleRigid` are available on iOS 13+. Our deployment minimum is iOS 15.0, so no `@available` guard is required.

#### 2e — Remove AudioToolbox from the root Makefile

In `Makefile`, remove `AudioToolbox` from `HaptiX_FRAMEWORKS`:

```makefile
# Before
HaptiX_FRAMEWORKS = UIKit AudioToolbox

# After
HaptiX_FRAMEWORKS = UIKit
```

**Verification:** `grep -n "AudioServices\|AudioToolbox" Tweak.x Makefile` must return zero results.

---

### Task 3 — Add Haptic Profile Selector to Root.plist

**File:** `haptixprefs/Resources/Root.plist`

Insert a new `PSGroupCell` labelled `"Haptic Profile"` and a `PSListItemsCell` specifier immediately after the `"Global Settings"` group (after the `enabled` switch specifier, before the `"Hardware & System"` group).

The specifier:
```xml
<dict>
    <key>cell</key>
    <string>PSGroupCell</string>
    <key>label</key>
    <string>Haptic Profile</string>
    <key>footerText</key>
    <string>Controls the intensity and character of feedback from the Taptic Engine.</string>
</dict>
<dict>
    <key>cell</key>
    <string>PSListItemsCell</string>
    <key>defaults</key>
    <string>com.eolnmsuk.haptix</string>
    <key>key</key>
    <string>hapticStyle</string>
    <key>label</key>
    <string>Feedback Style</string>
    <key>default</key>
    <integer>0</integer>
    <key>validValues</key>
    <array>
        <integer>0</integer>
        <integer>1</integer>
        <integer>2</integer>
        <integer>3</integer>
        <integer>4</integer>
    </array>
    <key>validTitles</key>
    <array>
        <string>Light</string>
        <string>Medium</string>
        <string>Heavy</string>
        <string>Soft</string>
        <string>Rigid</string>
    </array>
    <key>PostNotification</key>
    <string>com.eolnmsuk.haptix/ReloadPrefs</string>
</dict>
```

**Verification:** Open the plist in a plist viewer or run `plutil -lint haptixprefs/Resources/Root.plist`.

---

### Task 4 — Audit and Fix AltList Blacklist Key Handling

**File:** `Tweak.x` and `haptixprefs/Resources/Root.plist`

There is a structural mismatch that must be resolved before shipping.

**The issue:** `Root.plist` declares the `ATLApplicationListMultiSelectionController` specifier with `key: blacklistedApps`. AltList's multi-selection controller stores each selected app as a top-level boolean in the preferences domain, keyed by bundle identifier (e.g., `com.example.app = YES`). However, the `key` field in the PSLinkListCell specifier may cause AltList to nest those booleans inside a sub-dictionary under `blacklistedApps` rather than at the top level, depending on the AltList version.

**Resolution steps:**

1. Read `vendor/AltList.framework/Headers/ATLApplicationListMultiSelectionController.h` and `ATLApplicationListControllerBase.h` to determine whether AltList stores values at the top level or under a sub-dictionary key.

2. **If AltList stores values at the top level** (i.e., `key` in the specifier is unused for storage path): the current `Tweak.x` implementation (`readBoolPref(bundleID, NO)`) is correct. No change needed in `Tweak.x`.

3. **If AltList stores values as a sub-dictionary under `blacklistedApps`**: rewrite the blacklist check in `loadPrefs()` to read the nested dictionary:
   ```objc
   CFPropertyListRef dict = CFPreferencesCopyAppValue(CFSTR("blacklistedApps"), CFSTR("com.eolnmsuk.haptix"));
   if (dict) {
       NSDictionary *blacklist = (__bridge NSDictionary *)dict;
       NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
       isBlacklisted = bundleID ? [blacklist[bundleID] boolValue] : NO;
       CFRelease(dict);
   }
   ```

4. After resolving, add a comment above the blacklist check in `loadPrefs()` documenting which AltList storage model is in use.

---

### Task 5 — Update the control File

**File:** `control`

Make the following changes:

1. **Version:** `3.0.0` → `1.0.1`
2. **Description:** Remove the fabricated "Overdrive mode" reference. Replace with an accurate one-line summary:
   ```
   Description: System-wide haptic feedback tweak for iOS 16 rootless jailbreaks. Configurable profiles, per-app exclusions, and SpringBoard hardware button support.
   ```

The final `control` file must be:
```
Package: com.eolnmsuk.haptix
Name: HaptiX
Depends: mobilesubstrate, preferenceloader, com.opa334.altlist
Version: 1.0.1
Architecture: iphoneos-arm64
Description: System-wide haptic feedback tweak for iOS 16 rootless jailbreaks. Configurable profiles, per-app exclusions, and SpringBoard hardware button support.
Maintainer: eolnmsuk
Author: eolnmsuk
Section: Tweaks
```

Ensure there is **no trailing newline** after the last field and **no Windows line endings (CRLF)**. The existing `build.yml` already runs `dos2unix control` to guard against CRLF, but the source file should be clean.

---

### Task 6 — Generate depiction.json (Sileo / Zebra)

**File:** `depiction.json` (create at repo root)

Sileo and Zebra use a native depiction JSON to display the package detail page. Create `depiction.json` with the following structure. Replace `YOUR_SCREENSHOT_URL` placeholders before distributing:

```json
{
  "minVersion": "0.1",
  "headerImage": "",
  "tintColor": "#FF6B35",
  "tabs": [
    {
      "tabname": "Details",
      "views": [
        {
          "class": "DepictionMarkdownView",
          "markdown": "**HaptiX** delivers system-wide haptic feedback on iOS 16 rootless jailbreaks (Dopamine 2). Built on `UIImpactFeedbackGenerator` for clean, hardware-accelerated feedback with zero double-fire.",
          "useSpacing": true
        },
        {
          "class": "DepictionSeparatorView"
        },
        {
          "class": "DepictionHeaderView",
          "title": "Features"
        },
        {
          "class": "DepictionMarkdownView",
          "markdown": "- 5 Taptic Engine profiles: Light, Medium, Heavy, Soft, Rigid\n- 50ms cooldown gate prevents double-fire\n- SpringBoard hooks: Volume, Power, Lock/Unlock, Home Screen Icons, App Switcher\n- UIKit hooks: Keyboard, Buttons, Switches, Table Cells, Scroll edges\n- Per-app exclusion list via AltList\n- Hot-reload — no respring required when changing settings",
          "useSpacing": true
        },
        {
          "class": "DepictionSeparatorView"
        },
        {
          "class": "DepictionTableTextView",
          "title": "Version",
          "text": "1.0.1"
        },
        {
          "class": "DepictionTableTextView",
          "title": "Compatibility",
          "text": "iOS 15.0 – 16.x"
        },
        {
          "class": "DepictionTableTextView",
          "title": "Architecture",
          "text": "iphoneos-arm64 (Rootless)"
        },
        {
          "class": "DepictionTableTextView",
          "title": "Developer",
          "text": "eolnmsuk"
        }
      ]
    },
    {
      "tabname": "Changelog",
      "views": [
        {
          "class": "DepictionHeaderView",
          "title": "1.0.1"
        },
        {
          "class": "DepictionMarkdownView",
          "markdown": "- Initial public release\n- Replaced `AudioServicesPlaySystemSound` with `UIImpactFeedbackGenerator`\n- Fixed cooldown: 80ms → 50ms\n- Added 5 configurable haptic profiles\n- Corrected AltList blacklist integration",
          "useSpacing": true
        }
      ]
    }
  ]
}
```

Once the file is created, add a `Depiction` field to `control` pointing to the raw GitHub URL for this file after the repo is published.

---

### Task 7 — Generate ProjectStructure.md

**File:** `ProjectStructure.md` (create at repo root)

The file must open with a technical summary section, followed by a fully annotated ASCII tree. Use the template below; verify every path against the actual repo contents before writing.

```markdown
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

\`\`\`
HaptiX/
│
├── Tweak.x                          # All hook logic, prefs loading, haptic engine
│   ├── readBoolPref() / readIntegerPref()  # Sandbox-bypassing CFPreferences readers
│   ├── loadPrefs()                  # Reads all pref keys; sets isBlacklisted
│   ├── triggerHaptic()              # UIImpactFeedbackGenerator dispatch; 50ms gate
│   ├── %group UIKitHooks            # UIKit process hooks (all injected apps)
│   └── %group SpringBoardHooks      # SpringBoard-only hardware hooks
│
├── Makefile                         # Root build; TARGET=iphone:clang:16.5:15.0;
│                                    # THEOS_PACKAGE_SCHEME=rootless;
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
        └── build.yml                # GitHub Actions: Theos setup → make package
                                     # FINALPACKAGE=1 → upload .deb artifact
\`\`\`
```

---

### Task 8 — Improve .github/workflows/build.yml

**File:** `.github/workflows/build.yml`

The existing workflow is functional but lacks release publishing. Make the following additions:

1. **Add a `pull_request` trigger** so CI runs on PRs, not only on pushes to `main`.

2. **Add a tag-triggered release job** that publishes the `.deb` to GitHub Releases when a tag matching `v*` is pushed:

```yaml
on:
  push:
    branches: [ main ]
    tags:
      - 'v*'
  pull_request:
    branches: [ main ]
  workflow_dispatch:
```

3. **Add a `Release` step** after the artifact upload step, conditional on tag push:

```yaml
      - name: Create GitHub Release
        if: startsWith(github.ref, 'refs/tags/')
        uses: softprops/action-gh-release@v2
        with:
          files: ${{ github.workspace }}/packages/*.deb
          generate_release_notes: false
          body: "See CHANGELOG.md for details."
```

4. **Keep the existing `dos2unix` step** — it is required because Windows-authored files frequently introduce CRLF and will cause `make` to fail.

**Verification:** Validate the YAML with `python3 -c "import yaml, sys; yaml.safe_load(sys.stdin)" < .github/workflows/build.yml` on the build machine.

---

### Task 9 — Initialize CHANGELOG.md

**File:** `CHANGELOG.md` (create at repo root)

Use [Keep a Changelog](https://keepachangelog.com) format. The initial entry must cover all changes made during this remediation cycle:

```markdown
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
```

---

### Task 10 — Rewrite README.md

**File:** `README.md`

The current README contains fabricated API references, an incorrect cooldown value, an incomplete feature list, and broken Markdown. Replace the entire file with content that accurately describes the verified v1.0.1 codebase. The rewrite must:

1. **Correct the haptic engine description** — `UIImpactFeedbackGenerator`, not legacy `AudioServicesPlaySystemSound`.
2. **State 50ms cooldown**, not 80ms.
3. **List all 5 haptic profiles** with accurate names (`UIImpactFeedbackStyle*` mapping in parentheses).
4. **List all trigger categories** — both UIKit (Keyboard, Buttons, Switches, Table Cells, Scroll Edge) and SpringBoard (Volume, Power, Lock/Unlock, Homescreen Icons, App Switcher/Gestures).
5. **Fix the Git clone code block** — use a working, properly terminated fenced block with `YOUR_USERNAME` replaced by the actual GitHub username (`EolnMsuk`).
6. **Document the haptic profile setting** under the Configuration section.
7. **Add a Compatibility note for RootHide** (change `control` Architecture to `iphoneos-arm64e`).
8. **Remove the broken Markdown link** in the clone example.
9. **Remove all placeholder text** (`YOUR_USERNAME`, `YOUR_SCREENSHOT_URL`).

Suggested structure:
```
# HaptiX

## Features
## Haptic Profiles
## Compatibility
## Building & Installation
  - Prerequisites
  - Local Compilation
  - GitHub Actions
## Configuration
## Troubleshooting
## Credits
```

---

## Completion Checklist

Run this checklist after all tasks are done, before tagging `v1.0.1`:

- [ ] `grep -n "0.08\|AudioServices\|AudioToolbox\|3.0.0\|Overdrive" Tweak.x Makefile control` — zero results
- [ ] `grep -n "0.05" Tweak.x` — returns the cooldown line
- [ ] `grep -n "UIImpactFeedbackGenerator" Tweak.x` — returns at least 2 lines
- [ ] `plutil -lint haptixprefs/Resources/Root.plist` — exits 0
- [ ] `grep -n "hapticStyle" haptixprefs/Resources/Root.plist Tweak.x` — at least 2 results each
- [ ] `control` Version field is `1.0.1`
- [ ] `depiction.json` exists at repo root and is valid JSON (`python3 -m json.tool depiction.json`)
- [ ] `ProjectStructure.md` exists at repo root
- [ ] `CHANGELOG.md` exists at repo root with a `[1.0.1]` entry dated `2026-04-28`
- [ ] `README.md` contains no occurrences of `AudioServicesPlaySystemSound`, `80ms`, `YOUR_USERNAME`, or `3.0.0`
- [ ] `make package` succeeds locally (or GitHub Actions CI passes)
