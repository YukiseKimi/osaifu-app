#!/bin/bash
#
# The one way to run Osaifu's tests.
#
#   script/test.sh packages            the headless tests of OsaifuCore
#   script/test.sh journey [Class/test]  the UI journeys, on a simulator
#   script/test.sh build               Release builds, and the sealed-launch check
#   script/test.sh ids                 the identifier registry against its mirror
#
# The simulator comes from OSAIFU_SIM, so a run never picks one of its own.
set -uo pipefail
cd "$(dirname "$0")/.."

PROJECT=OsaifuApp.xcodeproj
SCHEME=Osaifu
GREEN="\033[32m"; RED="\033[31m"; OFF="\033[0m"

green() { printf "${GREEN}GREEN${OFF}  %s\n" "$1"; }
red()   { printf "${RED}RED${OFF}    %s\n" "$1"; }

lane_packages() {
    local out; out=$(swift test --package-path OsaifuCore 2>&1)
    local line; line=$(printf '%s' "$out" | grep -E "Test run with" | tail -1)
    if printf '%s' "$out" | grep -q "Test run with .* passed"; then
        green "packages  ${line##*􁁛  }"
    else
        red "packages"
        printf '%s\n' "$out" | grep -E "error:|recorded an issue" | head -20
        printf "rerun: swift test --package-path OsaifuCore\n"
        return 1
    fi
}

lane_ids() {
    # The app owns the registry; the UI target mirrors it, because a UI test
    # bundle cannot import the app. These two lists must stay the same.
    local app mirror
    app=$(grep -oE '"[a-zA-Z]+\.[a-zA-Z.\\()]+"' Osaifu/Testing/A11yID.swift | sort)
    mirror=$(grep -oE '"[a-zA-Z]+\.[a-zA-Z.\\()]+"' OsaifuUITests/Support/A11yIDMirror.swift | sort)
    if [ "$app" = "$mirror" ]; then
        green "ids       $(printf '%s' "$app" | wc -l | tr -d ' ') identifiers, registry and mirror agree"
    else
        red "ids       the registry and its mirror differ"
        diff <(printf '%s\n' "$app") <(printf '%s\n' "$mirror") | head -20
        printf "rerun: script/test.sh ids\n"
        return 1
    fi
}

lane_journey() {
    local sim="${OSAIFU_SIM:-}"
    if [ -z "$sim" ]; then
        red "journey   no simulator. Set OSAIFU_SIM to a simulator UDID."
        return 1
    fi
    # --clean throws the whole derived data away. Use it when a run fails
    # with "embedded binary is not signed" (Xcode left the widget extension
    # unsigned and believes otherwise) or when the app dies at launch with
    # "Library missing" (its rpath points at frameworks that are not there).
    # Deleting less than everything causes the second of those.
    if [ "${1:-}" = "--clean" ]; then
        shift
        rm -rf ~/Library/Developer/Xcode/DerivedData/OsaifuApp-*
        printf "CLEAN\n"
    fi

    # This lane signs. An unsigned widget extension cannot launch, and the
    # system starts it when the app is installed, which fails the test before
    # it reaches the first screen.
    # The bash on a Mac is 3.2, where "${empty[@]}" under set -u is an
    # unbound variable and not an empty list, so the expansion below carries
    # its own default. Without it the whole-suite form of this lane could
    # never run at all.
    local only=()
    [ $# -gt 0 ] && only=(-only-testing:"OsaifuUITests/$1")

    local built start finish
    start=$(date +%s)
    built=$(xcodebuild build-for-testing \
        -project "$PROJECT" -scheme "$SCHEME" \
        -destination "id=$sim" -configuration Debug 2>&1)
    if ! printf '%s' "$built" | grep -q "^\*\* TEST BUILD SUCCEEDED \*\*"; then
        red "journey   the build failed"
        printf '%s\n' "$built" | grep -E "error:" | head -10
        return 1
    fi
    finish=$(date +%s)
    printf "BUILT  %ss\n" "$((finish - start))"

    local out
    start=$(date +%s)
    out=$(xcodebuild test-without-building \
        -project "$PROJECT" -scheme "$SCHEME" \
        -destination "id=$sim" -configuration Debug \
        -parallel-testing-enabled NO \
        ${only[@]+"${only[@]}"} 2>&1)
    finish=$(date +%s)

    # test-without-building prints TEST EXECUTE SUCCEEDED, not TEST SUCCEEDED.
    if printf '%s' "$out" | grep -qE "^\*\* TEST (EXECUTE )?SUCCEEDED \*\*"; then
        green "journey   $(printf '%s' "$out" | grep -cE "' passed \(") passed in $((finish - start))s"
    else
        red "journey"
        printf '%s\n' "$out" | grep -E "error:|XCTAssert|never appeared|Critical process" | head -12
        printf "rerun: OSAIFU_SIM=%s script/test.sh journey %s\n" "$sim" "${1:-}"
        return 1
    fi
}

lane_build() {
    local failed=0
    for d in "generic/platform=iOS Simulator" "platform=macOS"; do
        if xcodebuild build -project "$PROJECT" -scheme "$SCHEME" \
            -destination "$d" -configuration Release \
            CODE_SIGNING_ALLOWED=NO >/tmp/osaifu-build.log 2>&1; then
            green "build     Release for $d"
        else
            red "build     Release for $d"
            grep -E "error:" /tmp/osaifu-build.log | head -10
            failed=1
        fi
    done

    # A Release app must refuse a sealed launch, or a journey's store could
    # reach someone's device.
    local app plist value
    app=$(find ~/Library/Developer/Xcode/DerivedData/OsaifuApp-*/Build/Products/Release-iphonesimulator -maxdepth 1 -name "Osaifu.app" 2>/dev/null | head -1)
    if [ -n "$app" ]; then
        value=$(/usr/libexec/PlistBuddy -c "Print :OsaifuSealedLaunch" "$app/Info.plist" 2>/dev/null)
        if [ "$value" = "NO" ]; then
            green "build     Release refuses a sealed launch"
        else
            red "build     Release says OsaifuSealedLaunch=$value, which should be NO"
            failed=1
        fi
    fi
    return $failed
}

case "${1:-}" in
    packages) shift; lane_packages "$@" ;;
    ids)      shift; lane_ids "$@" ;;
    journey)  shift; lane_journey "$@" ;;
    build)    shift; lane_build "$@" ;;
    *) printf "lanes: packages | ids | journey [Class/test] | build\n"; exit 2 ;;
esac
