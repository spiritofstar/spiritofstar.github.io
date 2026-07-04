#set document(
  title: "Comparative Analysis of Sandboxing and Mitigation Philosophies in Mobile User-Agent Architectures",
  author: "Independent Security Research",
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
  Comparative Analysis of Sandboxing and Mitigation\
  Philosophies in Mobile User-Agent Architectures
])
#v(6mm)
#align(center, text(size: 12pt, style: "italic")[
  A Threat-Modeling Analysis of GeckoView and Chromium on Android
])
#v(6mm)
#align(center, text(size: 11pt)[Independent Security Research])
#align(center, text(size: 11pt)[July 2026])
#v(2cm)

#show heading.where(level: 1): it => {
  pagebreak()
  heading(level: 1, numbering: it.numbering, it.body)
}
