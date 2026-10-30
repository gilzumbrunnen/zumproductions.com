# Changelog

## [Unreleased]

### Added

- Unpublished Games section: a Games nav item, a homepage teaser, `/games/`, one page per title, and `/games/privacy/`.
- Games pages send `noindex`. Remove that meta tag when the section is published. This repo has no sitemap; add the games URLs then if one is created.
- Games privacy policy for all six titles. The in-app URL is `https://zumproductions.com/games/privacy/`. `/games/privacy` without the slash redirects to that URL on the local static server.
- The effective date on the games privacy policy is still `[DD Month YYYY]`, marked on the page. Set it on the day the policy is approved for publishing.
- Support on each game page is games@zumproductions.com. The privacy contact on the games policy stays privacy@zumproductions.com.
- Screenshots are still missing for Callout Cadence, Summit Rescue, Funicular Fix, and Fondue Frenzy.
- Games hero art is in `assets/games/hero/` under stable names (`games_hero_1600x600` and `games_hero_3200x1200`, AVIF, WebP and PNG).
- Hero repaint: the Fromage Dash mouse now wears goggles and a scarf. Same filenames and dimensions. AVIF and the PNG fallbacks were regenerated with the same settings.
- Fromage Dash icon, feature graphic, and screenshots use the same reskin (goggles, red scarf, dusk background). Derivatives were regenerated with the same pipeline.
- This repo has no Content-Security-Policy file. The games pages add no third-party scripts, fonts, or trackers.
- `.htaccess` redirects `/games/privacy` to `https://zumproductions.com/games/privacy/` and sends `X-Robots-Tag: noindex` for `/games/` and `/assets/games/`. Gil merges this into the live Apache config ahead of the `/404/` catch-all. Remove the noindex header at launch.
- Game icons keep a fixed 72px box so they do not squash on a narrow screen.
- Portrait screenshot `sizes` follow the real column count (one column below 424px, two until 623px, three from 624px to 799px). Feature graphics stop at their native 1024px. Hero `sizes` uses 59rem under 640px, where the image is cover-cropped into the 22rem frame.
- Hero art adds AVIF and uses width descriptors. PNG fallbacks are compressed. Screenshot enlargements open the WebP.
- Hero text sits on a darker scrim. Footer focus rings use `#C4B5FD`.
- Game privacy links are absolute: `https://zumproductions.com/games/privacy/#slug`.

### Changed

- Header and footer use the approved Zum Productions lockup on studio pages and the Zum Games lockup on `/games/` pages. Light SVGs sit on the white header. Dark SVGs sit on the ink footer. The previous wordmark and mark files are removed.
- The Zum Games logo in the games header and footer links to the games index. The footer logo fades on hover and keyboard focus, with no underline and the lavender focus ring. The 404 page has Open Graph title, type, and URL, and its footer includes Games. Privacy and terms include `og:site_name`. The local note in `scripts/post-merge-curl.sh` lists only the checks that phase runs.
- Studio favicons are the root set (`favicon.ico`, `favicon.svg`, `favicon-32.png`, `favicon-16.png`, `apple-touch-icon-180.png`). Games pages use the set in `games/`.
- Open Graph cards are 1200×630 on paper `#F8F6F3`. Studio pages use `assets/og-image.png`. The games index and the games privacy page use `assets/og-games.png`. Each game page still shares its feature graphic.
- `scripts/post-merge-curl.sh` checks the new logo, favicon, and OG URLs for status 200 and content type. Phase `local` runs those checks against a static server.
- Studio contact is hello@zumproductions.com (bonjour@zumproductions.com on French content), including the quote button and the footer on the studio pages. Games pages use games@zumproductions.com in the footer. privacy@ stays on the privacy notice, the terms questions line, and the games privacy policy.

Do not merge this until the section is meant to go live.

### Deploy notes / launch blockers

