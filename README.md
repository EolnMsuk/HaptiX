# HaptiX

**HaptiX** is a system-wide haptic feedback tweak for iOS 13–17, supporting both rootless jailbreaks and rootful jailbreaks. It uses Apple's `UIImpactFeedbackGenerator` to deliver clean, hardware-accelerated Taptic Engine feedback across every app.

---

## ✨ Features

- **System-wide injection** via `com.apple.UIKit` and `com.apple.springboard` — no per-app setup required.
- **50ms cooldown gate** prevents the Taptic Engine from double-firing on rapid sequential UI events.
- **5 configurable Taptic Engine profiles** — selectable from Settings.
- **UIKit triggers** — Keyboard, Buttons, Switches, Table Cells, Scroll Edge.
- **SpringBoard triggers** — Volume, Power, Lock/Unlock, Homescreen Icons, App Switcher/Gestures.
- **Per-app exclusion list** via AltList — disable HaptiX for any app.

---

## 📱 Compatibility

| Package | Jailbreak | iOS |
|---|---|---|
| `iphoneos-arm64.deb` | Dopamine 2, Palera1n (rootless mode), RootHide | iOS 15 – 17 |
| `iphoneos-arm.deb` | Palera1n (rootful mode) | iOS 15 – 17 |
| `iphoneos-arm_legacy.deb` | Unc0ver, Checkra1n, Electra | iOS 13 – 14 |

See [COMPATIBILITY.md](COMPATIBILITY.md) for a full device matrix and conflict guide.

---

## 📥 Installation

1. Navigate to the [Releases page](https://github.com/EolnMsuk/HaptiX/releases).
2. Download the correct `.deb` for your environment (see table).
3. Install it via **Sileo** or **Zebra** by opening the `.deb` file directly, or by importing it through the package manager's local file installer.
4. A respring will be performed automatically to activate the tweak.

---

## ⚙️ Configuration

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

> **Note:** With both System Haptics and Keyboard Feedback → Haptic ON, every keypress will fire the system's own haptic *and* HaptiX's haptic — producing a double-pulse. This is expected behavior; reduce its intensity by choosing the Light profile in HaptiX settings or by toggling off the Keyboard Presses hook.

---

## ⚠️ Required iOS Settings

HaptiX uses `UIImpactFeedbackGenerator`, which is gated at the OS level by Apple. **The tweak will produce zero haptic feedback if either of these settings is off — this cannot be overridden in software.**

| Setting | Path | Required state |
|---------|------|---------------|
| System Haptics | Settings → Sounds & Haptics → System Haptics | **ON** |
| Keyboard Feedback → Haptic | Settings → Sounds & Haptics → Keyboard Feedback → Haptic | **ON** *(only needed if the Keyboard hook is enabled)* |

---

## 🔧 Troubleshooting

**No haptics at all after install:** Verify System Haptics is **ON** (Settings → Sounds & Haptics → System Haptics). `UIImpactFeedbackGenerator` is completely disabled at the OS layer when this is off — HaptiX cannot fire regardless of its own settings.

**Keyboard hook produces no feedback:** Verify Keyboard Feedback → Haptic is **ON** (Settings → Sounds & Haptics → Keyboard Feedback → Haptic).

**Haptics not firing after install:** Respring or restart the affected app. The tweak is injected at process launch.

**Settings changes not taking effect:** The tweak hot-reloads via Darwin notification — no respring needed. If changes still don't apply, force-quit and relaunch the app.

**Double haptic pulse on interactions:** Another installed tweak or a native iOS haptic setting (System Haptics / Keyboard Feedback) is firing alongside HaptiX. See [COMPATIBILITY.md](COMPATIBILITY.md) for the full conflict guide.

---

## Credits

Author: [EolnMsuk](https://github.com/EolnMsuk)

Donate: [BTC](https://www.blockchain.com/explorer/addresses/btc/bc1qm06lzkdfule3f7flf4u70xvjrp5n74lzxnnfks) | [Venmo](https://venmo.com/user/eolnmsuk)
