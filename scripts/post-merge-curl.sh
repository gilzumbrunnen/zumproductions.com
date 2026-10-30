#!/bin/bash
# Post-merge checks for zumproductions.com. Not part of the site upload.
# Prints PASS or FAIL per check and exits 1 if any check fails.
#
# Usage:
#   scripts/post-merge-curl.sh [base-url] [1|2|local] [--check-http]
#   PHASE=2 scripts/post-merge-curl.sh https://zumproductions.com
#   scripts/post-merge-curl.sh http://127.0.0.1:8000 local
#
# The base URL is $1, defaulting to https://zumproductions.com.
# PHASE is 1, 2, or local, from $2 or from the PHASE environment variable. Default is 1.
# local checks the static files against python3 -m http.server (no Apache redirects).
# --check-http (or CHECK_HTTP=1) requests http://<host>/games/ and expects a
# Location that starts with https://. Leave it off on this network: the proxy
# here answers 500 on port 80, so that check has to run from somewhere else.
#
# Phase 1, after the pre-launch upload (games/, assets/games/, assets/brand/,
# css/, js/, assets/fonts/inter-latin.woff2, assets/og-image.png, assets/og-games.png).
# Homepage files are not uploaded yet. noindex is still on.
#   /                          301 to /en/
#   /en/                       200 (old site, until launch cleanup), no X-Robots-Tag
#   /index.html                301 to /404/ (held back)
#   /privacy.html              301 to /404/ (held back). No X-Robots-Tag check:
#                              Header set does not run on a 3xx, so a count of 0
#                              would pass even if the games header were site-wide.
#   /terms.html                301 to /404/ (held back). Same as privacy.html.
#   /games                     301 to /games/   (not 200)
#   /games/                    200, X-Robots-Tag: noindex, HSTS present
#   /games/privacy             301 to https://zumproductions.com/games/privacy/
#   /games/privacy?x=1         301 to https://zumproductions.com/games/privacy/?x=1
#                              (the query string is kept)
#   /games/privacy/            200, X-Robots-Tag: noindex
#   each /games/<slug>/        200, X-Robots-Tag: noindex
#   /games/fromage-dash        301 to the trailing slash, not to /404/
#   /assets/games/...          200, X-Robots-Tag: noindex
#   /assets/games/             403 (no directory listing)
#   /assets/og-image.png       200, image/png, no X-Robots-Tag (the non-games check)
#   /assets/og-games.png       200, image/png, no X-Robots-Tag
#   /assets/brand/*.svg        200, image/svg+xml, no X-Robots-Tag
#   /games/favicon.svg         200, image/svg+xml, X-Robots-Tag: noindex
#   /games/favicon-32.png      200, image/png, X-Robots-Tag: noindex
#   /games/favicon-16.png      200, image/png, X-Robots-Tag: noindex
#   /games/apple-touch-icon-180.png
#                              200, image/png, X-Robots-Tag: noindex
#   /favicon.ico               200 (old icon until launch; content type not checked)
#   /css/styles.css /js/nav.js 200, no X-Robots-Tag
#   /assets/fonts/             403 after this upload (301 to /404/ before it)
#   /robots.txt                still the live file (body contains Disallow: /assets/)
#   /sitemap.xml               301 to /404/ (there is no sitemap)
#   /no-such-page-pr3-check    301 to /404/ until the catch-all is replaced
#   /.git/ /.git/config /.env /.htaccess
#                              403 or 404. Never 200.
#   www host                   Location https://zumproductions.com/games/
#                              (only when the base host is zumproductions.com)
#   http host                  optional, --check-http, Location starts with https://
#   no response anywhere       500
#
# Phase 2, after launch (index.html, privacy.html, terms.html, robots.txt,
# favicon.ico, 404.html, /en/ rule on, noindex block removed):
#   /                          200 (new home), no X-Robots-Tag
#   /en/ and /en/foo           301 to https://zumproductions.com/
#   /index.html /privacy.html /terms.html
#                              200, no X-Robots-Tag
#   /games and /games/<slug>  same redirects as phase 1, including
#                              /games/privacy?x=1, but no X-Robots-Tag
#   /games/ and each slug and /games/privacy/
#                              200, no X-Robots-Tag, HSTS present
#   assets, css, js            200, no X-Robots-Tag
#   /assets/fonts/ and /assets/games/
#                              403
#   /favicon.ico               200, image/vnd.microsoft.icon or image/x-icon
#   /favicon.svg               200, image/svg+xml
#   /favicon-32.png /favicon-16.png /apple-touch-icon-180.png
#                              200, image/png
#   /games/favicon.svg and the games PNG icons
#                              200, no X-Robots-Tag, same types as phase 1
#   brand SVGs and both OG images
#                              200, no X-Robots-Tag, same types as phase 1
#
# local, against python3 -m http.server from the repo root:
#   studio and games HTML      200, no X-Robots-Tag
#   the logo, favicon, and OG URLs above
#                              200 and the same content types
#   /assets/logo-wordmark.svg /assets/logo-wordmark.png
#   /assets/logo-mark.svg /assets/logo-mark.png /assets/favicon.png
#                              404
#   Dotfile and redirect checks are skipped. Those need Apache.
#   /robots.txt                200, and the body has no "Disallow: /assets/"
#   /sitemap.xml               404 (real status; there is still no sitemap)
#   /no-such-page-pr3-check    404 (real status) once ErrorDocument 404 /404.html
#                              replaces the soft-404 catch-all
#   /.git/ /.env /.htaccess    403 or 404, never 200
#   HSTS still present
#   no 500

