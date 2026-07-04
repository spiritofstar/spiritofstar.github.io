#!/usr/bin/env python3
"""
Build helper for spiritofstar research blog.

1. Injects navigation partial (_nav.html) into HTML source files
2. Generates RSS, Atom, and JSON feeds from Markdown frontmatter
"""

import html as htmlmod
import json
import os
import re
from datetime import datetime, timezone
from email.utils import formatdate
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.abspath(__file__))
SITE_URL = "https://spiritofstar.github.io"
SITE_TITLE = "spiritofstar"
SITE_DESC = (
    "Independent research on browser security, memory safety, and privacy engineering"
)
AUTHOR = "spiritofstar"
FEED_TAG = "tag:spiritofstar.github.io"


# ── Frontmatter parser ──


def parse_frontmatter(text):
    """Minimal YAML frontmatter parser for flat keys and lists."""
    m = re.match(r"^\s*---\s*\n(.*?)\n---", text, re.DOTALL)
    if not m:
        return {}, text
    fm, body = {}, text[m.end() :]
    key = None
    for line in m.group(1).split("\n"):
        # List item:   - value
        if line.strip().startswith("- ") and key:
            val = line.strip("- ").strip().strip('"').strip("'")
            fm.setdefault(key, []).append(val)
        # Key-value: key: value
        elif ":" in line and not line.startswith(" "):
            k, _, v = line.partition(":")
            key = k.strip()
            v = v.strip().strip('"').strip("'")
            if v:
                fm[key] = v
            # If no value, key is tracked for potential list items below
            # but not added to fm (handled by setdefault in list branch)
        # Nested keys under a section (skipped)
        pass
    return fm, body


def extract_abstract(body):
    """Extract text from ## Abstract section."""
    m = re.search(r"## Abstract\s*\n\n(.*?)(?:\n\n---|\n## )", body, re.DOTALL)
    return m.group(1).strip() if m else SITE_DESC


# ── Nav injection ──


def inject_nav():
    nav_path = os.path.join(ROOT, "_nav.html")
    if not os.path.exists(nav_path):
        print("  ! _nav.html not found, skipping nav injection")
        return

    with open(nav_path) as f:
        nav_html = f.read().rstrip("\n")

    for fn in ("index.html", "_template.html"):
        path = os.path.join(ROOT, fn)
        if not os.path.exists(path):
            continue
        with open(path) as f:
            content = f.read()
        if "<!-- NAV -->" not in content:
            print(f"  ! No <!-- NAV --> placeholder in {fn}, skipping")
            continue
        content = content.replace("<!-- NAV -->", nav_html)
        with open(path, "w") as f:
            f.write(content)
        print(f"  ✓ {fn}")


# ── Feed generation ──


