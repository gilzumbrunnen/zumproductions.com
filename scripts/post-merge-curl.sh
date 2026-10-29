#!/bin/sh
# Post-merge checks for zumproductions.com. Not part of the site upload.
# Run from a normal network. This environment's proxy answers 500 on port 80,
# so the http to https line has to be run from somewhere else.
#
# Phase 1 (games uploaded, homepage still the 2021 site, noindex still on):
#   /                          301 to /en/          (until launch blocker b)
#   /en/                       200                  (old site, until launch cleanup)
#   /index.html                not the new page yet if it was held back (catch-all to /404/)
#   /privacy.html              no X-Robots-Tag if the new file is not uploaded yet
#   /games and /games/         200, X-Robots-Tag: noindex
#   /games/privacy             301 to https://zumproductions.com/games/privacy/
#   /games/privacy/            200, X-Robots-Tag: noindex
#   each /games/<slug>/        200, X-Robots-Tag: noindex
#   /games/fromage-dash        301 to the trailing slash, not to /404/
#   /assets/games/...          200, X-Robots-Tag: noindex
#   /assets/og-image.png       200 only after the rest of assets/ is uploaded; no X-Robots-Tag
#   /assets/favicon.png        same
#   /favicon.ico               200 (old icon until launch)
#   /css/styles.css /js/nav.js 200 after the pre-launch upload
#   /assets/fonts/             403 (no directory listing)
#   /assets/games/             403 (no directory listing)
#   /robots.txt                still the live file until launch; after launch, no "Disallow: /assets/"
#   /sitemap.xml               301 to /404/ (there is no sitemap)
#   /no-such-page-*            301 to /404/ until the catch-all is replaced
#   /.git/ /.git/config /.env /.htaccess
#                              403 (or 404). Never 200.
#   www host                   Location https://zumproductions.com/... (path kept)
#   http host                  Location https://... (run off this network)
#   HSTS                       present on responses
#   no response anywhere       500
#
# Phase 2 (launch): / no longer 301s to /en/; /en/ 301s to /; index.html, privacy.html,
# terms.html and robots.txt are the new files; no X-Robots-Tag anywhere after the
# noindex commit is re-uploaded.

B=https://zumproductions.com
for p in / /en/ /index.html /privacy.html /terms.html /games /games/ /games/privacy /games/privacy/ \
  /games/fromage-dash/ /games/callout-cadence/ /games/alp-graze/ /games/summit-rescue/ /games/funicular-fix/ /games/fondue-frenzy/ \
  /games/fromage-dash /assets/games/hero/games_hero_1600x600.webp /assets/games/fromage-dash/icon-512.png \
  /assets/og-image.png /assets/favicon.png /favicon.ico /css/styles.css /js/nav.js /assets/fonts/ \
  /robots.txt /sitemap.xml /no-such-page-$RANDOM /.git/ /.git/config /.env /.htaccess /assets/games/ ; do
  printf '%-55s ' "$p"
  curl -s -o /dev/null -I -w '%{http_code} %{redirect_url}\n' "$B$p"
done
echo '-- games headers (expect x-robots-tag and strict-transport-security until launch) --'
curl -sI "$B/games/" | grep -iE '^(x-robots-tag|strict-transport-security|HTTP/)'
echo '-- privacy.html x-robots-tag count (expect 0) --'
curl -sI "$B/privacy.html" | grep -ic x-robots-tag
echo '-- og image x-robots-tag count (expect 0) --'
curl -sI "$B/assets/og-image.png" | grep -ic x-robots-tag
echo '-- www to apex (expect https://zumproductions.com/games/) --'
curl -sI "https://www.zumproductions.com/games/" | grep -i ^location
echo '-- http to https; run this line from another network --'
curl -sI "http://zumproductions.com/games/" | grep -i ^location
echo '-- robots.txt (after launch: no Disallow: /assets/) --'
curl -s "$B/robots.txt"
