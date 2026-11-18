#!/usr/bin/env bash
set -euo pipefail

package="$1"
variant="$2"
package_arch="$3"
version="$4"
minimum_ios="$5"

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

check_field() {
    local actual
    actual=$(dpkg-deb -f "$package" "$1")
    [[ "$actual" == "$2" ]] || fail "Expected $1 to be $2. Found $actual."
}

check_field Package com.eolnmsuk.haptix
check_field Version "$version"
check_field Architecture "$package_arch"

prefix=
case "$variant" in
    rootless)
        prefix=var/jb/
        altlist='@rpath/AltList.framework/AltList'
        ;;
    roothide) altlist='@loader_path/.jbroot/Library/Frameworks/AltList.framework/AltList' ;;
    rootful) altlist='@rpath/AltList.framework/AltList' ;;
    legacy) altlist='/Library/Frameworks/AltList.framework/AltList' ;;
    *) fail "Unknown package variant $variant." ;;
esac

contents=$(dpkg-deb -c "$package")
paths=$(awk '$1 ~ /^[-d]/ {
    path = $NF
    sub(/^\.\//, "", path)
    sub(/\/$/, "", path)
    print path
}' <<< "$contents")

tweak=$(awk '/(^|\/)(Library\/MobileSubstrate\/DynamicLibraries|usr\/lib\/TweakInject)\/HaptiX\.dylib$/' <<< "$paths")
case "$tweak" in
    "${prefix}Library/MobileSubstrate/DynamicLibraries/HaptiX.dylib"|"${prefix}usr/lib/TweakInject/HaptiX.dylib") ;;
    *) fail "Expected one HaptiX.dylib under the $variant installation root. Found ${tweak:-none}." ;;
esac
bundle="${prefix}Library/PreferenceBundles/haptixprefs.bundle"
entry="${prefix}Library/PreferenceLoader/Preferences/HaptiX.plist"
for path in "${tweak%.dylib}.plist" "$bundle" "$bundle/haptixprefs" "$entry"; do
    matches=$(awk -v expected="$path" '$0 == expected {print}' <<< "$paths")
    [[ "$matches" == "$path" ]] || fail "Expected one $path in $package."
done
printf 'Verified payload paths in %s\n' "$package"
printf '  %s\n' "$tweak" "${tweak%.dylib}.plist" "$bundle" "$entry"

extracted=$(mktemp -d "$RUNNER_TEMP/haptix-package.XXXXXXXX")
dpkg-deb -x "$package" "$extracted"
prefs="$extracted/$bundle/haptixprefs"

for binary in "$extracted/$tweak" "$prefs"; do
    archs=$(xcrun lipo -archs "$binary")
    case "$archs" in
        'arm64 arm64e'|'arm64e arm64') ;;
        *) fail "Expected arm64 and arm64e slices in $binary. Found $archs." ;;
    esac

    for arch in arm64 arm64e; do
        libraries=$(xcrun otool -arch "$arch" -L "$binary")
        commands=$(xcrun otool -arch "$arch" -l "$binary")
        minos=$(awk '
            $1 == "cmd" {ios = $2 == "LC_BUILD_VERSION" || $2 == "LC_VERSION_MIN_IPHONEOS"}
            ios && ($1 == "minos" || $1 == "version") {print $2; exit}
        ' <<< "$commands")
        runpaths=$(awk '
            $1 == "cmd" {rpath = $2 == "LC_RPATH"}
            rpath && $1 == "path" {print $2}
        ' <<< "$commands")

        printf '%s (%s), minimum iOS %s\n' "$binary" "$arch" "$minos"
        printf '%s\n' "$libraries"
        printf 'Runpaths\n%s\n' "$runpaths"
        [[ "$minos" == "$minimum_ios" || "$minos" == "$minimum_ios.0" ]] ||
            fail "Expected iOS $minimum_ios as the deployment target for $binary ($arch)."

        if [[ "$variant" != rootless ]] &&
            grep -Eq '^[[:space:]]*/var/jb(/|$)' <<< "$libraries"$'\n'"$runpaths"; then
            fail "Found a stock rootless load path in $binary ($arch) for $variant."
        fi

        if [[ "$binary" == "$prefs" ]]; then
            linked_altlist=$(awk '$1 ~ /\/AltList\.framework\/AltList$/ {print $1}' <<< "$libraries")
            [[ "$linked_altlist" == "$altlist" ]] ||
                fail "Expected $altlist in the prefs bundle ($arch). Found ${linked_altlist:-none}."

            case "$variant" in
                rootless)
                    grep -Fxq '/var/jb/Library/Frameworks' <<< "$runpaths" ||
                        grep -Fxq '@loader_path/.jbroot/Library/Frameworks' <<< "$runpaths" ||
                        fail "Missing the stock rootless framework runpath in the prefs bundle ($arch)."
                    ;;
                rootful)
                    grep -Fxq '/Library/Frameworks' <<< "$runpaths" ||
                        fail "Missing /Library/Frameworks in the prefs bundle runpaths ($arch)."
                    ;;
            esac
        fi
    done
done
