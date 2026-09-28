#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"

signing_file="$HOME/.local/share/android-release-signing/nativealpha/signing.env"
apksigner="$ANDROID_HOME/build-tools/35.0.0/apksigner"
adb="$ANDROID_HOME/platform-tools/adb"
declare -a apks=(
    "glob:app/build/outputs/apk/extendedGithub/release/*universal*release*.apk"
)

resolve_apk() {
    local pattern="$1"
    if [[ "$pattern" == glob:* ]]; then
        local matches=() latest candidate
        mapfile -t matches < <(compgen -G "${pattern#glob:}" || true)
        (("${#matches[@]}" > 0)) || { echo "No universal release APK found. Build the release first." >&2; return 1; }
        latest="${matches[0]}"
        for candidate in "${matches[@]:1}"; do
            [[ "$candidate" -nt "$latest" ]] && latest="$candidate"
        done
        printf '%s\n' "$latest"
    else
        printf '%s\n' "$pattern"
    fi
}

verify_apks() {
    local pattern apk
    for pattern in "${apks[@]}"; do
        apk="$(resolve_apk "$pattern")"
        [[ -f "$apk" ]] || { echo "Missing APK: $apk" >&2; return 1; }
        "$apksigner" verify --verbose "$apk"
    done
}

load_signing() {
    [[ -f "$signing_file" ]] || { echo "Missing signing file: $signing_file" >&2; return 1; }
    # Signing variables stay outside the repository.
    source "$signing_file"
    local suffix variable
    for suffix in STORE_FILE STORE_PASSWORD KEY_ALIAS KEY_PASSWORD; do
        variable="NATIVEALPHA_ANDROID_$suffix"
        [[ -n "${!variable:-}" ]] || { echo "Missing signing variable: $variable" >&2; return 1; }
    done
    [[ -f "${NATIVEALPHA_ANDROID_STORE_FILE}" ]] || { echo "Signing keystore does not exist" >&2; return 1; }
}

case "${1:-}" in
    full|release)
        load_signing
        if [[ "$1" == full ]]; then ./gradlew clean; fi
        ./gradlew :app:assembleExtendedGithubRelease
        verify_apks
        ;;
    install)
        verify_apks
        "$adb" devices -l
        for pattern in "${apks[@]}"; do
            "$adb" install -r "$(resolve_apk "$pattern")"
        done
        ;;
    *)
        echo "Usage: $0 {full|release|install}" >&2
        exit 2
        ;;
esac
