#!/bin/sh
# Build the paper PDFs and the Typst demo PDF into dist/.
# Requires: pandoc, typst. Run after `npm run build` (astro build output
# must exist at dist/).
#
# Port of the old _build.sh: markdown -> pandoc -> typst -> PDF, with the
# classic page setup (Times New Roman 11pt, 2.5cm margins, centered
# title/subtitle/author block).

set -e
cd "$(dirname "$0")/.."

# pandoc can come standalone or bundled with Quarto (`quarto pandoc`).
if command -v pandoc >/dev/null 2>&1; then
  PANDOC=pandoc
elif command -v quarto >/dev/null 2>&1; then
  PANDOC="quarto pandoc"
else
  echo "pandoc (or quarto, which bundles it) is required" >&2
  exit 1
fi
command -v typst >/dev/null 2>&1 || { echo "typst is required (brew install typst)"; exit 1; }

mkdir -p dist

build_paper() {
  md="$1"
  slug="$2"
  title="$3"
  author="$4"
  subtitle="$5"

  echo "=== Building PDF: $slug ==="
  $PANDOC "$md" -o "/tmp/$slug.typ" --to typst
  sed -i '' 's/#horizontalrule/#line()/g' "/tmp/$slug.typ" 2>/dev/null || \
  sed -i 's/#horizontalrule/#line()/g' "/tmp/$slug.typ"

  cat > "/tmp/$slug-preamble.typ" <<TYPEOF
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

  cat "/tmp/$slug-preamble.typ" > "/tmp/$slug-combined.typ"
  cat "/tmp/$slug.typ" >> "/tmp/$slug-combined.typ"
  typst compile "/tmp/$slug-combined.typ" "dist/$slug.pdf"
}

build_paper \
  "src/content/posts/sandboxing-mitigation-comparative-analysis.md" \
  "blog" \
  "Comparative Analysis of Sandboxing and Mitigation Philosophies in Mobile User-Agent Architectures" \
  "Independent Security Research" \
  "A Threat-Modeling Analysis of GeckoView and Chromium on Android"

build_paper \
  "src/content/posts/responding-to-criticism.md" \
  "responding-to-criticism" \
  "Browser Security Analysis: New Discoveries and Reaffirmed Findings" \
  "Independent Security Research" \
  "A Follow-Up Investigation of Mobile Browser Security Architectures"

build_paper \
  "src/content/posts/assessment-over-authority.md" \
  "assessment-over-authority" \
  "Assessment over Authority: Methodology, Threat Modeling, and the False Binary in Browser Security" \
  "spiritofstar" \
  "Why security assessment requires threat modeling, not vendor loyalty"

echo "=== Building PDF: demo ==="
typst compile "src/typst/demo-page.typ" "dist/demo.pdf"

echo "=== Done — PDFs written to dist/ ==="
