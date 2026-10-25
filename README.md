# Zum Productions

Static one-page marketing site for [zumproductions.com](https://zumproductions.com).

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
| `index.html` | Home: nav, hero, three services, contact |
| `privacy.html` | Short privacy notice |
| `terms.html` | Short terms notice |
| `css/styles.css` | Layout and the Painter palette |
| `js/nav.js` | Mobile menu only |
| `assets/` | Logo mark, wordmark, service icons, favicon, OG image, self-hosted Inter |

## Design

Ink `#0B1F2A`, purple `#6D28D9` (hover `#5B21B6`), background `#F8F6F3`. `#8B5CF6` is decorative only. Inter is self-hosted in `assets/fonts/` so the page does not call Google Fonts. The stack falls back to system UI fonts if the file does not load.

Public contact is `hello@zumproductions.com`. `privacy@zumproductions.com` stays on the privacy notice and the terms questions line.
