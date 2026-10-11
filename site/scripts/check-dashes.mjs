// Fails the build if any em dash, en dash or their HTML entities appear in the built HTML.
import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs';
import { join } from 'node:path';
const bad = /[–—]|&mdash;|&ndash;|&#8211;|&#8212;|&#x2013;|&#x2014;/i;
let hits = 0;
function walk(d) {
  for (const n of readdirSync(d)) {
    const p = join(d, n);
    if (statSync(p).isDirectory()) { if (n === '_astro' || n === 'pagefind') continue; walk(p); continue; }
    if (!n.endsWith('.html')) continue;
    readFileSync(p, 'utf8').split('\n').forEach((l, i) => { const m = l.match(bad); if (m) { hits++; const at = l.search(bad); console.error(`${p}:${i + 1}: ...${l.slice(Math.max(0, at - 40), at + 40)}...`); } });
  }
}
if (existsSync('dist')) walk('dist');
console.log(hits ? `${hits} dash(es) found` : 'no em or en dashes');
process.exit(hits ? 1 : 0);
