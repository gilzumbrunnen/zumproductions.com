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
| `assets/` | Logos (`assets/brand/`), service icons, Open Graph images, self-hosted Inter |
| `favicon.ico`, `favicon.svg`, `favicon-32.png`, `favicon-16.png`, `apple-touch-icon-180.png` | Studio favicons, at the site root |
| `games/favicon.svg`, `games/favicon-32.png`, `games/favicon-16.png`, `games/apple-touch-icon-180.png` | Games favicons |
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

Public contact is `hello@zumproductions.com` for the studio (`bonjour@zumproductions.com` on French content). `games@zumproductions.com` covers games. `privacy@zumproductions.com` stays on the studio privacy notice, the terms questions line, and the games privacy policy.

## Logos

Approved lockups are in `assets/brand/`. The SVGs are outlined, so do not retype them, recolour them, or place them on purple.

| File | Use |
|------|-----|
| `zum-productions_light.svg` | Zum Productions, purple and ink. White header. |
| `zum-productions_dark.svg` | Zum Productions, lavender and white. Ink footer. |
| `zum-games_light.svg` | Zum Games, on the games header. |
| `zum-games_dark.svg` | Zum Games, on the games footer. |

Clear space is the padding around the image. For the main logo that is the width of the purple full stop, about 16% of the logo height. For the games logo it is half the cap height of GAMES, about 17% of the logo height. On screen the main logo stays at least 120px wide and the games logo at least 100px wide. The header and footer CSS is above those floors (162px and 133px for the main logo, 208px and 160px for games).

Studio pages use the root favicon set: `favicon.ico`, `favicon.svg`, `favicon-32.png`, `favicon-16.png`, and `apple-touch-icon-180.png`. Games pages use the set in `games/` (`favicon.svg`, `favicon-32.png`, `favicon-16.png`, `apple-touch-icon-180.png`). There is no web manifest.

Open Graph images are 1200×630 on paper `#F8F6F3`, with no effects. `assets/og-image.png` is the studio logo. `assets/og-games.png` is the games logo. Each game page still shares its own feature graphic.

## Deploy notes / launch blockers

Gil uploads. Devops does not have the SFTP or Manager login. `.htaccess` in this repo is a merge template, never a file to upload.

**Never use mirror, sync, or "delete missing files" in the SFTP client.** That includes FileZilla synchronized browsing, a directory comparison that deletes, `rsync --delete`, and `lftp mirror -R --delete`. Any of those would wipe `/en/` and `/404/` and take the live site down. Upload only. Do not delete anything in the live docroot before launch.

### Manual upload

1. Gil downloads a full backup of the live site to his own disk, `.htaccess` and `robots.txt` included, plus `/en/`, `/404/`, `/404.html`, `/static/`, `/page-data/`, and `favicon.ico`. He also notes the date of the latest automatic backup in Infomaniak Manager. Keep that copy off the server. Do not leave `.htaccess.bak` or a zip in the docroot.
2. He uploads the new files. Files are mode 644, folders are mode 755. Never 777. Transfer binary (or Auto with no line-ending rewrite). `.htaccess`, once edited, stays 644.
3. He edits the live `.htaccess` in place, as the last upload step. Merge the template line by line. Do not replace the live file.
4. Then he runs `scripts/post-merge-curl.sh` (phase 1, the default). After launch he runs `scripts/post-merge-curl.sh https://zumproductions.com 2`. Against a local static server, `scripts/post-merge-curl.sh http://127.0.0.1:8000 local` checks the logo, favicon, and OG URLs (200 and content type) without the Apache redirects. The script prints PASS or FAIL per check and exits 1 on any mismatch. Add `--check-http` only from another network; that flag checks the plain-`http` to `https` redirect.

### What to upload, in two phases

**Pre-launch:** `games/` (including the games favicons), `assets/games/`, `assets/brand/`, `css/`, `js/`, `assets/fonts/` (`inter-latin.woff2`), `assets/og-image.png`, and `assets/og-games.png`.

```bash
git archive --format=zip -o /tmp/zumproductions-prelaunch.zip HEAD css js games assets/games assets/brand assets/fonts assets/og-image.png assets/og-games.png
```

Until launch, a request for `/favicon.ico` still returns the old live icon. Games pages do not use that URL. They point at `/games/favicon.svg`, which is uploaded with `games/`.

**Launch only:** `index.html`, `privacy.html`, `terms.html`, `404.html`, the studio favicon set (`favicon.ico`, `favicon.svg`, `favicon-32.png`, `favicon-16.png`, `apple-touch-icon-180.png`), `css/`, `js/`, the rest of `assets/`, and `robots.txt`. `404.html` loads `/css/styles.css` and `/js/nav.js`, so those two directories are in this zip as well. The launch upload is self-contained, and it expects the pre-launch upload to be done already. `robots.txt` allows all crawlers and does not disallow `/assets/`. There is no sitemap, so it has no `Sitemap:` line. `favicon.ico` is the approved 16, 32 and 48 pixel icon, for the launch swap of the old icon. `404.html` is not wired up until the catch-all is replaced.

