#!/bin/sh
# Builds dist/index.html for Vercel from plumb.html.
# Reads optional environment variables (set them in Vercel > Project > Settings > Environment Variables):
#   CASCADE_LIVES         lives per board (default 5)
#   CASCADE_FIRE_SECONDS  how long the fire lasts after cracking a special word (default 5)
#   CASCADE_ANALYTICS     set to 1 to load Vercel Web Analytics (turn it on in the dashboard too)
set -e
cd "$(dirname "$0")"

# whole numbers only; anything else falls back to the default
num() { case "$1" in ''|*[!0-9]*) echo "$2" ;; *) echo "$1" ;; esac; }
LIVES=$(num "$CASCADE_LIVES" 5)
FIRE=$(num "$CASCADE_FIRE_SECONDS" 5)

mkdir -p dist
{
  printf '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
  printf '<script>window.CASCADE_CONFIG = { lives: %s, fireSeconds: %s };</script>\n' "$LIVES" "$FIRE"
  if [ "$CASCADE_ANALYTICS" = "1" ]; then
    printf '<script defer src="/_vercel/insights/script.js"></script>\n'
  fi
  cat plumb.html
  printf '\n</html>\n'
} > dist/index.html

echo "Built dist/index.html (lives $LIVES, fire ${FIRE}s, analytics ${CASCADE_ANALYTICS:-off})"
