# HaptiX

**HaptiX** is a system-wide haptic feedback tweak for iOS 13–17, supporting both rootless and rootful jailbreaks. It uses Apple's `UIImpactFeedbackGenerator` to deliver clean, hardware-accelerated Taptic Engine feedback across every app.

---

[<img width="800" alt="bannerRaw" src="https://github.com/user-attachments/assets/69dc12b5-8953-4ca8-a5be-9b6a37f1e7b2" />](https://www.reddit.com/r/jailbreak_/comments/1sz8wa9/haptix_system_wide_native_haptics_for_ios_1317/)

## Installation

1. Navigate to the [Releases page](https://github.com/EolnMsuk/HaptiX/releases).
2. Download the correct `.deb` for your environment. 
3. Install it via **Sileo** or **Zebra** by opening the `.deb`.

## Required iOS Settings

HaptiX uses `UIImpactFeedbackGenerator`, which is gated at the OS level by Apple. **The tweak will produce zero haptic feedback if either of these settings is off — this cannot be overridden in software.**

## Configuration

Open **Settings → HaptiX** to configure the tweak:

| Setting | Description |
|---------|-------------|
| Enable HaptiX | Master on/off toggle |
| Feedback Style | Choose one of 5 Taptic Engine profiles |
| Volume Buttons | SpringBoard volume key feedback |
| Power Button | Power/sleep key feedback |
| Lock/Unlock Events | Screen lock and unlock feedback |
| Homescreen Icons | Icon tap feedback |
| App Switcher & Gestures | Swipe gesture feedback |
| Keyboard Presses & Deletes | Key tap and delete feedback |
| Standard Buttons | `UIControl` tap feedback |
| UI Toggles & Switches | `UISwitch` feedback |
| Table/List Cells | `UITableViewCell` selection feedback |
| Scroll Collision Edge | Scroll boundary feedback (off by default) |
| Excluded Apps | Per-app exclusion list (AltList) |

## Troubleshooting

**No haptics at all after install:** Verify System Haptics is **ON** (Settings → Sounds & Haptics → System Haptics). `UIImpactFeedbackGenerator` is completely disabled at the OS layer when this is off — HaptiX cannot fire regardless of its own settings.

**Keyboard hook produces no feedback:** Verify Keyboard Feedback → Haptic is **ON** (Settings → Sounds & Haptics → Keyboard Feedback → Haptic).

**Haptics not firing after install:** Respring or restart the affected app. The tweak is injected at process launch.

**Double haptic pulse on interactions:** Another installed tweak or a native iOS haptic setting (System Haptics / Keyboard Feedback) is firing alongside HaptiX. See [compatability.md](compatability.md) for the full conflict guide.

## Developer

[Venmo](https://venmo.com/u/EolnMsuk) | Bitcoin: `31uHLpioo1TbxAmo9kM7rrKcLz3wvcoZaL`
