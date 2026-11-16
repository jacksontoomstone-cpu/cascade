#!/bin/sh
# Builds dist/index.html for Vercel from plumb.html.
# Reads optional environment variables (set them in Vercel > Project > Settings > Environment Variables):
#   CASCADE_LIVES         lives per board (default 5)
#   CASCADE_FIRE_SECONDS  how long the fire lasts after cracking a special word (default 5)
#   CASCADE_ANALYTICS     set to 1 to load Vercel Web Analytics (turn it on in the dashboard too)
#   CASCADE_SITE_URL      the site's main address, for search engines and link previews (default https://www.playcascade.io)
set -e
cd "$(dirname "$0")"

# whole numbers only; anything else falls back to the default
num() { case "$1" in ''|*[!0-9]*) echo "$2" ;; *) echo "$1" ;; esac; }
LIVES=$(num "$CASCADE_LIVES" 5)
FIRE=$(num "$CASCADE_FIRE_SECONDS" 5)
SITE=${CASCADE_SITE_URL:-https://www.playcascade.io}
SITE=${SITE%/}
TITLE="Cascade: a falling-letters word puzzle"
DESC="Solve crossword-style clues and watch the letters fall. Crack the hidden top and side words before your lives run out."

mkdir -p dist
{
  printf '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
  # search results and link previews (texts, iMessage, Discord, X)
  printf '<title>%s</title>\n<meta name="description" content="%s">\n' "$TITLE" "$DESC"
  printf '<link rel="canonical" href="%s/">\n<link rel="icon" type="image/png" href="/icon.png">\n<link rel="apple-touch-icon" href="/icon.png">\n' "$SITE"
  printf '<meta name="theme-color" content="#04121a">\n'
  printf '<meta property="og:type" content="website">\n<meta property="og:site_name" content="Cascade">\n<meta property="og:url" content="%s/">\n' "$SITE"
  printf '<meta property="og:title" content="Cascade">\n<meta property="og:description" content="%s">\n' "$DESC"
  printf '<meta property="og:image" content="%s/og.png">\n<meta property="og:image:width" content="1200">\n<meta property="og:image:height" content="630">\n' "$SITE"
  printf '<meta property="og:image:alt" content="Cascade: solve the clues, watch the letters fall.">\n'
  printf '<meta name="twitter:card" content="summary_large_image">\n<meta name="twitter:title" content="Cascade">\n<meta name="twitter:description" content="%s">\n<meta name="twitter:image" content="%s/og.png">\n' "$DESC" "$SITE"
  printf '<script>window.CASCADE_CONFIG = { lives: %s, fireSeconds: %s };</script>\n' "$LIVES" "$FIRE"
  if [ "$CASCADE_ANALYTICS" = "1" ]; then
    printf '<script defer src="/_vercel/insights/script.js"></script>\n'
  fi
  # plumb.html opens with the artifact's page wrapper on line 1: keep its base styles, drop the duplicate doctype/html/head/body tags
  sed -e '1s/^<!doctype html><html><head>//' -e '1s/<\/head><body>$//' -e '/^<title>Cascade<\/title>$/d' plumb.html
  printf '\n</html>\n'
} > dist/index.html

cp og.png icon.png dist/
printf 'User-agent: *\nAllow: /\n\nSitemap: %s/sitemap.xml\n' "$SITE" > dist/robots.txt
printf '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n  <url><loc>%s/</loc><lastmod>%s</lastmod><changefreq>daily</changefreq></url>\n</urlset>\n' "$SITE" "$(date -u +%Y-%m-%d)" > dist/sitemap.xml

echo "Built dist/index.html (lives $LIVES, fire ${FIRE}s, analytics ${CASCADE_ANALYTICS:-off})"
