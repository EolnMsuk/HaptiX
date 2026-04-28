# HaptiX — Compatibility Matrix

---

## Supported iOS Versions

| Field | Value | Source |
|-------|-------|--------|
| Minimum deployment target | iOS 13.0 | `TARGET := iphone:clang:16.5:13.0` in root `Makefile` |
| Maximum tested | iOS 17.0 | SDK 16.5; tested across rootless and rootful environments |
| Haptic API minimum | iOS 10.0 | `UIImpactFeedbackGenerator` available since iOS 10; Soft/Rigid styles require iOS 13+ |

HaptiX is compiled against the iOS 16.5 SDK with a deployment floor of iOS 13.0. All five `UIImpactFeedbackGenerator` styles (Light, Medium, Heavy, Soft, Rigid) are available on iOS 13+, safely above the floor. The UIKit hooks (`UIKeyboardImpl`, `UIControl`, `UISwitch`, `UITableViewCell`, `UIScrollView`) are stable across iOS 13–17. SpringBoard private class hooks (`SBVolumeControl`, `SBLockHardwareButton`, `SBLockScreenManager`, `SBIconView`, `SBHomeGesturePanGestureRecognizer`, `SBFluidSwitcherViewController`) are verified present on iOS 15–17; on iOS 13–14 these classes may be renamed or restructured — UIKit hooks will still function normally, SpringBoard hooks will silently skip missing classes.

---

## Supported Jailbreaks & Devices

### Package variants

Two `.deb` packages are produced by the CI pipeline and published to each GitHub Release:

| Package suffix | `THEOS_PACKAGE_SCHEME` | Prefs path prefix | Target |
|----------------|------------------------|-------------------|--------|
| `-rootless.deb` | `rootless` | `/var/jb` | Dopamine 2, RootHide, palera1n (rootless) |
| `-rootful.deb` | *(unset)* | *(none)* | Checkra1n, unc0ver, palera1n (rootful) |

The preferences controller (`HaptixPrefsRootListController.m`) resolves the correct path at runtime by checking for the existence of `/var/jb`, so no recompilation is needed when switching between environments.

### Architecture

The `control` file declares `Architecture: iphoneos-arm64`. arm64 slices run on both arm64 and arm64e (A12+) devices under Dopamine 2. For RootHide, which enforces arm64e pointer authentication, change the architecture field to `iphoneos-arm64e` and recompile.

| Jailbreak | iOS Range | Architecture | Package | Status |
|-----------|-----------|--------------|---------|--------|
| Dopamine 2 | 15.0 – 16.6.1 | iphoneos-arm64 | `-rootless.deb` | Supported |
| RootHide | 15.0 – 16.x | iphoneos-arm64e (recompile required) | `-rootless.deb` | Supported |
| palera1n (rootless mode) | 15.0 – 16.x | iphoneos-arm64 | `-rootless.deb` | Compatible |
| palera1n (rootful mode) | 15.0 – 16.x | iphoneos-arm64 | `-rootful.deb` | Compatible |
| Checkra1n | 13.0 – 14.8.1 | iphoneos-arm64 | `-rootful.deb` | Compatible |
| unc0ver | 13.0 – 14.8 | iphoneos-arm64 | `-rootful.deb` | Compatible |

### Device coverage (iphoneos-arm64 build)

| Chip | Representative Devices | iOS 13–17 Rootless / Rootful |
|------|------------------------|------------------------------|
| A9 / A9X | iPhone 6s, SE (1st gen), iPad (5th gen) | Rootful (Checkra1n/unc0ver) |
| A10 / A10X | iPhone 7, iPad (6th–7th gen) | Rootful (Checkra1n/unc0ver) |
| A11 | iPhone 8, iPhone X | Rootful (Checkra1n/unc0ver) |
| A12 – A16 | iPhone XS through iPhone 14 series | Rootless (Dopamine 2 / RootHide) |

---

## Required iOS Settings

> **HaptiX will not produce any haptic feedback if these settings are disabled.** This is an intentional OS-level gate enforced by Apple: `UIImpactFeedbackGenerator` silently becomes a no-op when System Haptics is off, with no way to bypass it through the same API.

| Setting | Location | Status | Effect if disabled |
|---------|----------|--------|--------------------|
| **System Haptics** | Settings → Sounds & Haptics → System Haptics | **REQUIRED — ON** | All HaptiX haptics stop completely. Every hook calls `UIImpactFeedbackGenerator`, which is fully blocked at the OS layer when this is off. |
| **Keyboard Feedback → Haptic** | Settings → Sounds & Haptics → Keyboard Feedback → Haptic | **REQUIRED — ON** (if `hookKeyboard` is enabled) | Keyboard hook fires but produces no haptic output. Turn this on to get haptic feedback on keypresses. |

## System Conflicts

These are native iOS settings that, when enabled alongside HaptiX, cause the Taptic Engine to fire twice per interaction.

| Native Setting | Location | Conflicting Hook | Recommendation |
|---------------|----------|-----------------|----------------|
| Keyboard Feedback — Haptic | Settings > Sounds & Haptics > Keyboard Feedback | `UIKeyboardImpl -playKeyClickSound` | HaptiX fires its own haptic on the same event — you will get double feedback. Leave it ON (required for HaptiX keyboard haptics), but be aware the system also fires its own haptic for key taps. |
| System Haptics | Settings > Sounds & Haptics > System Haptics | All hooks | Must remain ON. Disabling it silences HaptiX entirely. |

> UIKit interactions (button taps, switch toggles) already carry a native system haptic when System Haptics is on. HaptiX adds a second one from its hooks. On Heavy/Rigid profiles this double-pulse is noticeable. You can reduce overlap by using the Light profile or by disabling specific hooks (e.g. `hookButtons`, `hookSwitches`) in HaptiX settings.

---

## Tweak Conflicts

Any tweak that hooks the same Objective-C methods as HaptiX will produce duplicate haptic pulses. No respring or error will occur — the feedback simply fires twice per event.

### High conflict risk

| Tweak category | Shared hook surface |
|----------------|---------------------|
| Keyboard haptic tweaks (e.g., any tweak that adds per-keypress vibration) | `UIKeyboardImpl -playKeyClickSound`, `UIKeyboardImpl -autoDelete` |
| Custom haptic / vibration tweaks targeting UIControl | `UIControl -sendAction:to:forEvent:` |
| Tweaks replacing or augmenting UISwitch behavior | `UISwitch -setOn:animated:` |
| Volume button behavior tweaks that call haptic APIs | `SBVolumeControl -increaseVolume` / `-decreaseVolume` |
| App-switcher gesture replacement tweaks | `SBHomeGesturePanGestureRecognizer -setState:`, `SBFluidSwitcherViewController` transition methods |

### Low conflict risk

Tweaks that operate on different layers (e.g., UI theming, network, notification, clipboard, or lock screen appearance tweaks that do not hook the specific methods above) are safe to run alongside HaptiX.

### Mitigation

Use the **Excluded Apps** list in HaptiX settings (powered by AltList) to disable HaptiX selectively in apps where a conflicting tweak is active, rather than disabling the conflicting tweak globally.
