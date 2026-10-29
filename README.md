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

The games pages are not published. They send `noindex`. The live host is Apache and currently sends unknown paths such as `/games/privacy` to `/404/`. `.htaccess` at the repo root redirects that exact path to `/games/privacy/` and sets `X-Robots-Tag: noindex` on `/games/` and `/assets/games/`. Devops needs to confirm that file is the document root config, and that the redirect runs before the existing 404 rule. Remove the noindex header at launch. Python's static server still adds the slash on its own.

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

The games hero files live in `assets/games/hero/` and keep these names: `games_hero_1600x600` and `games_hero_3200x1200`, each as AVIF, WebP, and PNG. The page offers them with width descriptors and `sizes="100vw"`. Replace the files in place if the art is repainted.

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
