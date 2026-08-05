// Typst feature demo — rendered into the site by astro-typst (SVG mode).
// The standalone PDF build (scripts/build-pdfs.sh) wraps this file with
// page setup via demo-page.typ; no `#set page` here because astro-typst
// embeds the rendered document into the web page.

#set text(font: "Libertinus Serif", size: 11pt, lang: "en")
#set par(justify: true)
#set heading(numbering: "1.")

= Introduction

This document exercises every major typesetting feature to compare #strong[PDF] (Typst) and _HTML_ output side-by-side.

= Headings

== Third-level heading

=== Fourth-level heading

#lorem(18)

= Text Formatting

#strong[Bold], _italic_, #strong[_bold-italic_]

#strike[Strikethrough], #smallcaps[Small Caps], #underline[Underlined]

`inline code`, Super#super[script] and Sub#sub[script]

= Lists

== Ordered

+ First item
+ Second item
  + Nested A
  + Nested B
+ Third item

== Unordered

- Alpha
- Bravo
  - Charlie nested
    - Delta deeper

== Term list

/ Term one: Definition of the first term.
/ Term two: Definition of the second term.

= Links

External: #link("https://typst.app")

Internal: See @sec:math for mathematics, @sec:tables for tables.

= Mathematics <sec:math>

Inline: $E = m c^2$ and $x = (-b +- sqrt(b^2 - 4a c)) / (2a)$

Display:

$ integral_0^oo e^(-x^2) dif x = sqrt(pi) / 2 $

$ mat(1, 0; 0, 1) quad sum_(k=0)^n binom(n, k) = 2^n $

$ f(x) = { x^2, x > 0; 0, x = 0; -x^2, "otherwise" } $

$ lim_(n -> oo) (1 + 1/n)^n = e $

= Tables <sec:tables>

#figure(
  table(
    columns: (1fr, 2fr, 1fr),
    inset: 8pt,
    stroke: 0.5pt + black,
    [], [#strong[Feature]], [#strong[Status]],
    [1], [Headings], [#emoji.checkmark],
    [2], [Math], [#emoji.checkmark],
    [3], [Tables], [#emoji.checkmark],
  ),
  caption: [Simple Table],
)

= Code Blocks

```rust
fn fibonacci(n: u32) -> u32 {
    match n {
        0 => 0,
        1 => 1,
        _ => fibonacci(n - 1) + fibonacci(n - 2),
    }
}
```

```python
def quicksort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + middle + quicksort(right)
```

= Block Quotes

#quote(block: true)[
  Typst is a modern typesetting system that combines the power of LaTeX with the ease of Markdown.
]

#quote(block: true, attribution: [R. Bringhurst])[
  Good typography is about creating a comfortable reading experience through careful attention to spacing, proportion, and rhythm.
]

= Footnotes

A sentence with a footnote.#footnote[This is the footnote content providing supplemental information.]

Another footnote reference.#footnote[A longer footnote that demonstrates wrapping behavior across lines at the bottom of the page.]

= Horizontal Rules

Above.

#line(length: 100%, stroke: 1pt + black)

Between.

#line(length: 100%, stroke: 1pt + black)

Below.

= Figures

#figure(
  image("assets/placeholder.svg", width: 50%),
  caption: [Placeholder diagram showing a simple flow relationship.],
)

= Colors

#text(fill: red)[Red] #text(fill: teal)[Teal] #text(fill: blue)[Blue]
#text(fill: purple)[Purple] #text(fill: green)[Green] #text(fill: orange)[Orange]

#text(fill: rgb("#2E86AB"))[Hex] #text(fill: rgb("#A23B72"))[Colors] #text(fill: rgb("#F18F01"))[Here]

= Special Characters

sym: #sym.arrow.r #sym.arrow.l #sym.checkmark

unicode: © ® ™ — – … • · § ¶ † ‡ µ Ω ∞

emoji: 😀 🎉 🚀 ❤️ ✅ 📚 ✨ ⚡ 🎨 🐧

= Feature Summary

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    inset: 6pt,
    stroke: 0.5pt + black,
    [\#], [#strong[Feature Category]], [#strong[Status]],
    [1], [Headings], [#emoji.checkmark],
    [2], [Text Formatting], [#emoji.checkmark],
    [3], [Lists], [#emoji.checkmark],
    [4], [Links], [#emoji.checkmark],
    [5], [Mathematics], [#emoji.checkmark],
    [6], [Tables], [#emoji.checkmark],
    [7], [Code Blocks], [#emoji.checkmark],
    [8], [Block Quotes], [#emoji.checkmark],
    [9], [Footnotes], [#emoji.checkmark],
    [10], [Horizontal Rules], [#emoji.checkmark],
    [11], [Figures & Images], [#emoji.checkmark],
    [12], [Colors], [#emoji.checkmark],
    [13], [Special Characters], [#emoji.checkmark],
  ),
  caption: [All major typesetting features tested in this document.],
)
