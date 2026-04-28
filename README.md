# HaptiX

**HaptiX** is a system-wide haptic feedback tweak for iOS 13–17, supporting both rootless jailbreaks (Dopamine 2, palera1n) and rootful jailbreaks (Checkra1n, unc0ver). It uses Apple's `UIImpactFeedbackGenerator` to deliver clean, hardware-accelerated Taptic Engine feedback across every UIKit app and SpringBoard, with a 50ms cooldown gate that eliminates double-fire.

---

## ✨ Features

- **System-wide injection** via `com.apple.UIKit` and `com.apple.springboard` — no per-app setup required.
- **50ms cooldown gate** prevents the Taptic Engine from double-firing on rapid sequential UI events.
- **5 configurable Taptic Engine profiles** — selectable from Settings.
- **UIKit triggers** — Keyboard, Buttons, Switches, Table Cells, Scroll Edge.
- **SpringBoard triggers** — Volume, Power, Lock/Unlock, Homescreen Icons, App Switcher/Gestures.
- **Per-app exclusion list** via AltList — disable HaptiX for any app without a respring.
- **Hot-reload** — settings changes apply instantly via Darwin notification; no respring needed.

---

## 🎚️ Haptic Profiles

| # | Name | UIImpactFeedbackStyle |
|---|------|-----------------------|
| 0 | Light | `UIImpactFeedbackStyleLight` (default) |
| 1 | Medium | `UIImpactFeedbackStyleMedium` |
| 2 | Heavy | `UIImpactFeedbackStyleHeavy` |
| 3 | Soft | `UIImpactFeedbackStyleSoft` |
| 4 | Rigid | `UIImpactFeedbackStyleRigid` |

Profiles map directly to the native `UIImpactFeedbackGenerator` styles available on iOS 13+.

---

## 📱 Compatibility

| Field | Value |
|-------|-------|
| iOS | 13.0 – 17.0 |
| Architecture | `iphoneos-arm64` |
| Rootless jailbreaks | Dopamine 2, RootHide, palera1n (rootless) — use `-rootless.deb` |
| Rootful jailbreaks | Checkra1n, unc0ver, palera1n (rootful) — use `-rootful.deb` |
| RootHide (arm64e) | Change `Architecture` in `control` to `iphoneos-arm64e` and recompile |

See [COMPATIBILITY.md](COMPATIBILITY.md) for a full device matrix and conflict guide.

---

## 📥 Installation

1. Navigate to the [Releases page](https://github.com/EolnMsuk/HaptiX/releases).
2. Download the correct `.deb` for your environment:
   - **Rootless** jailbreak (Dopamine 2, palera1n rootless): download the `*-rootless.deb` file.
   - **Rootful** jailbreak (Checkra1n, unc0ver, palera1n rootful): download the `*-rootful.deb` file.
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

> **Tip:** Disable Apple's native keyboard haptics (Settings > Sounds & Haptics > Keyboard Feedback) to let HaptiX take full control and prevent overlapping feedback.

---

## 🔧 Troubleshooting

**Haptics not firing after install:** Respring or restart the affected app. The tweak is injected at process launch.

**Settings changes not taking effect:** The tweak hot-reloads via Darwin notification — no respring needed. If changes still don't apply, force-quit and relaunch the app.

**Double haptic pulse on interactions:** Another installed tweak or a native iOS haptic setting (System Haptics / Keyboard Feedback) is firing alongside HaptiX. See [COMPATIBILITY.md](COMPATIBILITY.md) for the full conflict guide.

---

## Credits

Author: [EolnMsuk](https://github.com/EolnMsuk)

Donate: [BTC](https://www.blockchain.com/explorer/addresses/btc/bc1qm06lzkdfule3f7flf4u70xvjrp5n74lzxnnfks) | [Venmo](https://venmo.com/user/eolnmsuk)