```bash
git archive --format=zip -o /tmp/zumproductions-launch.zip HEAD index.html privacy.html terms.html 404.html favicon.ico favicon.svg favicon-32.png favicon-16.png apple-touch-icon-180.png css js assets robots.txt
```

Do not upload README, CHANGELOG, `scripts/`, `.git/`, or other dotfiles. `scripts/` and `.gitkeep` are `export-ignore` in `.gitattributes`, so these zips contain no dotfiles. Run the archive on `main` after the merge and record the SHA.

The new `css/styles.css` and `js/nav.js` are not referenced by the 2021 pages, and those paths do not exist on the live site today. Uploading them does not change how the 2021 pages look.

After the pre-launch upload, the only games-page links that still miss are `index.html`, `privacy.html`, and `terms.html`. They follow the catch-all to the old `/404/`. Links to `/` still land on the 2021 site, which is fine while `/` redirects to `/en/`.

### Rollback

1. Re-upload the saved live `.htaccess` first. That is the only file that changes how existing URLs behave. `/games/` can be reached directly, but it is noindexed and not linked from the live site. Restoring the saved file removes the privacy redirect and the `X-Robots-Tag` header. The pages keep their meta noindex.
2. If that is not enough, delete only files that were new: `games/`, `assets/brand/`, `assets/og-image.png`, `assets/og-games.png`, `assets/fonts/`, `css/`, `js/`, and, if they were uploaded, `index.html`, `privacy.html`, and `terms.html`. For any launch file that replaces an existing live file, restore it from the backup instead of deleting it: `favicon.ico`, `robots.txt`, and `404.html` if one exists live. Also remove the other studio favicon files if they were uploaded (`favicon.svg`, `favicon-32.png`, `favicon-16.png`, `apple-touch-icon-180.png`). Do not delete `robots.txt` and leave the site without one.
3. Last resort: restore from Infomaniak's automatic backups (Manager, Backups). Check the retention shown there before relying on it.

### Launch-day checklist

Do not do these until Gil says the section goes live.

(b) Remove the live `/` to `/en/` rule. It hides the new `index.html`. The commented `^en(/.*)?$` rule in `.htaccess` can then 301 `/en/` and `/en/*` to `/`. Do not enable that rule while `/` still redirects to `/en/`.

(c) Upload this repo's `robots.txt` over the live one. The live file disallows `/assets/`, which blocks the new images, fonts, and OG image. Also upload the studio favicon set from the repo root (`favicon.ico`, `favicon.svg`, `favicon-32.png`, `favicon-16.png`, `apple-touch-icon-180.png`) over the old icon.

(d) `ErrorDocument 404 /404.html` does nothing until the live soft-404 catch-all (the `!-f`/`!-d` rule that 301s to `/404/`) is replaced. `404.html` is in the repo and uses root-absolute paths only. The `ErrorDocument` line in `.htaccess` is commented and sits outside `<IfModule mod_rewrite.c>`, because it is a core directive. Do not enable it beside the old catch-all.

(e) Remove the games `noindex` meta tags and the `X-Robots-Tag` block, and set the privacy effective date. Removing the meta tags is a new commit, then re-upload the eight games HTML files:

```bash
git archive --format=zip -o /tmp/zumproductions-games-html.zip HEAD games/index.html games/privacy/index.html games/fromage-dash/index.html games/callout-cadence/index.html games/alp-graze/index.html games/summit-rescue/index.html games/funicular-fix/index.html games/fondue-frenzy/index.html
```

Run `scripts/post-merge-curl.sh https://zumproductions.com 2` and expect no `X-Robots-Tag`.

When the commented hardening block is merged, its rewrite rules go before the live catch-all. Replace the live `Strict-Transport-Security` line. Do not add a second one: the later line wins.

(f) Merging PR #3 makes Games public through the nav and the homepage teaser on GitHub. On the live server that only happens when `index.html` is uploaded and `/` stops redirecting to `/en/`. Merge only on Gil's explicit go.

(g) Devops must confirm the document root (Infomaniak Manager, Hosting, Sites) before Gil merges `.htaccess` into the live file. Gil does the upload.

(h) Set the `privacy.html` effective date at publish. The games@ mailbox must exist before merge (or switch the games pages and the games policy to privacy@).

After the new 404 works, and only then, remove the Gatsby leftovers: `/en/`, `/404/`, `/404.html`, `/static/`, `/page-data/`, and the root Gatsby bundles. `/404/` loads files from `/static/`, so deleting `/static/` first breaks the old 404. `favicon.ico` from this repo replaces the old icon in the same pass. There is no service worker, so no kill-switch file is needed.