- **Never use mirror, sync, or "delete missing files" in the SFTP client.** That would wipe `/en/` and `/404/` and take the live site down.
- Pre-launch upload is `games/` (including the games favicons), `assets/games/`, `assets/brand/`, `css/`, `js/`, `assets/fonts/inter-latin.woff2`, `assets/og-image.png`, and `assets/og-games.png`. Command: `git archive --format=zip -o /tmp/zumproductions-prelaunch.zip HEAD css js games assets/games assets/brand assets/fonts assets/og-image.png assets/og-games.png`. `index.html`, `privacy.html`, `terms.html`, `404.html`, and the studio favicon set wait until launch. Launch command, which also includes `css` and `js` because `404.html` loads them, and which expects the pre-launch upload to be done already: `git archive --format=zip -o /tmp/zumproductions-launch.zip HEAD index.html privacy.html terms.html 404.html favicon.ico favicon.svg favicon-32.png favicon-16.png apple-touch-icon-180.png css js assets robots.txt`. `robots.txt` is launch-only (allow all, no `/assets/` disallow, no `Sitemap:` line). `css/` and `js/` do not restyle the 2021 pages. Links to `/` still reach that site. Links to `privacy.html` and `terms.html` follow the catch-all to `/404/` until launch.
- Rollback step 2 deletes only paths that were new. It restores `favicon.ico`, `robots.txt`, and `404.html` (if one exists live) from the backup instead of deleting them, and removes the other studio favicon files if they were uploaded. The rest of the runbook is in the README.
- (a) Deploys are manual SFTP or file-manager uploads. Gil merges `.htaccess` into the live file. Do not replace the live file, and do not upload README, CHANGELOG, `scripts/`, or other dotfiles. Never use mirror, sync, or "delete missing files".
- (b) Remove the live `/` to `/en/` rule at launch. It hides the new `index.html`. The commented `^en(/.*)?$` rule can then 301 `/en/` and `/en/*` to `/`. Do not enable that rule while `/` still redirects to `/en/`.
- (c) Upload this repo's `robots.txt` over the live one. The live file disallows `/assets/`, which blocks the new images, fonts, and OG image. Also upload the studio favicon set from the repo root (`favicon.ico`, `favicon.svg`, `favicon-32.png`, `favicon-16.png`, `apple-touch-icon-180.png`) over the old icon.
- (d) `ErrorDocument 404 /404.html` does nothing until the live catch-all that 301s to `/404/` is replaced. `404.html` is in the repo, uses root-absolute paths, and is not active. The line is commented and sits outside `<IfModule mod_rewrite.c>` because it is a core directive. Do not enable it beside the old catch-all.
- (e) Remove the games `noindex` meta tags and the `X-Robots-Tag` block, and set the games privacy effective date. Removing the meta tags is a new commit, then `git archive --format=zip -o /tmp/zumproductions-games-html.zip HEAD games/index.html games/privacy/index.html games/fromage-dash/index.html games/callout-cadence/index.html games/alp-graze/index.html games/summit-rescue/index.html games/funicular-fix/index.html games/fondue-frenzy/index.html`.
- (f) Merging PR #3 makes Games public through the nav and the homepage teaser on GitHub. On the live server that only happens when `index.html` is uploaded and `/` stops redirecting to `/en/`. Merge only on Gil's explicit go.
- (g) Devops must confirm the document root (Infomaniak Manager, Hosting, Sites) before Gil merges `.htaccess` into the live file. Gil does the upload.
- (h) Set the `privacy.html` effective date at publish. The games@ mailbox must exist before merge (or switch the games pages and the games policy to privacy@).
- Hardening rewrite rules go before the live catch-all. Replace the live HSTS line. A second line loses, because the later one wins.
- Checks: `scripts/post-merge-curl.sh [base-url] [1|2|local]`. Default base is `https://zumproductions.com` and the default phase is 1. It prints PASS or FAIL per URL and exits 1 on a mismatch. Phase 1: `/games` is 301 to `/games/`. `/assets/fonts/` is 403 after the upload. `/sitemap.xml` is 301 to `/404/`. The non-games no-`X-Robots-Tag` check includes `/assets/og-image.png` and the brand SVGs, because `privacy.html` and `terms.html` still redirect. Logo, favicon, and OG checks also expect the content type. Phase 2 adds the studio favicon set, expects no `X-Robots-Tag` on the games icons, and treats `/sitemap.xml` and `/no-such-page-pr3-check` as real 404s. `/en/foo` is 301 to `https://zumproductions.com/`. `/games/privacy?x=1` is 301 to `https://zumproductions.com/games/privacy/?x=1` in both phases. `local` checks the same logo, favicon, and OG URLs against a static server and expects the old logo paths to 404. `--check-http` is optional and has to be run from another network. `scripts/` is `export-ignore`.


## [0.1.2] - 2026-10-25

### Changed

- Hero lede, eyebrow (Swiss digital studio), service blurbs, and contact heading.
- Primary contact button is "Send a short brief". Hero button stays "Talk to us".
- Public contact address is hello@zumproductions.com for the studio (bonjour@zumproductions.com on French content). games@ covers games. privacy@ stays on the privacy notice, the terms questions line, and the games privacy policy.
- Trust line under the hero actions. Newsletter line removed from the footer.
- Privacy and terms pages use short notice language. Meta descriptions match the new lede.

## [0.1.1] - 2026-10-25

### Changed

- Accent is purple `#6D28D9`, with hover `#5B21B6`. Soft `#8B5CF6` is decorative only (nav line, eyebrow).
- Logo, service icons, favicon, and Open Graph image replaced with the purple pack.

## [0.1.0] - 2026-10-25

### Added

- Static one-page site for Zum Productions: sticky nav, hero, Websites / Apps / Hosting cards, contact CTA, and ink footer.
- Painter palette (ink, teal, warm background) and self-hosted Inter.
- Logo mark, wordmark, service icons, favicon, and Open Graph image in `assets/`.
- Privacy and terms placeholder pages.
- Mobile menu script. Newsletter noted as coming soon, with no backend.
