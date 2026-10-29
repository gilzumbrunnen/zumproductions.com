#!/bin/bash
# Post-merge checks for zumproductions.com. Not part of the site upload.
# Prints PASS or FAIL per check and exits 1 if any check fails.
#
# Usage:
#   scripts/post-merge-curl.sh [base-url] [1|2] [--check-http]
#   PHASE=2 scripts/post-merge-curl.sh https://zumproductions.com
#
# The base URL is $1, defaulting to https://zumproductions.com.
# PHASE is 1 or 2, from $2 or from the PHASE environment variable. Default is 1.
# --check-http (or CHECK_HTTP=1) requests http://<host>/games/ and expects a
# Location that starts with https://. Leave it off on this network: the proxy
# here answers 500 on port 80, so that check has to run from somewhere else.
#
# Phase 1, after the pre-launch upload (games/, assets/games/, css/, js/, and
# assets/favicon.png, assets/logo-mark.png, assets/logo-mark.svg,
# assets/logo-wordmark.svg, assets/fonts/inter-latin.woff2, assets/og-image.png).
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
#   /assets/og-image.png       200, no X-Robots-Tag (the non-games check)
#   /assets/favicon.png        200, no X-Robots-Tag
#   /favicon.ico               200 (old icon until launch)
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
#   /favicon.ico               200 (the new file)
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

if [[ "$PHASE" != "1" && "$PHASE" != "2" ]]; then
  echo "PHASE must be 1 or 2 (got ${PHASE})." >&2
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

# expect <path> <code> <location> <robots>
# location: empty skips the check; "-" requires no Location header; otherwise
# the Location must match that path or absolute URL. A query on the expected
# value must be kept. If the expected value has no query, one on the response
# is ignored.
# code may be "403|404".
# robots: yes (header present and contains noindex), no (header absent), or "-".
expect() {
  local path="$1"
  local want_code="$2"
  local want_loc="$3"
  local want_robots="$4"
  local url hdr code loc robots_n robots_line ok detail
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
  expect /assets/og-image.png 200 - no
  expect /assets/favicon.png 200 - no
  expect /favicon.ico 200 - -
  expect /css/styles.css 200 - no
  expect /js/nav.js 200 - no
  expect /assets/fonts/ 403 - -
  expect_robots_body /robots.txt live
  expect /sitemap.xml 301 /404/ -
  expect /no-such-page-pr3-check 301 /404/ -
  expect /assets/games/ 403 - -
else
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
  expect /assets/og-image.png 200 - no
  expect /assets/favicon.png 200 - no
  expect /favicon.ico 200 - -
  expect /css/styles.css 200 - no
  expect /js/nav.js 200 - no
  expect /assets/fonts/ 403 - -
  expect_robots_body /robots.txt launch
  expect /sitemap.xml 404 - -
  expect /no-such-page-pr3-check 404 - -
  expect /assets/games/ 403 - -
fi

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

if [[ "$failures" -gt 0 ]]; then
  echo "FAILED ${failures}"
  exit 1
fi
echo "OK"
exit 0
