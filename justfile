set shell := ["bash", "-euo", "pipefail", "-c"]

# Build, install, and launch Findroid on the connected debugging device.
run:
    @adb get-state 2>/dev/null | grep -qx device || { echo "No debugging device connected. Check 'adb devices'." >&2; exit 1; }
    ./gradlew :app:phone:installLibreDebug
    adb shell am force-stop dev.jdtech.jellyfin.debug
    adb shell am start -W -n dev.jdtech.jellyfin.debug/dev.jdtech.jellyfin.MainActivity