def generate_feeds():
    posts = []
    for fn in sorted(os.listdir(ROOT)):
        if not fn.endswith(".md") or fn.startswith("_"):
            continue

        with open(os.path.join(ROOT, fn)) as f:
            raw = f.read()
        fm, body = parse_frontmatter(raw)
        if not fm.get("title"):
            continue

        abstract = extract_abstract(body)

        # Parse date (format: "July 2026")
        dt = datetime.now(timezone.utc)
        if fm.get("date"):
            try:
                dt = datetime.strptime(fm["date"], "%B %Y").replace(tzinfo=timezone.utc)
            except ValueError:
                pass

        slug = fn.replace(".md", "")
        atom_date = dt.strftime("%Y-%m-%dT%H:%M:%SZ")
        tag_id = f"{FEED_TAG},{dt.strftime('%Y-%m-%d')}:/blog/{slug}"

        # Map filename to URL: first paper uses blog.html for brevity
        if slug == "sandboxing-mitigation-comparative-analysis":
            page_url = f"{SITE_URL}/blog.html"
        else:
            page_url = f"{SITE_URL}/{slug}.html"

        posts.append(
            {
                "title": fm["title"],
                "url": page_url,
                "guid": tag_id,
                "abstract": abstract,
                "atom_date": atom_date,
                "pub_date": formatdate(
                    timeval=dt.timestamp(), localtime=False, usegmt=True
                ),
                "categories": fm.get("categories", []),
            }
        )

    if not posts:
        print("  ! No posts found")
        return

    posts.sort(key=lambda p: p["atom_date"], reverse=True)

    # ── RSS 2.0 ──
    items_rss = ""
    for p in posts:
        cat_tags = "".join(
            f"      <category>{escape(c)}</category>\n" for c in p["categories"]
        )
        items_rss += (
            "    <item>\n"
            f"      <title>{escape(p['title'])}</title>\n"
            f"      <link>{escape(p['url'])}</link>\n"
            f"      <guid>{escape(p['guid'])}</guid>\n"
            f"      <pubDate>{p['pub_date']}</pubDate>\n"
            f"{cat_tags}"
            "      <description><![CDATA[\n"
            f"{p['abstract']}\n"
            "\n"
            f'<a href="{escape(p["url"])}">Read the full paper &rarr;</a>\n'
            "      ]]></description>\n"
            "    </item>\n"
        )

    rss = (
        '<?xml version="1.0" encoding="utf-8" ?>\n'
        '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">\n'
        "  <channel>\n"
        f"    <title>{escape(SITE_TITLE)}</title>\n"
        f"    <description>{escape(SITE_DESC)}</description>\n"
        f"    <link>{SITE_URL}/</link>\n"
        "    <language>en</language>\n"
        f"    <lastBuildDate>{posts[0]['pub_date']}</lastBuildDate>\n"
        f'    <atom:link href="{SITE_URL}/rss.xml" rel="self" '
        'type="application/rss+xml" />\n'
        f"{items_rss}"
        "  </channel>\n"
        "</rss>\n"
    )
    with open(os.path.join(ROOT, "rss.xml"), "w") as f:
        f.write(rss)
    print("  ✓ rss.xml")

    # ── Atom ──
    entries_atom = ""
    for p in posts:
        cat_atom = "".join(
            f'    <category term="{escape(c)}" />\n' for c in p["categories"]
        )
        entries_atom += (
            "  <entry>\n"
            f"    <title>{escape(p['title'])}</title>\n"
            f'    <link href="{escape(p["url"])}" rel="alternate" '
            'type="text/html" />\n'
            f"    <published>{p['atom_date']}</published>\n"
            f"    <updated>{p['atom_date']}</updated>\n"
            f"{cat_atom}"
            f"    <id>{escape(p['guid'])}</id>\n"
            '    <summary type="html"><![CDATA[\n'
            f"{p['abstract']}\n"
            "    ]]></summary>\n"
            f'    <content type="html" src="{escape(p["url"])}" />\n'
            "  </entry>\n"
        )

    atom = (
        '<?xml version="1.0" encoding="utf-8" ?>\n'
        '<feed xmlns="http://www.w3.org/2005/Atom">\n'
        f"  <title>{escape(SITE_TITLE)}</title>\n"
        f"  <subtitle>{escape(SITE_DESC)}</subtitle>\n"
        f'  <link href="{SITE_URL}/atom.xml" rel="self" />\n'
        f'  <link href="{SITE_URL}/" rel="alternate" type="text/html" />\n'
        f"  <updated>{posts[0]['atom_date']}</updated>\n"
        f"  <id>{FEED_TAG},2026-07-04:/</id>\n"
        "  <author>\n"
        f"    <name>{AUTHOR}</name>\n"
        "  </author>\n"
        "  <rights>CC BY 4.0</rights>\n"
        "\n"
        f"{entries_atom}"
        "</feed>\n"
    )
    with open(os.path.join(ROOT, "atom.xml"), "w") as f:
        f.write(atom)
    print("  ✓ atom.xml")

    # ── JSON Feed ──
    items_json = []
    for p in posts:
        items_json.append(
            {
                "id": p["guid"],
                "url": p["url"],
                "title": p["title"],
                "summary": p["abstract"],
                "content_html": (
                    f"<p>{htmlmod.escape(p['abstract'])}</p>"
                    f'<p><a href="{p["url"]}">Read the full paper →</a></p>'
                ),
                "date_published": p["atom_date"],
                "date_modified": p["atom_date"],
                "tags": p["categories"],
            }
        )
    feed = {
        "version": "https://jsonfeed.org/version/1.1",
        "title": SITE_TITLE,
        "description": SITE_DESC,
        "home_page_url": f"{SITE_URL}/",
        "feed_url": f"{SITE_URL}/feed.json",
        "authors": [{"name": AUTHOR}],
        "language": "en",
        "items": items_json,
    }
    with open(os.path.join(ROOT, "feed.json"), "w") as f:
        json.dump(feed, f, indent=2)
    print("  ✓ feed.json")


# ── Main ──


def main():
    print("=== spiritofstar build helper ===")
    print("\n--- Injecting navigation ---")
    inject_nav()
    print("\n--- Generating feeds ---")
    generate_feeds()
    print("\n=== Done ===")


if __name__ == "__main__":
    main()
