# HaptiX — Compatibility Matrix

---

## Supported iOS Versions

| Field | Value | Source |
|-------|-------|--------|
| Minimum deployment target | iOS 15.0 | `TARGET := iphone:clang:16.5:15.0` in root `Makefile` |
| Maximum tested | iOS 16.x | SDK 16.5; rootless jailbreak availability ceiling |
| Haptic API minimum | iOS 13.0 | `UIImpactFeedbackStyleSoft` / `UIImpactFeedbackStyleRigid` require iOS 13+ |

HaptiX is compiled against the iOS 16.5 SDK with a deployment floor of iOS 15.0. The `UIImpactFeedbackStyleSoft` and `UIImpactFeedbackStyleRigid` profiles introduced in iOS 13 are safely above that floor. All hooked private SpringBoard classes (`SBVolumeControl`, `SBLockHardwareButton`, `SBLockScreenManager`, `SBIconView`, `SBHomeGesturePanGestureRecognizer`, `SBFluidSwitcherViewController`) are present across the iOS 15–16 range.

---

## Supported Jailbreaks & Devices

### Package scheme

HaptiX is built with `THEOS_PACKAGE_SCHEME = rootless`. The preferences file is stored under the `/var/jb` prefix. **Rootful jailbreaks are not supported** by this build without recompilation.

### Architecture

The `control` file declares `Architecture: iphoneos-arm64`. arm64 slices run on both arm64 and arm64e (A12+) devices under Dopamine 2. For RootHide, which enforces arm64e pointer authentication, change the architecture field to `iphoneos-arm64e` and recompile.

| Jailbreak | iOS Range | Architecture | Status |
|-----------|-----------|--------------|--------|
| Dopamine 2 | 15.0 – 16.6.1 | iphoneos-arm64 (default build) | Supported |
| RootHide | 15.0 – 16.x | iphoneos-arm64e (recompile required) | Supported |
| palera1n (rootless mode) | 15.0 – 16.x | iphoneos-arm64 | Compatible |
| Checkra1n / unc0ver (rootful) | — | — | Not supported |

### Device coverage (iphoneos-arm64 build)

| Chip | Representative Devices | iOS 15–16 Rootless |
|------|------------------------|-------------------|
| A9 / A9X | iPhone 6s, SE (1st gen), iPad (5th gen) | Dopamine 2 |
| A10 / A10X | iPhone 7, iPad (6th–7th gen) | Dopamine 2 |
| A11 | iPhone 8, iPhone X | Dopamine 2 |
| A12 – A16 | iPhone XS through iPhone 14 series | Dopamine 2 / RootHide |

---

## System Conflicts

These are native iOS settings that, when enabled alongside HaptiX, cause the Taptic Engine to fire twice per interaction.

| Native Setting | Location | Conflicting Hook | Recommendation |
|---------------|----------|-----------------|----------------|
| Keyboard Feedback — Haptic | Settings > Sounds & Haptics > Keyboard Feedback | `UIKeyboardImpl -playKeyClickSound` | Disable to prevent double-tap feedback on every keystroke |
| System Haptics | Settings > Sounds & Haptics > System Haptics | `UIControl -sendAction:to:forEvent:`, `UISwitch -setOn:animated:` | Disabling removes iOS baseline haptics system-wide; optional but eliminates all overlap |

> If you leave System Haptics enabled, UIKit interactions (button taps, switch toggles) will produce one system haptic followed immediately by HaptiX's injection, which is audible on heavy Taptic Engine modes. Keyboard Feedback is the most noticeable conflict and should always be disabled when `hookKeyboard` is on.

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
