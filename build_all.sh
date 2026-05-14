#!/usr/bin/env bash
set -euo pipefail

VERSION=$(grep -i '^Version:' control | awk '{print $2}')
[ -z "$VERSION" ] && { echo "Error → Version not found in control file"; exit 1; }

mkdir -p output
rm -f output/*.deb

SDK_16="$THEOS/sdks/iPhoneOS16.5.sdk"
SDK_14="$THEOS/sdks/iPhoneOS14.5.sdk"

# ── Swap in new AltList for modern builds ─────────────────────────────────────
rm -rf vendor/AltList.framework
cp -R vendor/AltList_New.framework vendor/AltList.framework

# Modern Rootful (iOS 15+, palera1n rootful)
make clean
rm -rf packages/*
make package FINALPACKAGE=1 SYSROOT="$SDK_16" TARGET="iphone:clang:16.5:15.0" ARCHS="arm64 arm64e"
mv packages/*.deb "output/com.eolnmsuk.haptix_${VERSION}_iphoneos-arm.deb"

# Modern Rootless (iOS 15+, Dopamine 2 / RootHide / palera1n rootless)
make clean
rm -rf packages/*
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless SYSROOT="$SDK_16" TARGET="iphone:clang:16.5:15.0" ARCHS="arm64 arm64e"
mv packages/*.deb "output/com.eolnmsuk.haptix_${VERSION}_iphoneos-arm64.deb"

# Legacy Rootful (iOS 13–14, Checkra1n / Unc0ver / Electra)
make clean
rm -rf packages/*
make package FINALPACKAGE=1 SYSROOT="$SDK_14" TARGET="iphone:clang:14.5:13.0" ARCHS="arm64 arm64e"
mv packages/*.deb "output/com.eolnmsuk.haptix_${VERSION}_iphoneos-arm_legacy.deb"

echo ""
echo "Done! Built:"
ls output/
