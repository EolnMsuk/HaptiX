# HaptiX Project Structure

## File Tree

```text
HaptiX/
├── Tweak.x                         # UIKit and SpringBoard hooks, preferences, haptic engine
├── HaptiX.plist                    # Injection filter for UIKit and SpringBoard
├── control                         # Package ID, dependencies, Debian architecture, version
├── Makefile                        # Aggregate build for the tweak and Settings bundle
├── Makefile.legacy                 # Separate local recipe with an arm64 default and iOS 13 minimum
├── build_all.sh                    # Three-target local build helper
├── depiction.json                  # Package manager depiction
├── haptixprefs/
│   ├── Makefile                    # Settings bundle, AltList link, native RootHide define
│   ├── Makefile.legacy             # Settings bundle recipe for local legacy builds
│   ├── HaptixPrefsRootListController.h
│   ├── HaptixPrefsRootListController.m  # Banner, version footer, preference reset, Info actions
│   └── Resources/
│       ├── Info.plist              # Bundle metadata and version
│       ├── Root.plist              # Main specifiers, including Excluded Apps
│       ├── Advanced.plist          # Per-trigger haptic style overrides
│       ├── banner.png, banner2.png # Settings header images
│       ├── icon*.png               # Preference pane icons
│       └── HaptiX.png, sicon.png   # Package manager imagery
├── layout/
│   └── Library/PreferenceLoader/Preferences/HaptiX.plist
├── vendor/
│   ├── AltList.framework/          # Canonical link input replaced in each Actions checkout
│   ├── AltList_New.framework/      # Rootless and modern rootful link input
│   ├── AltList_Roothide.framework/ # Native RootHide link input
│   └── AltList_Old.framework/      # Legacy rootful link input
├── .github/
│   ├── workflows/build.yml         # Build matrix, artifact uploads, draft release
│   └── scripts/verify-package.sh   # Package checks on the macOS runner
├── README.md                       # Installation and configuration
├── compatability.md                # Jailbreak, architecture, and conflict guide
├── ProjectOverview.md              # Project overview
└── changelog.md                    # Release history
```

The tweak reads the `com.eolnmsuk.haptix` preferences domain with CFPreferences and dispatches feedback through `UIImpactFeedbackGenerator`. The Settings bundle loads its specifiers and images from its own resources. Its footer reads the bundle version and displays `RootHide` on the native build.

## Build System & CI Pipeline

Pushes to `main` and manual dispatches run [the packaging workflow](.github/workflows/build.yml). The metadata job on `ubuntu-latest` reads the release version from `control`. One `macos-15` job builds each row with both `arm64` and `arm64e` Mach-O slices.

| 2.0.0 draft asset | Theos scheme | Debian architecture | SDK / minimum iOS | Vendored framework |
| --- | --- | --- | --- | --- |
| `com.eolnmsuk.HaptiX_2.0.0_rootless.deb` | `rootless` | `iphoneos-arm64` | 16.5 / 15.0 | `AltList_New.framework` |
| `com.eolnmsuk.HaptiX_2.0.0_roothide.deb` | `roothide` | `iphoneos-arm64e` | 16.5 / 15.0 | `AltList_Roothide.framework` |
| `com.eolnmsuk.HaptiX_2.0.0_rootful.deb` | rootful (unset) | `iphoneos-arm` | 16.5 / 15.0 | `AltList_New.framework` |
| `com.eolnmsuk.HaptiX_2.0.0_legacy.deb` | rootful (unset) | `iphoneos-arm` | 14.5 / 13.0 | `AltList_Old.framework` |

The four build jobs use `Randomblock1/theos-action@v1` to provision Theos and host tools. For RootHide, the runner clones `roothide/theos` with its submodules under `$RUNNER_TEMP`, selects its `bin` ahead of the stock tools, and makes the 16.5 SDK available in the fork's SDK directory. The aggregate build passes the row's scheme, SDK, deployment target, and slices to the tweak and Settings bundle.

Each job copies its selected framework to `vendor/AltList.framework`. The Settings bundle links against that copy, and the package manager supplies the runtime framework through `com.opa334.altlist`. The modern rootful build resolves `@rpath` through `/Library/Frameworks`, and the stock rootless build uses the rootless scheme's framework runpaths. The native RootHide load name is `@loader_path/.jbroot/Library/Frameworks/AltList.framework/AltList`. Legacy uses the absolute `/Library/Frameworks/AltList.framework/AltList` load name. If the legacy linker probe fails on the historical ABI, the job logs the diagnostic and retries with a rootful text stub for the app picker interface.

Theos stages the PreferenceLoader entry from `layout/Library/PreferenceLoader/Preferences/HaptiX.plist` alongside the tweak, injection filter, and `haptixprefs.bundle`. Stock rootless places them under `var/jb/` in the archive. RootHide uses paths relative to its jailbreak root. Rootful and legacy use paths relative to the filesystem root.

Before upload, the runner uses `dpkg-deb`, `lipo`, and `otool` to verify the installed ID, version, architecture, archive paths, Mach-O slices, deployment targets, and AltList linkage. Each job uploads one named asset as `HaptiX-<variant>`. The `ubuntu-latest` release job merges the four downloads, compares their case-sensitive basenames, and attaches the four explicit files to the `HaptiX v<version>` draft tagged `v<version>-b<run_number>`.

## Local Build Helper

`build_all.sh` is a separate local helper for rootful, rootless, and legacy rootful builds. The four-package release runs from a clean checkout in GitHub Actions and uses the runner's temporary directory for the native toolchain and package inspection.

## Maintainer Verification

1. Run the workflow in Actions. Confirm the runner and Xcode versions, review the package checks, and compare the draft assets with the table.
2. Install the native `_roothide.deb` directly from your RootHide package manager. In **Settings → HaptiX**, check the `2.0.0` footer and the **Excluded Apps** picker. Enable HaptiX and **Standard Buttons**, then tap a standard button to confirm feedback.
3. Record the Actions and device results separately from local static verification.
