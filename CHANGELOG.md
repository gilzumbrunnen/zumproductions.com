# Changelog

## [Unreleased]

### Added

- Unpublished Games section: a Games nav item, a homepage teaser, `/games/`, one page per title, and `/games/privacy/`.
- Games pages send `noindex`. Remove that meta tag when the section is published. This repo has no sitemap; add the games URLs then if one is created.
- Games privacy policy for all six titles. The in-app URL is `https://zumproductions.com/games/privacy/`. `/games/privacy` without the slash redirects to that URL on the local static server.
- The effective date on the games privacy policy is still `[DD Month YYYY]`, marked on the page. Set it on the day the policy is approved for publishing.
- Support on each game page is games@zumproductions.com. The privacy contact on the games policy stays privacy@zumproductions.com.
- Screenshots are still missing for Callout Cadence, Summit Rescue, Funicular Fix, and Fondue Frenzy.
- Games hero art is in `assets/games/hero/` under stable names (`games_hero_1600x600` and `games_hero_3200x1200`, WebP and PNG).
- This repo has no Content-Security-Policy file. The games pages add no third-party scripts, fonts, or trackers.
- `.htaccess` redirects `/games/privacy` to `/games/privacy/` and sends `X-Robots-Tag: noindex` for `/games/` and `/assets/games/`. Devops: merge this into the live Apache config ahead of the `/404/` catch-all. Remove the noindex header at launch.
- Game icons keep a fixed 72px box so they do not squash on a narrow screen.
- Portrait screenshot `sizes` follow the single column on small screens. Feature graphics stop at their native 1024px.
- Hero art adds AVIF and uses width descriptors. PNG fallbacks are compressed. Screenshot enlargements open the WebP.
- Hero text sits on a darker scrim. Footer focus rings use `#C4B5FD`.
- Game privacy links are absolute: `https://zumproductions.com/games/privacy/#slug`.

Do not merge this until the section is meant to go live.


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
