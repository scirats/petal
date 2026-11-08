#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."

CONFIG=${CONFIG:-release}
IDENTITY=${SIGN_IDENTITY:--}
OUT=build
APP="$OUT/Petal.app"

swift build -c "$CONFIG" --product Petal
swift build -c "$CONFIG" --product petalctl
BIN=$(swift build -c "$CONFIG" --show-bin-path)

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$OUT"
cp Support/Info.plist "$APP/Contents/Info.plist"
cp "$BIN/Petal" "$APP/Contents/MacOS/Petal"
[[ -f Support/AppIcon.icns ]] && cp Support/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp LICENSE "$APP/Contents/Resources/LICENSE.txt"
cp THIRD_PARTY_NOTICES.md "$APP/Contents/Resources/THIRD_PARTY_NOTICES.md"
cp "$BIN/petalctl" "$OUT/petalctl"

codesign --force --options runtime --entitlements Support/Petal.entitlements --sign "$IDENTITY" "$OUT/petalctl"
codesign --force --options runtime --entitlements Support/Petal.entitlements --sign "$IDENTITY" "$APP"
codesign --verify --strict "$APP"
echo "Built $APP and $OUT/petalctl"
