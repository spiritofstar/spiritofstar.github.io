#!/usr/bin/env python3
"""Post-process blog.html to make in-text citations [N] clickable links to references."""

import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "_output/blog.html"

with open(path, "r", encoding="utf-8") as f:
    html = f.read()

# --- Step 1: Add id attributes to reference items ---
ref_start = html.find('<section id="references"')
if ref_start > 0:
    # Find the matching </section> by tracking nesting depth
    depth = 0
    ref_end = ref_start
    for pos in range(ref_start, len(html)):
        if html.startswith("</section", pos):
            depth -= 1
            if depth == 0:
                ref_end = pos + 10  # len("</section>")
                break
        elif html.startswith("<section", pos):
            depth += 1

    ref_section = html[ref_start:ref_end]

    def add_ref_id(m):
        num = m.group(1)
        return f'<p id="ref-{num}">[{num}]'

    ref_section_linked = re.sub(r"<p>\s*\[(\d+)\]", add_ref_id, ref_section)

    if ref_section_linked != ref_section:
        html = html[:ref_start] + ref_section_linked + html[ref_end:]
        print("Added id attributes to reference items")
    else:
        print("No reference items found to id (already done or pattern mismatch)")
else:
    print("No references section found")

# --- Step 2: Link in-text citations [N] in the body (before references section) ---
body_end = ref_start if ref_start > 0 else len(html)
body = html[:body_end]
rest = html[body_end:]

# Process body text only (not inside HTML tags or existing anchors)
parts = re.split(r"(<[^>]*>)", body)
changed = False
for i, part in enumerate(parts):
    if not part.startswith("<"):
        # Link [N] patterns, including composite ranges [27]-[30]
        new = re.sub(
            r"\[(\d+)\]",
            lambda m: (
                f'<a href="#ref-{m.group(1)}" class="citation">[{m.group(1)}]</a>'
            ),
            part,
        )
        if new != part:
            changed = True
            parts[i] = new

if changed:
    body = "".join(parts)
    html = body + rest
    with open(path, "w", encoding="utf-8") as f:
        f.write(html)
    print("Linked in-text citations")

    # Verify
    href_count = html.count('href="#ref-')
    print(f"Total citation links: {href_count}")
else:
    print("No citations to link")
