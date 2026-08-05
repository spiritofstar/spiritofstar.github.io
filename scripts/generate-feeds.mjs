#!/usr/bin/env node
/**
 * Feed generator — ports the old _build.py feed logic.
 *
 * Reads src/content/posts/*.md, parses frontmatter, and writes
 * rss.xml, atom.xml and feed.json into dist/.
 *
 * URL scheme (preserved from the old site):
 *   sandboxing-mitigation-comparative-analysis.md -> /blog.html
 *   everything else                                -> /<slug>.html
 */

import { readdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(fileURLToPath(new URL('.', import.meta.url)), '..');
const POSTS_DIR = join(ROOT, 'src', 'content', 'posts');
const DIST_DIR = join(ROOT, 'dist');

const SITE_URL = 'https://spiritofstar.github.io';
const SITE_TITLE = 'spiritofstar';
const SITE_DESC =
  'Independent research on browser security, memory safety, and privacy engineering';
const AUTHOR = 'spiritofstar';
const FEED_TAG = 'tag:spiritofstar.github.io';

/** Minimal YAML frontmatter parser for flat keys and lists. */
function parseFrontmatter(text) {
  const m = /^\s*---\s*\n(.*?)\n---/s.exec(text);
  if (!m) return { fm: {}, body: text };
  const body = text.slice(m[0].length);
  const fm = {};
  let key = null;
  for (const line of m[1].split('\n')) {
    const t = line.trim();
    if (t.startsWith('- ') && key) {
      fm[key].push(t.slice(2).trim().replace(/^["']|["']$/g, ''));
    } else if (line.includes(':') && !line.startsWith(' ')) {
      const i = line.indexOf(':');
      key = line.slice(0, i).trim();
      const v = line.slice(i + 1).trim().replace(/^["']|["']$/g, '');
      if (v) fm[key] = v;
      else if (!(key in fm)) fm[key] = [];
    }
  }
  return { fm, body };
}

/** Extract the text of the "## Abstract" section. */
function extractAbstract(body) {
  const m = /## Abstract\s*\n\n([\s\S]*?)(?:\n\n---|\n## )/.exec(body);
  return m ? m[1].trim().replace(/\s+/g, ' ') : SITE_DESC;
}

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/** Parse "July 2026" into a Date (UTC, first of month); falls back to now. */
function parseMonthYear(value) {
  const [month, year] = String(value).split(/\s+/);
  const mi = MONTHS.indexOf(month);
  if (mi !== -1 && /^\d{4}$/.test(year)) {
    return new Date(Date.UTC(Number(year), mi, 1));
  }
  return new Date();
}

async function main() {
  const files = (await readdir(POSTS_DIR)).filter(
    (f) => f.endsWith('.md') && !f.startsWith('_')
  );

  const posts = [];
  for (const fn of files) {
    const raw = await readFile(join(POSTS_DIR, fn), 'utf8');
    const { fm, body } = parseFrontmatter(raw);
    if (!fm.title) continue;

    const abstract = extractAbstract(body);

    const dt = fm.date ? parseMonthYear(fm.date) : new Date();

    const slug = fn.replace(/\.md$/, '');
    const atomDate = dt.toISOString().replace(/\.\d{3}Z$/, 'Z');
    const day = dt.toISOString().slice(0, 10);
    const tagId = `${FEED_TAG},${day}:/blog/${slug}`;
    const pageUrl =
      slug === 'sandboxing-mitigation-comparative-analysis'
        ? `${SITE_URL}/blog.html`
        : `${SITE_URL}/${slug}.html`;

    posts.push({
      title: fm.title,
      url: pageUrl,
      guid: tagId,
      abstract,
      atomDate,
      pubDate: dt.toUTCString(),
      categories: Array.isArray(fm.categories) ? fm.categories : [],
    });
  }

  if (!posts.length) {
    console.log('  ! No posts found');
    return;
  }

  posts.sort((a, b) => b.atomDate.localeCompare(a.atomDate));

  // ── RSS 2.0 ──
  const itemsRss = posts
    .map((p) => {
      const cats = p.categories.map((c) => `      <category>${esc(c)}</category>\n`).join('');
      return (
        '    <item>\n' +
        `      <title>${esc(p.title)}</title>\n` +
        `      <link>${esc(p.url)}</link>\n` +
        `      <guid>${esc(p.guid)}</guid>\n` +
        `      <pubDate>${p.pubDate}</pubDate>\n` +
        cats +
        '      <description><![CDATA[\n' +
        `${p.abstract}\n\n` +
        `<a href="${p.url}">Read the full paper &rarr;</a>\n` +
        '      ]]></description>\n' +
        '    </item>\n'
      );
    })
    .join('');

  const rss =
    '<?xml version="1.0" encoding="utf-8" ?>\n' +
    '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">\n' +
    '  <channel>\n' +
    `    <title>${esc(SITE_TITLE)}</title>\n` +
    `    <description>${esc(SITE_DESC)}</description>\n` +
    `    <link>${SITE_URL}/</link>\n` +
    '    <language>en</language>\n' +
    `    <lastBuildDate>${posts[0].pubDate}</lastBuildDate>\n` +
    `    <atom:link href="${SITE_URL}/rss.xml" rel="self" type="application/rss+xml" />\n` +
    itemsRss +
    '  </channel>\n' +
    '</rss>\n';

  // ── Atom ──
  const entriesAtom = posts
    .map((p) => {
      const cats = p.categories.map((c) => `    <category term="${esc(c)}" />\n`).join('');
      return (
        '  <entry>\n' +
        `    <title>${esc(p.title)}</title>\n` +
        `    <link href="${p.url}" rel="alternate" type="text/html" />\n` +
        `    <published>${p.atomDate}</published>\n` +
        `    <updated>${p.atomDate}</updated>\n` +
        cats +
        `    <id>${esc(p.guid)}</id>\n` +
        '    <summary type="html"><![CDATA[\n' +
        `${p.abstract}\n` +
        '    ]]></summary>\n' +
        `    <content type="html" src="${p.url}" />\n` +
        '  </entry>\n'
      );
    })
    .join('');

  const atom =
    '<?xml version="1.0" encoding="utf-8" ?>\n' +
    '<feed xmlns="http://www.w3.org/2005/Atom">\n' +
    `  <title>${esc(SITE_TITLE)}</title>\n` +
    `  <subtitle>${esc(SITE_DESC)}</subtitle>\n` +
    `  <link href="${SITE_URL}/atom.xml" rel="self" />\n` +
    `  <link href="${SITE_URL}/" rel="alternate" type="text/html" />\n` +
    `  <updated>${posts[0].atomDate}</updated>\n` +
    `  <id>${FEED_TAG},2026-07-04:/</id>\n` +
    '  <author>\n' +
    `    <name>${AUTHOR}</name>\n` +
    '  </author>\n' +
    '  <rights>All Rights Reserved</rights>\n\n' +
    entriesAtom +
    '</feed>\n';

  // ── JSON Feed ──
  const feed = {
    version: 'https://jsonfeed.org/version/1.1',
    title: SITE_TITLE,
    description: SITE_DESC,
    home_page_url: `${SITE_URL}/`,
    feed_url: `${SITE_URL}/feed.json`,
    authors: [{ name: AUTHOR }],
    language: 'en',
    items: posts.map((p) => ({
      id: p.guid,
      url: p.url,
      title: p.title,
      summary: p.abstract,
      content_html: `<p>${p.abstract.replace(/&/g, '&amp;').replace(/</g, '&lt;')}</p><p><a href="${p.url}">Read the full paper →</a></p>`,
      date_published: p.atomDate,
      date_modified: p.atomDate,
      tags: p.categories,
    })),
  };

  await writeFile(join(DIST_DIR, 'rss.xml'), rss);
  console.log('  ✓ rss.xml');
  await writeFile(join(DIST_DIR, 'atom.xml'), atom);
  console.log('  ✓ atom.xml');
  await writeFile(join(DIST_DIR, 'feed.json'), JSON.stringify(feed, null, 2));
  console.log('  ✓ feed.json');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
