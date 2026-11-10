#!/usr/bin/env bash
# Renders the app icons and splash images from branding/mark.svg.
# Needs Playwright's headless Chromium (npx playwright install chromium-headless-shell) and macOS sips.
# Usage: branding/render-icons.sh
set -euo pipefail
cd "$(dirname "$0")/.."

CREAM='#f2ede6'
CHROME=${CHROME:-$(ls -d ~/Library/Caches/ms-playwright/chromium_headless_shell-*/chrome-*/chrome-headless-shell | tail -1)}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# render <out.png> <px> <mark height as a fraction of the canvas> <background, or "none">
render() {
  local out=$1 px=$2 scale=$3 bg=$4
  cat > "$TMP/page.html" <<HTML
<html><body style="margin:0;background:${bg/none/transparent}">
<svg id="s" width="$px" height="$px" style="display:block">$(sed -n '/<path/p' branding/mark.svg)</svg>
<script>
  const s = document.getElementById('s'), b = s.getBBox(), side = b.height / $scale;
  s.setAttribute('viewBox', [b.x + b.width / 2 - side / 2, b.y + b.height / 2 - side / 2, side, side].join(' '));
</script></body></html>
HTML
  "$CHROME" --headless --disable-gpu --hide-scrollbars --default-background-color=00000000 \
    --window-size="$px,$px" --screenshot="$out" "file://$TMP/page.html" 2>/dev/null
}

# A 1024 px master per variant; every size is scaled down from it.
render "$TMP/icon.png" 1024 0.62 "$CREAM"          # full-bleed square: iOS rounds the corners itself
render "$TMP/foreground.png" 1024 0.42 none        # Android adaptive foreground: inside the 66/108 safe zone
render "$TMP/splash.png" 1024 0.9 none             # centred on the cream splash background

resize() { sips -s format png -z "$2" "$2" "$1" --out "$3" >/dev/null; }

# iOS: every file in the AppIcon set is named after its pixel size, e.g. "120 1.png" is 120 px.
# The App Store icon must not have an alpha channel, so flatten it to JPEG and back.
for f in ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png; do
  px=$(basename "$f" .png); px=${px%% *}
  resize "$TMP/icon.png" "$px" "$f"
done
sips -s format jpeg "$TMP/icon.png" --out "$TMP/icon.jpg" >/dev/null
sips -s format png "$TMP/icon.jpg" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/1024.png >/dev/null

# iOS launch image: 168 x 185 pt in LaunchScreen.storyboard, so 185/370/555 px squares fit at 1x/2x/3x.
L=ios/Runner/Assets.xcassets/LaunchImage.imageset
resize "$TMP/splash.png" 185 "$L/LaunchImage.png"
resize "$TMP/splash.png" 370 "$L/LaunchImage@2x.png"
resize "$TMP/splash.png" 555 "$L/LaunchImage@3x.png"

# Android: legacy square icon, adaptive foreground, and the splash mark, per density.
for d in mdpi:1 hdpi:1.5 xhdpi:2 xxhdpi:3 xxxhdpi:4; do
  name=${d%%:*} m=${d##*:}
  dir=android/app/src/main/res/mipmap-$name
  resize "$TMP/icon.png" "$(printf '%.0f' "$(echo "48*$m" | bc)")" "$dir/ic_launcher.png"
  resize "$TMP/foreground.png" "$(printf '%.0f' "$(echo "108*$m" | bc)")" "$dir/ic_launcher_foreground.png"
  resize "$TMP/splash.png" "$(printf '%.0f' "$(echo "160*$m" | bc)")" "$dir/launch_image.png"
done
echo "Icons and splash images written."