set -u

BASE=""
PHASE_ARG=""
CHECK_HTTP="${CHECK_HTTP:-0}"
POSITIONAL=()

for arg in "$@"; do
  case "$arg" in
    --check-http) CHECK_HTTP=1 ;;
    --help|-h)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    -*)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
    *) POSITIONAL+=("$arg") ;;
  esac
done

if [[ ${#POSITIONAL[@]} -ge 1 ]]; then
  BASE="${POSITIONAL[0]}"
fi
if [[ ${#POSITIONAL[@]} -ge 2 ]]; then
  PHASE_ARG="${POSITIONAL[1]}"
fi
if [[ ${#POSITIONAL[@]} -gt 2 ]]; then
  echo "Too many arguments. Usage: $0 [base-url] [1|2] [--check-http]" >&2
  exit 2
fi

BASE="${BASE:-https://zumproductions.com}"
BASE="${BASE%/}"
if [[ -n "$PHASE_ARG" ]]; then
  PHASE="$PHASE_ARG"
fi
PHASE="${PHASE:-1}"

case "$CHECK_HTTP" in
  1|true|TRUE|yes|YES) CHECK_HTTP=1 ;;
  *) CHECK_HTTP=0 ;;
esac

if [[ "$PHASE" != "1" && "$PHASE" != "2" && "$PHASE" != "local" ]]; then
  echo "PHASE must be 1, 2, or local (got ${PHASE})." >&2
  exit 2
fi

failures=0

# Read one response header. The name is matched with tolower(), which mawk
# and macOS awk both provide. Over HTTP/2, curl prints header names in
# lowercase (location:, x-robots-tag:, strict-transport-security:).
header_value() {
  local name="$1"
  local file="$2"
  awk -v name="$name" 'BEGIN { pat = "^" name ":" }
    {
      if (tolower($0) ~ pat) {
        sub(/\r/, "")
        sub(/^[^:]*:[[:space:]]*/, "")
        print
        exit
      }
    }
  ' "$file"
}

location_ok() {
  local got="$1"
  local want="$2"
  local got_cmp want_cmp origin
  got="${got//$'\r'/}"
  got="${got#"${got%%[![:space:]]*}"}"
  got="${got%"${got##*[![:space:]]}"}"
  if [[ "$want" == *\?* ]]; then
    got_cmp="$got"
    want_cmp="$want"
  else
    got_cmp="${got%%\?*}"
    want_cmp="${want%%\?*}"
  fi
  [[ "$got_cmp" == "$want_cmp" ]] && return 0
  if [[ "$want_cmp" == /* ]]; then
    origin="$BASE"
    [[ "$got_cmp" == "$origin$want_cmp" ]] && return 0
    [[ "$got_cmp" == "https://zumproductions.com$want_cmp" ]] && return 0
    [[ "$got_cmp" == "http://zumproductions.com$want_cmp" ]] && return 0
  fi
  return 1
}

# Compare a Content-Type header to one MIME type, or to a|b alternatives.
# Parameters after ';' are ignored.
mime_ok() {
  local got="$1"
  local want="$2"
  local part
  got="${got//$'\r'/}"
  got="${got,,}"
  got="${got%%;*}"
  got="${got#"${got%%[![:space:]]*}"}"
  got="${got%"${got##*[![:space:]]}"}"
  local IFS='|'
  for part in $want; do
    part="${part,,}"
    part="${part// /}"
    if [[ "$got" == "$part" ]]; then
      return 0
    fi
  done
  return 1
}

# expect <path> <code> <location> <robots> [content-type]
# location: empty skips the check; "-" requires no Location header; otherwise
# the Location must match that path or absolute URL. A query on the expected
# value must be kept. If the expected value has no query, one on the response
# is ignored.
# code may be "403|404".
# robots: yes (header present and contains noindex), no (header absent), or "-".
# content-type: optional. A MIME type, or type|type. Compared without parameters.
expect() {
  local path="$1"
  local want_code="$2"
  local want_loc="$3"
  local want_robots="$4"
  local want_type="${5:-}"
  local url hdr code loc robots_n robots_line ctype ok detail
  url="${BASE}${path}"
  hdr=$(mktemp)
  code=$(curl -s -I --max-redirs 0 --max-time 25 -D "$hdr" -o /dev/null -w '%{http_code}' "$url" || true)
  if [[ ! "$code" =~ ^[0-9]{3}$ ]]; then
    code=000
  fi
  loc=$(header_value location "$hdr")
  robots_n=$(grep -ic '^x-robots-tag:' "$hdr" || true)
  robots_n=${robots_n:-0}
  robots_line=$(header_value x-robots-tag "$hdr")
  ctype=$(header_value content-type "$hdr")
  ok=1
  detail=""
  if [[ "$want_code" == *"|"* ]]; then
    if [[ "|$want_code|" != *"|$code|"* ]]; then
      ok=0
      detail+=" status want ${want_code} got ${code}"
    fi
  elif [[ "$code" != "$want_code" ]]; then
    ok=0
    detail+=" status want ${want_code} got ${code}"
  fi
  if [[ "$code" == "500" || "$code" == "000" ]]; then
    ok=0
  fi
  if [[ -n "$want_loc" ]]; then
    if [[ "$want_loc" == "-" ]]; then
      if [[ -n "$loc" ]]; then
        ok=0
        detail+=" location want none got ${loc}"
      fi
    elif ! location_ok "$loc" "$want_loc"; then
      ok=0
      detail+=" location want ${want_loc} got ${loc:-<none>}"
    fi
  fi
  if [[ "$want_robots" == "yes" ]]; then
    if [[ "$robots_n" -lt 1 ]] || ! printf '%s' "$robots_line" | grep -qi noindex; then
      ok=0
      detail+=" X-Robots-Tag want noindex got ${robots_line:-<none>}"
    fi
  elif [[ "$want_robots" == "no" ]]; then
    if [[ "$robots_n" -ne 0 ]]; then
      ok=0
      detail+=" X-Robots-Tag want none got ${robots_line}"
    fi
  fi
  if [[ -n "$want_type" ]]; then
    if ! mime_ok "$ctype" "$want_type"; then
      ok=0
      detail+=" content-type want ${want_type} got ${ctype:-<none>}"
    fi
  fi
  if [[ "$ok" -eq 1 ]]; then
    printf 'PASS  %s  %s\n' "$code" "$path"
  else
    printf 'FAIL  %s  %s %s\n' "$code" "$path" "$detail"
    failures=$((failures + 1))
  fi
  rm -f "$hdr"
}

expect_hsts() {
  local path="$1"
  local url hdr hsts
  url="${BASE}${path}"
  hdr=$(mktemp)
  curl -s -I --max-redirs 0 --max-time 25 -D "$hdr" -o /dev/null "$url" || true
  hsts=$(header_value strict-transport-security "$hdr")
  if [[ -n "$hsts" ]]; then
    printf 'PASS  HSTS  %s  %s\n' "$path" "$hsts"
  else
    printf 'FAIL  HSTS  %s  missing Strict-Transport-Security\n' "$path"
    failures=$((failures + 1))
  fi
  rm -f "$hdr"
}

expect_robots_body() {
  local path="$1"
  local mode="$2"
  local url hdr body code
  url="${BASE}${path}"
  hdr=$(mktemp)
  body=$(mktemp)
  code=$(curl -s --max-redirs 0 --max-time 25 -D "$hdr" -o "$body" -w '%{http_code}' "$url" || true)
  if [[ ! "$code" =~ ^[0-9]{3}$ ]]; then
    code=000
  fi
  if [[ "$code" != "200" ]]; then
    printf 'FAIL  %s  %s  status want 200 got %s\n' "$code" "$path" "$code"
    failures=$((failures + 1))
  elif [[ "$mode" == "live" ]]; then
    if grep -q 'Disallow: /assets/' "$body"; then
      printf 'PASS  %s  %s  Disallow: /assets/ present\n' "$code" "$path"
    else
      printf 'FAIL  %s  %s  expected Disallow: /assets/ in the live file\n' "$code" "$path"
      failures=$((failures + 1))
    fi
  elif grep -q 'Disallow: /assets/' "$body"; then
    printf 'FAIL  %s  %s  Disallow: /assets/ is still present\n' "$code" "$path"
    failures=$((failures + 1))
  else
    printf 'PASS  %s  %s  no Disallow: /assets/\n' "$code" "$path"
  fi
  rm -f "$hdr" "$body"
}

expect_brand_files() {
  local robots="$1"
  expect /assets/og-image.png 200 - "$robots" image/png
  expect /assets/og-games.png 200 - "$robots" image/png
  expect /assets/brand/zum-productions_light.svg 200 - "$robots" image/svg+xml
  expect /assets/brand/zum-productions_dark.svg 200 - "$robots" image/svg+xml
  expect /assets/brand/zum-games_light.svg 200 - "$robots" image/svg+xml
  expect /assets/brand/zum-games_dark.svg 200 - "$robots" image/svg+xml
}

expect_games_favicons() {
  local robots="$1"
  expect /games/favicon.svg 200 - "$robots" image/svg+xml
  expect /games/favicon-32.png 200 - "$robots" image/png
  expect /games/favicon-16.png 200 - "$robots" image/png
  expect /games/apple-touch-icon-180.png 200 - "$robots" image/png
}

expect_root_favicons() {
  local robots="$1"
  expect /favicon.ico 200 - "$robots" "image/vnd.microsoft.icon|image/x-icon"
  expect /favicon.svg 200 - "$robots" image/svg+xml
  expect /favicon-32.png 200 - "$robots" image/png
  expect /favicon-16.png 200 - "$robots" image/png
  expect /apple-touch-icon-180.png 200 - "$robots" image/png
}

echo "phase ${PHASE}  ${BASE}"

if [[ "$PHASE" == "1" ]]; then
  expect / 301 /en/ -
  expect /en/ 200 - no
  expect /index.html 301 /404/ -
  expect /privacy.html 301 /404/ -
  expect /terms.html 301 /404/ -
  expect /games 301 /games/ -
  expect /games/ 200 - yes
  expect_hsts /games/
  expect /games/privacy 301 "https://zumproductions.com/games/privacy/" -
  expect "/games/privacy?x=1" 301 "https://zumproductions.com/games/privacy/?x=1" -
  expect /games/privacy/ 200 - yes
  expect /games/fromage-dash/ 200 - yes
  expect /games/callout-cadence/ 200 - yes
  expect /games/alp-graze/ 200 - yes
  expect /games/summit-rescue/ 200 - yes
  expect /games/funicular-fix/ 200 - yes
  expect /games/fondue-frenzy/ 200 - yes
  expect /games/fromage-dash 301 /games/fromage-dash/ -
  expect /assets/games/hero/games_hero_1600x600.webp 200 - yes
  expect /assets/games/fromage-dash/icon-512.png 200 - yes
  expect_brand_files no
  expect_games_favicons yes
  expect /favicon.ico 200 - -
  expect /css/styles.css 200 - no
  expect /js/nav.js 200 - no
  expect /assets/fonts/ 403 - -
  expect_robots_body /robots.txt live
  expect /sitemap.xml 301 /404/ -
  expect /no-such-page-pr3-check 301 /404/ -
  expect /assets/games/ 403 - -
elif [[ "$PHASE" == "2" ]]; then
  expect / 200 - no
  expect /en/ 301 "https://zumproductions.com/" -
  expect /en/foo 301 "https://zumproductions.com/" -
  expect /index.html 200 - no
  expect /privacy.html 200 - no
  expect /terms.html 200 - no
  expect /games 301 /games/ -
  expect /games/ 200 - no
  expect_hsts /games/
  expect /games/privacy 301 "https://zumproductions.com/games/privacy/" -
  expect "/games/privacy?x=1" 301 "https://zumproductions.com/games/privacy/?x=1" -
  expect /games/privacy/ 200 - no
  expect /games/fromage-dash/ 200 - no
  expect /games/callout-cadence/ 200 - no
  expect /games/alp-graze/ 200 - no
  expect /games/summit-rescue/ 200 - no
  expect /games/funicular-fix/ 200 - no
  expect /games/fondue-frenzy/ 200 - no
  expect /games/fromage-dash 301 /games/fromage-dash/ -
  expect /assets/games/hero/games_hero_1600x600.webp 200 - no
  expect /assets/games/fromage-dash/icon-512.png 200 - no
  expect_brand_files no
  expect_games_favicons no
  expect_root_favicons no
  expect /css/styles.css 200 - no
  expect /js/nav.js 200 - no
  expect /assets/fonts/ 403 - -
  expect_robots_body /robots.txt launch
  expect /sitemap.xml 404 - -
  expect /no-such-page-pr3-check 404 - -
  expect /assets/games/ 403 - -
else
  expect / 200 - no
  expect /privacy.html 200 - no
  expect /terms.html 200 - no
  expect /404.html 200 - no
  expect /games/ 200 - no
  expect /games/privacy/ 200 - no
  expect /games/fromage-dash/ 200 - no
  expect /games/callout-cadence/ 200 - no
  expect /games/alp-graze/ 200 - no
  expect /games/summit-rescue/ 200 - no
  expect /games/funicular-fix/ 200 - no
  expect /games/fondue-frenzy/ 200 - no
  expect /css/styles.css 200 - no text/css
  expect /js/nav.js 200 - no "text/javascript|application/javascript"
  expect_brand_files no
  expect_games_favicons no
  expect_root_favicons no
  expect /assets/logo-wordmark.svg 404 - -
  expect /assets/logo-wordmark.png 404 - -
  expect /assets/logo-mark.svg 404 - -
  expect /assets/logo-mark.png 404 - -
  expect /assets/favicon.png 404 - -
fi

if [[ "$PHASE" != "local" ]]; then
  expect /.git/ "403|404" - -
  expect /.git/config "403|404" - -
  expect /.env "403|404" - -
  expect /.htaccess "403|404" - -

  host="${BASE#*://}"
  host="${host%%/*}"
  if [[ "$host" == "zumproductions.com" || "$host" == "www.zumproductions.com" ]]; then
    saved="$BASE"
    BASE="https://www.zumproductions.com"
    expect /games/ 301 "https://zumproductions.com/games/" -
    BASE="$saved"
  fi

  if [[ "$CHECK_HTTP" -eq 1 ]]; then
    saved="$BASE"
    BASE="http://${host}"
    hdr=$(mktemp)
    code=$(curl -s -I --max-redirs 0 --max-time 25 -D "$hdr" -o /dev/null -w '%{http_code}' "${BASE}/games/" || true)
    loc=$(header_value location "$hdr")
    if [[ "$code" =~ ^3 && "$loc" == https://* && "$loc" == *"/games/"* ]]; then
      printf 'PASS  %s  http://%s/games/  %s\n' "$code" "$host" "$loc"
    else
      printf 'FAIL  %s  http://%s/games/  want 3xx Location https://.../games/ got %s\n' "${code:-000}" "$host" "${loc:-<none>}"
      failures=$((failures + 1))
    fi
    rm -f "$hdr"
    BASE="$saved"
  fi
fi

if [[ "$failures" -gt 0 ]]; then
  echo "FAILED ${failures}"
  exit 1
fi
echo "OK"
exit 0
