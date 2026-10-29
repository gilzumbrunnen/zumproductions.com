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

Gil uploads. Devops does not have the SFTP or Manager login. `.htaccess` in this repo is a merge template, never a file to upload.

**Never use mirror, sync, or "delete missing files" in the SFTP client.** That includes FileZilla synchronized browsing, a directory comparison that deletes, `rsync --delete`, and `lftp mirror -R --delete`. Any of those would wipe `/en/` and `/404/` and take the live site down. Upload only. Do not delete anything in the live docroot before launch.

### Manual upload

1. Gil downloads a full backup of the live site to his own disk, `.htaccess` and `robots.txt` included, plus `/en/`, `/404/`, `/404.html`, `/static/`, `/page-data/`, and `favicon.ico`. He also notes the date of the latest automatic backup in Infomaniak Manager. Keep that copy off the server. Do not leave `.htaccess.bak` or a zip in the docroot.
2. He uploads the new files. Files are mode 644, folders are mode 755. Never 777. Transfer binary (or Auto with no line-ending rewrite). `.htaccess`, once edited, stays 644.
3. He edits the live `.htaccess` in place, as the last upload step. Merge the template line by line. Do not replace the live file.
4. Then he runs `scripts/post-merge-curl.sh`. The expected results are in that script. The plain-`http` check has to be run from another network.

### What to upload, in two phases

**Pre-launch:** `games/`, `assets/games/`, `css/`, and `js/` only.

```bash
git archive --format=zip -o /tmp/zumproductions-prelaunch.zip HEAD css js games assets/games
```

**Launch only:** `index.html`, `privacy.html`, `terms.html`, the rest of `assets/` (logos, favicon, font, OG image), and `robots.txt`. `robots.txt` in this repo is launch-only: it allows all crawlers and does not disallow `/assets/`. There is no sitemap, so it has no `Sitemap:` line.

```bash
git archive --format=zip -o /tmp/zumproductions-launch.zip HEAD index.html privacy.html terms.html assets robots.txt
```

Do not upload README, CHANGELOG, `scripts/`, `.git/`, or other dotfiles. `scripts/` and `.gitkeep` are `export-ignore` in `.gitattributes`, so these zips contain no dotfiles. Run the archive on `main` after the merge and record the SHA.

The new `css/styles.css` and `js/nav.js` are not referenced by the 2021 pages, and those paths do not exist on the live site today. Uploading them does not change how the 2021 pages look.

Games pages also ask for files that are not in the pre-launch set: `assets/favicon.png`, `assets/logo-wordmark.svg`, `assets/logo-mark.svg`, `assets/logo-mark.png`, `assets/fonts/inter-latin.woff2` (from the CSS), and, on `/games/` and `/games/privacy/`, `assets/og-image.png`. Until the launch upload, those requests miss and the catch-all sends them to `/404/`. The pages still load; the logo and the self-hosted font do not, and the browser falls back to a system font. Links to `/` still land on the 2021 site, which is fine while `/` redirects to `/en/`. Links to `privacy.html` and `terms.html` also miss until launch and follow the catch-all to `/404/`.

### Rollback

1. Re-upload the saved live `.htaccess` first. That is the only file that changes how existing URLs behave, and it is enough if the new folders are still hidden behind `/en/`.
2. If that is not enough, remove the new folders and pages (`games/`, `assets/games/` or `assets/`, `css/`, `js/`, and, if they were uploaded, `index.html`, `privacy.html`, `terms.html`, `robots.txt`).
3. Last resort: restore from Infomaniak's automatic backups (Manager, Backups). Check the retention shown there before relying on it.

### Launch-day checklist

Do not do these until Gil says the section goes live.

(b) Remove the live `/` to `/en/` rule. It hides the new `index.html`. The commented `^en(/.*)?$` rule in `.htaccess` can then 301 `/en/` and `/en/*` to `/`. Do not enable that rule while `/` still redirects to `/en/`.

(c) Upload this repo's `robots.txt` over the live one. The live file disallows `/assets/`, which blocks the new images, fonts, and OG image.

(d) `ErrorDocument 404` does nothing until the live soft-404 catch-all (the `!-f`/`!-d` rule that 301s to `/404/`) is replaced. The new 404 page is not built yet. When it is, it must use root-absolute paths (`/css/styles.css`, `/assets/...`), because it will be served for any missing URL.

(e) Remove the games `noindex` meta tags and the `X-Robots-Tag` block, and set the privacy effective date. Removing the meta tags is a new commit, then re-upload the eight games HTML files. Run the curl script again and expect no `X-Robots-Tag`.

(f) Merging PR #3 makes Games public through the nav and the homepage teaser on GitHub. On the live server that only happens when `index.html` is uploaded and `/` stops redirecting to `/en/`. Merge only on Gil's explicit go.

(g) Devops must confirm the document root (Infomaniak Manager, Hosting, Sites) before Gil merges `.htaccess` into the live file. Gil does the upload.

(h) Set the `privacy.html` effective date at publish. The games@ mailbox must exist before merge (or switch the games pages and the games policy to privacy@).

After the new 404 works, and only then, remove the Gatsby leftovers: `/en/`, `/404/`, `/404.html`, `/static/`, `/page-data/`, and the root Gatsby bundles. `/404/` loads files from `/static/`, so deleting `/static/` first breaks the old 404. Replace `/favicon.ico` in the same pass. There is no service worker, so no kill-switch file is needed.
