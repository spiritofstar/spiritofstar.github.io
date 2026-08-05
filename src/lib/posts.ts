import type { CollectionEntry } from 'astro:content';

export const SITE_TITLE = 'spiritofstar';
export const SITE_URL = 'https://spiritofstar.github.io';
export const SITE_DESC =
  'Independent research on browser security, memory safety, and privacy engineering';

/** Old site order for posts published in the same month. */
const LEGACY_ORDER = [
  'assessment-over-authority',
  'sandboxing-mitigation-comparative-analysis',
  'responding-to-criticism',
];

/** URL scheme from the old site: the sandboxing paper lives at /blog.html. */
export function postUrl(post: CollectionEntry<'posts'>): string {
  return post.id === 'sandboxing-mitigation-comparative-analysis'
    ? '/blog.html'
    : `/${post.id}.html`;
}

/** PDF location (built by scripts/build-pdfs.sh into dist/). */
export function pdfUrl(post: CollectionEntry<'posts'>): string {
  return post.id === 'sandboxing-mitigation-comparative-analysis'
    ? '/blog.pdf'
    : `/${post.id}.pdf`;
}

/** Text of the "## Abstract" section, or the site description as a fallback. */
export function abstractOf(post: CollectionEntry<'posts'>): string {
  const body = post.body ?? '';
  const m = /^##\s+Abstract[^\n]*\n+([\s\S]*?)(?=\n## |\n---|\s*$)/im.exec(body);
  if (!m) return SITE_DESC;
  return m[1].trim().replace(/\s+/g, ' ');
}

/** Posts sorted newest-first, preserving the old site's intra-month order. */
export function sortedPosts(posts: CollectionEntry<'posts'>[]): CollectionEntry<'posts'>[] {
  return [...posts].sort((a, b) => {
    const byDate = String(b.data.date ?? '').localeCompare(String(a.data.date ?? ''));
    if (byDate !== 0) return byDate;
    const ia = LEGACY_ORDER.indexOf(a.id);
    const ib = LEGACY_ORDER.indexOf(b.id);
    return (ia === -1 ? 999 : ia) - (ib === -1 ? 999 : ib);
  });
}

/** Approximate reading time at 200 wpm. */
export function readingTime(post: CollectionEntry<'posts'>): string {
  const words = (post.body ?? '').split(/\s+/).filter(Boolean).length;
  return `${Math.max(1, Math.round(words / 200))} min read`;
}
