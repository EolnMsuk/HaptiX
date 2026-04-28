# HaptiX

**HaptiX** is a system-wide haptic feedback tweak for iOS 16 rootless jailbreaks (Dopamine 2). It uses Apple's `UIImpactFeedbackGenerator` API to deliver clean, hardware-accelerated Taptic Engine feedback across UIKit apps and SpringBoard with a 50ms cooldown gate that eliminates double-fire.

---

## Features

- **System-wide injection** via `com.apple.UIKit` and `com.apple.springboard` filter — no per-app hooks required.
- **50ms cooldown gate** prevents the Taptic Engine from double-firing on rapid sequential UI events.
- **5 configurable Taptic Engine profiles** — selectable from Settings.
- **UIKit triggers** — Keyboard, Buttons, Switches, Table Cells, Scroll Edge.
- **SpringBoard triggers** — Volume, Power, Lock/Unlock, Homescreen Icons, App Switcher/Gestures.
- **Per-app exclusion list** via AltList — disable HaptiX for any app without a respring.
- **Hot-reload** — settings changes apply instantly via Darwin notification; no respring needed.

---

## Haptic Profiles

| # | Name | UIImpactFeedbackStyle |
|---|------|-----------------------|
| 0 | Light | `UIImpactFeedbackStyleLight` (default) |
| 1 | Medium | `UIImpactFeedbackStyleMedium` |
| 2 | Heavy | `UIImpactFeedbackStyleHeavy` |
| 3 | Soft | `UIImpactFeedbackStyleSoft` |
| 4 | Rigid | `UIImpactFeedbackStyleRigid` |

Profiles map directly to the native `UIImpactFeedbackGenerator` styles available on iOS 13+.

---

## Compatibility

| Field | Value |
|-------|-------|
| iOS | 15.0 – 16.x |
| Architecture | `iphoneos-arm64` (Rootless) |
| Jailbreak | Dopamine 2 |
| RootHide | Change `Architecture` in `control` to `iphoneos-arm64e` |

---

## Building & Installation

### Prerequisites

- [Theos](https://github.com/theos/theos) installed and configured for rootless compilation.
- iOS 16.5 SDK (set via `TARGET := iphone:clang:16.5:15.0` in the root `Makefile`).

### Local Compilation

```bash
git clone https://github.com/EolnMsuk/HaptiX.git
cd HaptiX
make package
```

Install the resulting `.deb` from the `packages/` folder via Sileo, Zebra, or Filza.

For a release-signed package:

```bash
make package FINALPACKAGE=1
```

To install directly to a connected device (requires `THEOS_DEVICE_IP` to be set):

```bash
make install
```

### GitHub Actions

Fork the repository and enable GitHub Actions. The workflow compiles a `.deb` artifact on every push to `main` and on pull requests. Pushing a tag matching `v*` additionally creates a GitHub Release with the `.deb` attached.

---

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

> **Tip:** Disable Apple's native keyboard haptics (Settings > Sounds & Haptics > Keyboard Feedback) to let HaptiX take full control and prevent overlapping feedback.

---

## Troubleshooting

**Haptics not firing after install:** Respring or restart the affected app. The tweak is injected at process launch.

**Settings changes not taking effect:** The tweak hot-reloads via Darwin notification — no respring needed. If changes still don't apply, force-quit and relaunch the app.

**Build fails with "SDK not found":** Ensure the Theos SDK path includes iOS 16.5. The `theos-action` CI step handles this automatically via `theos-sdks`.

---

## Credits

Author: [EolnMsuk](https://github.com/EolnMsuk)

Donate: [BTC](https://www.blockchain.com/explorer/addresses/btc/bc1qm06lzkdfule3f7flf4u70xvjrp5n74lzxnnfks) | [Venmo](https://venmo.com/user/eolnmsuk)
