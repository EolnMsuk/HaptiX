# HaptiX Changelog

## 2.0.1

- Added the **Other** group with **Updates**, **GitHub**, **Reddit**, and **Donate**.
- **Updates** checks GitHub for the latest published stable HaptiX release when tapped.
- **Donate** offers Venmo in the default browser and a **Crypto Wallets** list with tap-to-copy addresses.

  | Release asset | Environment |
  | --- | --- |
  | `com.eolnmsuk.HaptiX_2.0.1_rootless.deb` | iOS 15–17 rootless |
  | `com.eolnmsuk.HaptiX_2.0.1_roothide.deb` | iOS 15–16 RootHide |
  | `com.eolnmsuk.HaptiX_2.0.1_rootful.deb` | iOS 15–17 rootful |
  | `com.eolnmsuk.HaptiX_2.0.1_legacy.deb` | iOS 13–14 rootful |

## 2.0.0

- The native RootHide package installs directly in your package manager. The HaptiX Settings footer shows `RootHide` on this build.
- GitHub Actions prepares four release assets for the same installed package ID, `com.eolnmsuk.haptix`.

## 1.2.0

- **20 new haptic triggers:** Added feedback for hardware and system events (screenshots, display wake, charger plug/unplug, ringer switch, reachability), System UI actions (Control Center and its toggles/modules, folders, Spotlight, Siri, power-down slider, biometric unlock, home bar gestures, passcode keys, app closures, call status changes, lock sounds, resprings), and app prompts (text selection menus and system alerts).
- **Dedicated Advanced Settings page:** Moved custom per-trigger styles into their own sub-page organized by category so the main settings screen stays clean.
- **Full reset support:** Updated the settings reset option to clear and restore all new triggers and custom styles.

## 1.1.0

- **Per-trigger haptic styles:** Pick Light, Medium, Heavy, Soft, or Rigid for individual triggers, or set any trigger to follow your global style.
- **Info section:** Added GitHub and Donate buttons in Settings.
- **Version & setup footer:** Added a footer at the bottom of Settings showing your HaptiX version and detected iOS/jailbreak environment.
- **More reliable reset:** Fixed resetting so preferences update right away instead of holding onto old values.

## 1.0.5

- **Build improvements:** Streamlined how packages are built for different iOS versions and jailbreak setups.

## 1.0.4

- **Cleaner package file names:** Updated package file names to follow standard package naming conventions.

## 1.0.3

- **Fixed Feedback Style option:** Resolved an issue that prevented choosing a feedback style in Settings.
- **Improved reset behavior:** Made resetting preferences apply changes cleanly.
- **New visuals and icons:** Added a banner in Settings that adapts between Light and Dark Mode, plus icons for Settings and package managers.
- **Dedicated iOS 13–14 support:** Added a separate package tailored for older iOS versions.

## 1.0.2

- **iOS 13.0–17.0 support:** Expanded compatibility to cover iOS 13 through iOS 17.
- **Rootful jailbreak support:** Added support for rootful setups in addition to rootless ones.

## 1.0.1

- **Five haptic profiles:** Added Light, Medium, Heavy, Soft, and Rigid feedback options in Settings.
- **Fixed per-app blacklist:** Fixed a mismatch that kept app blacklist preferences from working as expected.
- **Refined haptic timing & feel:** Switched to native iOS impact feedback with a cooldown between triggers.
