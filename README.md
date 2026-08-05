# spiritofstar.github.io

Source repository for [spiritofstar.github.io](https://spiritofstar.github.io) —
independent research on browser security, memory safety, and privacy engineering.

## Stack

- **Astro 5** — static site generator (`src/pages/`, `src/layouts/`, `src/components/`)
- **astro-typst** — integration for rendering Typst (`.typ`) documents at build time (configured in `astro.config.mjs`)
- **Decap CMS** — git-based CMS at `/admin/` (`public/admin/config.yml`); saving a post commits to `main` and triggers the Pages workflow
- **Pandoc + Typst** — builds the article PDFs (`npm run build:pdfs`)
- Content lives in `src/content/posts/` (Astro content collections)

## Commands

```sh
npm install          # install dependencies
npm run dev          # local dev server
npm run build        # astro build + feed generation (rss.xml, atom.xml, feed.json)
npm run build:pdfs   # pandoc → typst → PDF for each paper (pandoc, or quarto which bundles it)
npm run preview      # serve the built dist/ locally
npm run cms          # local Decap CMS server (optional)
```

## Layout

| Path | Purpose |
| ---- | ------- |
| `src/pages/` | `index.astro` (home), `blog.astro` (sandboxing paper, old URL), `assessment-over-authority.astro`, `responding-to-criticism.astro`, `404.astro` |
| `src/content/posts/` | Markdown papers (frontmatter: title, subtitle, author, date, categories) |
| `scripts/` | `generate-feeds.mjs` (RSS/Atom/JSON feeds), `build-pdfs.sh`, `rehype-citations.mjs` (links `[N]` citations to the references section) |
| `public/` | Static assets: fonts, favicon, robots.txt, sitemap.xml, `.well-known/ai.txt`, Decap CMS admin |

URLs are preserved from the old site (`build.format: 'file'`): the sandboxing
paper keeps `/blog.html`, the others keep `/assessment-over-authority.html` and
`/responding-to-criticism.html`.

## Security

- Content Security Policy is enforced via a `<meta>` tag in
  `src/layouts/BaseLayout.astro` (GitHub Pages does not send server headers).
- The only third-party frame allowed is the Substack newsletter embed.
- `robots.txt` blocks AI crawlers; `.well-known/ai.txt` declares AI data usage.

## Deploy

Pushing to `main` runs `.github/workflows/pages.yml` (Node 20 + Pandoc + Typst),
which builds the site, generates feeds and PDFs into `dist/`, and deploys via
`peaceiris/actions-gh-pages`.
