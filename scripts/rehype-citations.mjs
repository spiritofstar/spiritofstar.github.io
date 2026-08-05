/**
 * rehype plugin — link numeric citations to the References section.
 *
 * The articles use the style "[6]" (and ranges like "[27]-[30]") for in-text
 * citations, with a "## References" section where each entry starts with
 * "[N] ". This plugin:
 *
 *   1. Adds `id="ref-N"` to each reference entry paragraph.
 *   2. Wraps in-text "[N]" / "[N]-[M]" tokens in <a href="#ref-N"> links.
 *
 * Content inside <code>, <pre>, <a> and the References section itself is
 * left untouched.
 */

import { visit } from 'unist-util-visit';

const CITATION = /\[(\d+)(?:-(\d+))?\]/;

function nodeText(node) {
  let out = '';
  visit(node, 'text', (t) => {
    out += t.value;
  });
  return out;
}

function isReferencesHeading(node) {
  return (
    node.type === 'element' &&
    /^h[1-6]$/.test(node.tagName) &&
    /^references$/i.test(nodeText(node).trim())
  );
}

export default function rehypeCitations() {
  return (tree) => {
    const replacements = [];
    let reachedRefs = false;

    visit(
      tree,
      (node, index, parent) => {
        if (node.type === 'element' && isReferencesHeading(node)) {
          reachedRefs = true;
          // Give the References section itself an anchor.
          if (!node.properties.id) node.properties.id = 'references';
          return;
        }

        if (!reachedRefs && node.type === 'element' && node.tagName === 'p') {
          const m = /^\[(\d+)\]/.exec(nodeText(node).trim());
          if (m && !node.properties.id) node.properties.id = `ref-${m[1]}`;
        }

        if (!reachedRefs && node.type === 'text' && parent && !['code', 'pre', 'a'].includes(parent.tagName)) {
          if (CITATION.test(node.value)) {
            replacements.push({ node, index, parent });
          }
        }

        return true;
      },
      true
    );

    // Apply replacements newest-first so sibling indices stay valid.
    for (let i = replacements.length - 1; i >= 0; i--) {
      const { node, index, parent } = replacements[i];
      const parts = node.value.split(/(\[(\d+)(?:-(\d+))?\])/);
      if (parts.length === 1) continue;

      const children = [];
      for (let k = 0; k < parts.length; k++) {
        const part = parts[k];
        if (!part) continue;
        const m = CITATION.exec(part);
        if (m && m[0] === part) {
          children.push({
            type: 'element',
            tagName: 'a',
            properties: { href: `#ref-${m[1]}`, className: ['citation'] },
            children: [{ type: 'text', value: part }],
          });
        } else {
          children.push({ type: 'text', value: part });
        }
      }
      parent.children.splice(index, 1, ...children);
    }
  };
}
