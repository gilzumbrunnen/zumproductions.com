#!/usr/bin/env python3
"""Render the games privacy article from an approved markdown file.

Swaps the policy body in games/privacy/index.html. HTML comments in the
markdown are removed. Wording is kept. Each list item that is only a bold
game name becomes one line:

    <li id="fromage-dash"><strong>Fromage Dash</strong></li>

Usage, from the repo root:

    python3 scripts/render-games-privacy.py path/to/zum-games-privacy-policy-en.md

Exits non-zero when the article text does not match the markdown wording.
"""

from __future__ import annotations

import re
import sys
import unicodedata
from html import unescape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAGE = ROOT / "games" / "privacy" / "index.html"
START = "<!-- POLICY:START -->"
END = "<!-- POLICY:END -->"
EMAIL = "privacy@zumproductions.com"
DATE = "[DD Month YYYY]"


def slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def inline(text: str) -> str:
    text = (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)", r"<em>\1</em>", text)
    text = text.replace(
        EMAIL,
        f'<a href="mailto:{EMAIL}">{EMAIL}</a>',
    )
    text = text.replace(
        "https://policies.google.com/privacy",
        '<a href="https://policies.google.com/privacy">https://policies.google.com/privacy</a>',
    )
    text = text.replace(
        DATE,
        '<mark class="policy-date" title="Unset. Replace this on the day the policy is approved for publishing.">'
        f"{DATE}</mark>",
    )
    return text


def render_article(markdown: str) -> str:
    markdown = re.sub(r"<!--.*?-->", "", markdown, flags=re.S).strip()
    blocks: list[list[str]] = []
    buf: list[str] = []
    for line in markdown.splitlines():
        if line.strip() == "" or line.strip() == "---":
            if buf:
                blocks.append(buf)
                buf = []
            if line.strip() == "---":
                blocks.append(["---"])
        else:
            buf.append(line.rstrip())
    if buf:
        blocks.append(buf)

    parts = ['<article id="policy" class="prose policy">']
    for block in blocks:
        if len(block) == 1 and block[0].strip() == "---":
            parts.append("  <hr>")
            continue
        if block[0].startswith("## "):
            parts.append(f"  <h2>{inline(block[0][3:].strip())}</h2>")
            continue
        if block[0].startswith("# "):
            parts.append(f"  <h1>{inline(block[0][2:].strip())}</h1>")
            continue
        if all(line.startswith("- ") for line in block):
            items = []
            for line in block:
                raw = line[2:].strip()
                whole = re.fullmatch(r"\*\*(.+)\*\*", raw)
                if whole:
                    name = whole.group(1)
                    items.append(
                        f'    <li id="{slug(name)}"><strong>{inline(name)}</strong></li>'
                    )
                else:
                    items.append(f"    <li>{inline(raw)}</li>")
            parts.append("  <ul>\n" + "\n".join(items) + "\n  </ul>")
            continue
        body = "<br>\n  ".join(inline(line.strip()) for line in block)
        parts.append(f"  <p>{body}</p>")
    parts.append("</article>")
    article = "\n".join(parts)
    return "\n".join(
        ("      " + line) if line else "" for line in article.splitlines()
    )


def plain_markdown(markdown: str) -> str:
    text = re.sub(r"<!--.*?-->", "", markdown, flags=re.S)
    lines = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped == "---":
            continue
        stripped = re.sub(r"^#{1,6}\s+", "", stripped)
        stripped = re.sub(r"^-\s+", "", stripped)
        stripped = stripped.replace("*", "")
        lines.append(stripped)
    return re.sub(r"\s+", " ", " ".join(lines)).strip()


def plain_html(article: str) -> str:
    text = re.sub(r"<br\s*/?>", " ", article, flags=re.I)
    text = re.sub(r"<[^>]+>", "", text)
    text = unescape(text)
    return re.sub(r"\s+", " ", text).strip()


def wording_diff(markdown: str, article: str) -> str:
    left = plain_markdown(markdown)
    right = plain_html(article)
    if left == right:
        return ""
    # Show the first mismatch so a bad swap is obvious.
    n = min(len(left), len(right))
    i = next((k for k in range(n) if left[k] != right[k]), n)
    start = max(0, i - 40)
    return (
        "Policy wording does not match the markdown.\n"
        f"markdown: {left[start:i + 80]!r}\n"
        f"html:     {right[start:i + 80]!r}"
    )


def replace_region(page: str, article: str) -> str:
    if START not in page or END not in page:
        raise SystemExit(f"{PAGE} is missing {START} / {END} markers")
    pre, rest = page.split(START, 1)
    _, post = rest.split(END, 1)
    return f"{pre}{START}\n{article}\n      {END}{post}"


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: python3 scripts/render-games-privacy.py POLICY.md")
    source = Path(sys.argv[1])
    markdown = source.read_text(encoding="utf-8")
    # Keep the approved characters (en dash, arrows). Reject a mojibake swap.
    markdown = unicodedata.normalize("NFC", markdown)
    article = render_article(markdown)
    diff = wording_diff(markdown, article)
    if diff:
        raise SystemExit(diff)
    page = PAGE.read_text(encoding="utf-8")
    PAGE.write_text(replace_region(page, article), encoding="utf-8")
    names = re.findall(r'<li id="([^"]+)">', article)
    print(f"Rendered {PAGE.relative_to(ROOT)} ({len(names)} game anchors)")
    print("Wording matches the markdown.")
    print("Anchors: " + ", ".join(f"#{name}" for name in names))


if __name__ == "__main__":
    main()
