#!/bin/bash
# Post-merge checks for zumproductions.com. Not part of the site upload.
# Run from a normal network. This environment's proxy answers 500 on port 80,
# so the http to https line has to be run from somewhere else.
#
# Phase 1, after the pre-launch upload (games/, assets/games/, css/, js/, and
# assets/favicon.png, assets/logo-mark.png, assets/logo-mark.svg,
# assets/logo-wordmark.svg, assets/fonts/inter-latin.woff2, assets/og-image.png).
# Homepage files are not uploaded yet. noindex is still on.
#   /                          301 to /en/
#   /en/                       200 (old site, until launch cleanup)
#   /index.html                301 to /404/ (held back)
#   /privacy.html              301 to /404/ (held back); no X-Robots-Tag
#   /terms.html                301 to /404/ (held back); no X-Robots-Tag
#   /games                     301 to /games/   (not 200)
#   /games/                    200, X-Robots-Tag: noindex
#   /games/privacy             301 to https://zumproductions.com/games/privacy/
#   /games/privacy/            200, X-Robots-Tag: noindex
#   each /games/<slug>/        200, X-Robots-Tag: noindex
#   /games/fromage-dash        301 to the trailing slash, not to /404/
#   /assets/games/...          200, X-Robots-Tag: noindex
#   /assets/games/             403 (no directory listing)
#   /assets/og-image.png       200, no X-Robots-Tag
#   /assets/favicon.png        200, no X-Robots-Tag
#   /favicon.ico               200 (old icon until launch)
#   /css/styles.css /js/nav.js 200
#   /assets/fonts/             301 to /404/ before this upload; 403 after it
#   /robots.txt                still the live file (Disallow: /assets/ until launch)
#   /sitemap.xml               301 to /404/ (there is no sitemap)
#   /no-such-page-pr3-check    301 to /404/ until the catch-all is replaced
#   /.git/ /.git/config /.env /.htaccess
#                              403 (or 404). Never 200.
#   www host                   Location https://zumproductions.com/games/ (path kept)
#   http host                  Location https://... (run off this network)
#   HSTS                       present (checked on /games/)
#   no response anywhere       500
#
# Phase 2, after launch (index.html, privacy.html, terms.html, robots.txt,
# favicon.ico, 404.html, /en/ rule on, noindex commit re-uploaded):
#   /                          200 (new home), no X-Robots-Tag
#   /en/ and /en/foo           301 to https://zumproductions.com/
#   /index.html /privacy.html /terms.html
#                              200, no X-Robots-Tag
#   /games and /games/<slug>  same redirects as phase 1, but no X-Robots-Tag
#   /games/ and each slug and /games/privacy/
#                              200, no X-Robots-Tag
#   assets, css, js            200
#   /assets/fonts/ and /assets/games/
#                              403
#   /favicon.ico               200 (the new file)
#   /robots.txt                200, and the body has no "Disallow: /assets/"
#   /sitemap.xml               301 to /404/ until a sitemap exists
#   /no-such-page-pr3-check    404 (real status) once ErrorDocument 404 /404.html
#                              replaces the soft-404 catch-all; 301 to /404/ until then
#   /.git/ /.env /.htaccess    403 or 404, never 200
#   HSTS still present
#   no 500

B=https://zumproductions.com
for p in / /en/ /index.html /privacy.html /terms.html /games /games/ /games/privacy /games/privacy/ \
  /games/fromage-dash/ /games/callout-cadence/ /games/alp-graze/ /games/summit-rescue/ /games/funicular-fix/ /games/fondue-frenzy/ \
  /games/fromage-dash /assets/games/hero/games_hero_1600x600.webp /assets/games/fromage-dash/icon-512.png \
  /assets/og-image.png /assets/favicon.png /favicon.ico /css/styles.css /js/nav.js /assets/fonts/ \
  /robots.txt /sitemap.xml /no-such-page-pr3-check /.git/ /.git/config /.env /.htaccess /assets/games/ ; do
  printf '%-55s ' "$p"
  curl -s -o /dev/null -I -w '%{http_code} %{redirect_url}\n' "$B$p"
done
echo '-- games headers (phase 1: x-robots-tag and strict-transport-security; phase 2: HSTS only) --'
curl -sI "$B/games/" | grep -iE '^(x-robots-tag|strict-transport-security|HTTP/)'
echo '-- privacy.html x-robots-tag count (expect 0) --'
curl -sI "$B/privacy.html" | grep -ic x-robots-tag
echo '-- terms.html x-robots-tag count (expect 0) --'
curl -sI "$B/terms.html" | grep -ic x-robots-tag
echo '-- og image x-robots-tag count (expect 0) --'
curl -sI "$B/assets/og-image.png" | grep -ic x-robots-tag
echo '-- www to apex (expect https://zumproductions.com/games/) --'
curl -sI "https://www.zumproductions.com/games/" | grep -i ^location
echo '-- http to https; run this line from another network --'
curl -sI "http://zumproductions.com/games/" | grep -i ^location
echo '-- robots.txt (after launch: no Disallow: /assets/) --'
curl -s "$B/robots.txt"
