# Zum Productions

Static marketing site for [zumproductions.com](https://zumproductions.com), plus an unpublished Games section.

No build step. Open the files with any static server.

## Run locally

From the repo root:

```bash
python3 -m http.server 8000
```

Then open [http://localhost:8000/](http://localhost:8000/).

## Pages

| Path | What it is |
|------|------------|
| `index.html` | Home: nav, hero, services, games teaser, contact |
| `privacy.html` | Short privacy notice for the studio site |
| `terms.html` | Short terms notice |
| `games/index.html` | Games catalog (unpublished, `noindex`) |
| `games/<slug>/index.html` | One page per game. These are the Play listing websites. |
| `games/privacy/index.html` | Games privacy policy. In-app link: `https://zumproductions.com/games/privacy/` |
| `css/styles.css` | Layout and the Painter palette |
| `js/nav.js` | Mobile menu only |
| `assets/` | Logo, service icons, favicon, OG image, self-hosted Inter |
| `assets/games/<slug>/` | Icon, feature graphic, optional title logo, screenshots |

The games pages are not published. They send `noindex`. `.htaccess` in this repo is a merge template, never a file to upload over the live one. It shows where the `/games/privacy` rewrite and the temporary `X-Robots-Tag: noindex` belong. See the deploy notes. Python's static server still adds the slash on its own.

## Games art

Each game folder uses the same names:

- `icon-512.png`, plus `icon-512.webp`, `icon-512.avif`, `icon-256.webp`, `icon-256.avif`
- `feature-1024x500.png`, plus `.webp`, `.avif`, and `feature-w640.webp` / `feature-w640.avif`
- `shots/<name>.png`, plus `.webp`, `.avif`, and a smaller `-w640` (landscape) or `-w360` (portrait) derivative
- `title-logo.png` when a wordmark file exists (Alp Graze and Summit Rescue). The pages use the feature graphic and an HTML heading, so the wordmark is kept in the folder and not shown again.

Replace an icon or feature graphic, then rerun:

```bash
python3 scripts/optimize-games-art.py
```

Needs Pillow, `cwebp`, `avifenc`, and `pngquant`. Screenshots for Callout Cadence, Summit Rescue, Funicular Fix, and Fondue Frenzy are not in yet. Drop PNGs in that game's `shots/` folder and rerun the same script.

The games hero files live in `assets/games/hero/` and keep these names: `games_hero_1600x600` and `games_hero_3200x1200`, each as AVIF, WebP, and PNG. The page offers them with width descriptors. `sizes` is `100vw`, and `(max-width: 640px) 59rem` where the hero is cover-cropped to the 22rem frame. Replace the files in place if the art is repainted.

## Games privacy policy

The policy visitors read is the article between `POLICY:START` and `POLICY:END` in `games/privacy/index.html`. To swap in a new approved markdown file:

```bash
python3 scripts/render-games-privacy.py path/to/zum-games-privacy-policy-en.md
```

The script removes HTML comments, keeps the wording, and gives each bold game name in the list an anchor (`#fromage-dash` and the rest). Adding a game is one new bullet in that markdown, or one `<li id="slug">` if you edit the HTML, plus a privacy link on that game's page.

Support on each game page is games@zumproductions.com. The privacy contact on the games policy stays privacy@zumproductions.com.

## Design

Ink `#0B1F2A`, purple `#6D28D9` (hover `#5B21B6`), background `#F8F6F3`. `#8B5CF6` is decorative only. Inter is self-hosted in `assets/fonts/` so the page does not call Google Fonts. The stack falls back to system UI fonts if the file does not load.

Public contact is `hello@zumproductions.com`. `privacy@zumproductions.com` stays on the studio privacy notice, the terms questions line, and the games privacy policy.

## Deploy notes / launch blockers

(a) Deploys are manual SFTP or file-manager uploads. `.htaccess` here is a merge template, never a file to upload. Merge it into the live file. Do not replace the live file, and do not upload README, CHANGELOG, or `scripts/`.

(b) At launch, remove the live `/` to `/en/` rule. It hides the new `index.html`.

(c) This repo has no `robots.txt`. The live one is not in git and has `Disallow: /assets/`, which blocks the new images, fonts, and OG image. At launch, replace the live file with a `robots.txt` that does not disallow `/assets/`, or add one to the repo then.

(d) Consider `ErrorDocument 404 /404/index.html` and a real 404 page so missing URLs return 404. Not built yet.

(e) At launch, remove the games `noindex` meta tags and the `X-Robots-Tag` block, and set the privacy effective date.

(f) Merging PR #3 makes Games public through the nav and the homepage teaser, so merge only on Gil's explicit go.

(g) Devops must confirm the document root and merge `.htaccess` into the live file.

After that merge, `curl -I` these URLs. None of them should return 500:

- `https://zumproductions.com/` (still 301s to `/en/` until blocker (b) is done)
- `https://zumproductions.com/privacy.html` (must not carry `X-Robots-Tag`)
- `https://zumproductions.com/games/`
- `https://zumproductions.com/games/privacy` (expect 301 to the trailing slash)
- `https://zumproductions.com/games/privacy/` (expect 200, plus `X-Robots-Tag` until launch)
- one asset under `https://zumproductions.com/assets/games/` (should carry `X-Robots-Tag: noindex` until launch)
