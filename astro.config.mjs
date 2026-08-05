// @ts-check
import { defineConfig } from 'astro/config';
import { typst } from 'astro-typst';
import rehypeCitations from './scripts/rehype-citations.mjs';

// https://astro.build/config
export default defineConfig({
  site: 'https://spiritofstar.github.io',
  output: 'static',
  // Emit real .html files so existing URLs (blog.html, …) keep working on GitHub Pages.
  build: {
    format: 'file',
  },
  markdown: {
    // Make in-text citations like [6] and [27]-[30] link to the References section.
    rehypePlugins: [rehypeCitations],
  },
  vite: {
    ssr: {
      external: ['@myriaddreamin/typst-ts-node-compiler'],
    },
  },
  integrations: [
    typst({
      options: {
        remPx: 14,
      },
      target: (id) =>
        id.endsWith('.html.typ') || id.includes('/html/') ? 'html' : 'svg',
    }),
  ],
});
