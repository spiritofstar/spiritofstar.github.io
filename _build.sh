#!/bin/sh
# Build HTML and PDF, output to _output/ for GitHub Pages
# Usage: sh _build.sh

set -e

echo "=== Generating site components and feeds ==="
python3 _build.py

echo "=== Copying static files ==="
cp index.html atom.xml feed.json rss.xml robots.txt sitemap.xml _output/
cp -r .well-known _output/.well-known

build_paper() {
  local md="$1"
  local slug="$2"
  local title="$3"
  local author="$4"
  local subtitle="$5"

  echo "=== Building HTML: $slug ==="
  quarto pandoc "$md" \
    -o "_output/$slug.html" --template=_template.html -s \
    --toc --toc-depth=2 --section-divs --mathjax

  echo "=== Building PDF: $slug ==="
  quarto pandoc "$md" \
    -o "_output/$slug.typ" --to typst
  sed -i '' 's/#horizontalrule/#line()/g' "_output/$slug.typ"

  cat > /tmp/preamble.typ << TYPEOF
#set document(
  title: "$title",
  author: "$author",
)
#set page(
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  numbering: "1",
  number-align: center,
)
#set text(font: "Times New Roman", size: 11pt)
#set par(justify: true)
#show math.equation: set text(size: 9.5pt)
#set heading(numbering: "1.1")

#align(center, text(size: 16pt, weight: "bold")[
  $title
])
#v(6mm)
#align(center, text(size: 12pt, style: "italic")[
  $subtitle
])
#v(6mm)
#align(center, text(size: 11pt)[$author])
#align(center, text(size: 11pt)[July 2026])
#v(2cm)

#show heading.where(level: 1): it => {
  pagebreak()
  heading(level: 1, numbering: it.numbering, it.body)
}
TYPEOF

  cat /tmp/preamble.typ > /tmp/combined.typ
  cat "_output/$slug.typ" >> /tmp/combined.typ
  mv /tmp/combined.typ "_output/$slug.typ"
  typst compile "_output/$slug.typ"
}

build_paper \
  "sandboxing-mitigation-comparative-analysis.md" \
  "blog" \
  "Comparative Analysis of Sandboxing and Mitigation Philosophies in Mobile User-Agent Architectures" \
  "Independent Security Research" \
  "A Threat-Modeling Analysis of GeckoView and Chromium on Android"

build_paper \
  "responding-to-criticism.md" \
  "responding-to-criticism" \
  "Responding to Security Criticism: Corrections and Reflections" \
  "Independent Security Research" \
  "A Response to Technical Criticisms of the Browser Security Analysis"

echo "=== Done ==="
echo "Output in _output/"
