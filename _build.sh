#!/bin/sh
# Build HTML and PDF, copy to docs/ for GitHub Pages (docs/ method)
# Usage: sh _build.sh

set -e

echo "=== Building HTML ==="
quarto pandoc sandboxing-mitigation-comparative-analysis.md \
  -o _output/blog.html --template=_template.html -s \
  --toc --toc-depth=2 --section-divs --katex

echo "=== Building PDF (Typst) ==="
quarto pandoc sandboxing-mitigation-comparative-analysis.md \
  -o _output/sandboxing-mitigation-comparative-analysis.typ --to typst
sed -i '' 's/#horizontalrule/#line()/g' \
  _output/sandboxing-mitigation-comparative-analysis.typ
cat _output/_typst-preamble.typ > /tmp/combined.typ
cat _output/sandboxing-mitigation-comparative-analysis.typ >> /tmp/combined.typ
mv /tmp/combined.typ _output/sandboxing-mitigation-comparative-analysis.typ
typst compile _output/sandboxing-mitigation-comparative-analysis.typ

echo "=== Copying to docs/ for GitHub Pages ==="
mkdir -p docs
cp _output/blog.html docs/
cp _output/atom.xml docs/
cp _output/feed.json docs/
cp _output/sandboxing-mitigation-comparative-analysis.pdf docs/
echo "Done. Push docs/ to GitHub to publish."
