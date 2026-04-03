# HaptiX 📳

**HaptiX** is an advanced, system-wide haptic customization tweak designed specifically for modern iOS 16 rootless jailbreaks (like Dopamine 2). 

Instead of relying on outdated legacy engine hooks that drain battery or cause SpringBoard crashes, HaptiX natively taps into Apple's `UIImpactFeedbackGenerator`. This provides clean, hardware-accelerated haptic feedback across your entire device with zero double-vibration stuttering.

## ✨ Features

* **System-Wide Injection:** Broadly hooks into UIKit to provide haptics across almost all applications without needing dozens of individual app hooks.
* **Smart Cooldown Gate:** Built-in 50ms time gate prevents the Taptic Engine from rattling or double-firing when multiple UI events happen simultaneously.
* **Taptic Engine Profiles:** Choose from 5 native hardware profiles:
  * Light
  * Medium
  * Heavy
  * Soft *(Perfect for subtle UI shifts)*
  * Rigid *(Perfect for a mechanical keyboard feel)*
* **Advanced Targeting:** Toggle haptics individually for:
  * Keyboard Presses
  * UI Buttons & Toggles
  * Scroll Momentum End

## 📱 Compatibility

* **iOS Version:** iOS 16.x
* **Architecture:** `iphoneos-arm64` (Rootless)
* **Jailbreaks:** Dopamine 2 
* **Devices:** Fully tested and optimized for A15 devices (e.g., iPhone 13 mini).

*(Note: If you are compiling for RootHide, change the architecture in the `control` file to `iphoneos-arm64e`)*

## 🛠️ Building & Installation

This project is structured to be built with [Theos](https://github.com/theos/theos). It is also fully compatible with standard Theos GitHub Actions workflows.

**Local Compilation:**
1. Ensure Theos is installed and configured for rootless compilation.
2. Clone this repository:
   ```bash
   git clone [https://github.com/YOUR_USERNAME/HaptiX.git](https://github.com/YOUR_USERNAME/HaptiX.git)
   cd HaptiX````

3.  Compile the `.deb` package:
    ```bash
    make package
    ```
4.  Install the resulting `.deb` file (found in the `packages` folder) via Sileo, Zebra, or Filza.

**GitHub Actions:**
If you fork this repository and enable GitHub Actions, the workflow will automatically compile the `.deb` file as an artifact upon every push.

## ⚙️ Configuration

Once installed, configure HaptiX directly from the native iOS **Settings** app.

*We recommend disabling Apple's native keyboard haptics (Settings \> Sounds & Haptics \> Keyboard Feedback) to let HaptiX take over entirely and prevent overlapping feedback.*

## 🧑‍💻 Author

Developed by **eolnmsuk**

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.
