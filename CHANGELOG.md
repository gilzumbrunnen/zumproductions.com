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
- `.htaccess` redirects `/games/privacy` to `/games/privacy/` and sends `X-Robots-Tag: noindex` for `/games/` and `/assets/games/`. Devops: merge this into the live Apache config ahead of the `/404/` catch-all. Remove the noindex header at launch.
- Game icons keep a fixed 72px box so they do not squash on a narrow screen.
- Portrait screenshot `sizes` follow the real column count (one column below 424px, two until 623px, three from 624px to 799px). Feature graphics stop at their native 1024px. Hero `sizes` uses 59rem under 640px, where the image is cover-cropped into the 22rem frame.
- Hero art adds AVIF and uses width descriptors. PNG fallbacks are compressed. Screenshot enlargements open the WebP.
- Hero text sits on a darker scrim. Footer focus rings use `#C4B5FD`.
- Game privacy links are absolute: `https://zumproductions.com/games/privacy/#slug`.

Do not merge this until the section is meant to go live.

### Deploy notes / launch blockers

- **Never use mirror, sync, or "delete missing files" in the SFTP client.** That would wipe `/en/` and `/404/` and take the live site down.
- Pre-launch upload is `games/`, `assets/games/`, `css/`, `js/`, and six shared files that are not on the live site: `assets/favicon.png`, `assets/logo-mark.png`, `assets/logo-mark.svg`, `assets/logo-wordmark.svg`, `assets/fonts/inter-latin.woff2`, and `assets/og-image.png`. Command: `git archive --format=zip -o /tmp/zumproductions-prelaunch.zip HEAD css js games assets/games assets/favicon.png assets/logo-mark.png assets/logo-mark.svg assets/logo-wordmark.svg assets/fonts assets/og-image.png`. `index.html`, `privacy.html`, `terms.html`, `404.html`, and `favicon.ico` wait until launch. `robots.txt` is launch-only (allow all, no `/assets/` disallow, no `Sitemap:` line). `css/` and `js/` do not restyle the 2021 pages. Links to `/` still reach that site. Links to `privacy.html` and `terms.html` follow the catch-all to `/404/` until launch.
- Rollback step 2 removes the new paths and restores `robots.txt` from the backup. It does not delete `robots.txt` and leave the site without one. The rest of the runbook is in the README.
- (d) `ErrorDocument 404 /404.html` does nothing until the live catch-all that 301s to `/404/` is replaced. `404.html` is in the repo, uses root-absolute paths, and is not active.
- (e) Removing the games `noindex` meta tags is a new commit, then `git archive --format=zip -o /tmp/zumproductions-games-html.zip HEAD games/index.html games/privacy/index.html games/fromage-dash/index.html games/callout-cadence/index.html games/alp-graze/index.html games/summit-rescue/index.html games/funicular-fix/index.html games/fondue-frenzy/index.html`.
- Hardening rewrite rules go before the live catch-all. Replace the live HSTS line. A second line loses, because the later one wins.
- (h) Set the `privacy.html` effective date at publish. The games@ mailbox must exist before merge (or switch the games pages and the games policy to privacy@).
- Checks: `scripts/post-merge-curl.sh` (`#!/bin/bash`, fixed path `/no-such-page-pr3-check`). Phase 1: `/games` is 301 to `/games/`. `/assets/fonts/` is 301 to `/404/` before the upload and 403 after it. `/terms.html` is 301 to `/404/` until launch. The script header has the launch-phase set. `scripts/` is `export-ignore`. The plain-`http` check has to be run from another network.


## [0.1.2] - 2026-10-25

### Changed

- Hero lede, eyebrow (Swiss digital studio), service blurbs, and contact heading.
- Primary contact button is "Send a short brief". Hero button stays "Talk to us".
- Public contact address is hello@zumproductions.com. privacy@ stays on the privacy notice and the terms questions line.
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
