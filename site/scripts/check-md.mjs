// Every docs page must have a matching .md in dist, each .md must be clean, and every llms.txt link must resolve.
import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs';
import { join } from 'node:path';
const SITE = 'https://aazainkhan.github.io/glass-os';
let bad = 0;
const fail = (m) => { bad++; console.error('FAIL ' + m); };

const pages = [];
(function walk(d) {
  for (const n of readdirSync(d)) {
    const p = join(d, n);
    if (statSync(p).isDirectory()) { if (['_astro', 'pagefind', '_llms-txt'].includes(n)) continue; walk(p); continue; }
    if (n === 'index.html') pages.push(p);
  }
})('dist');

let checked = 0;
for (const p of pages) {
  const rel = p.slice('dist'.length, -'/index.html'.length) || '/'; // "/install/app" or "/"
  if (rel === '/') continue; // landing page is not a docs page
  const html = readFileSync(p, 'utf8');
  if (/http-equiv="refresh"/i.test(html)) continue; // redirect stub
  if (!/data-pagefind-body|class="sl-markdown-content"/.test(html)) continue;
  const md = join('dist', rel + '.md');
  if (!existsSync(md)) { fail(`missing ${rel}.md for ${rel}/`); continue; }
  const text = readFileSync(md, 'utf8');
  if (/^---\s*$/m.test(text.split('\n')[0] ?? '')) fail(`${rel}.md has frontmatter`);
  if (/^:::/m.test(text)) fail(`${rel}.md has unconverted aside`);
  if (/[–—]/.test(text)) fail(`${rel}.md has an em or en dash`);
  if (!text.startsWith('# ')) fail(`${rel}.md does not start with a title`);
  checked++;
}

const llms = readFileSync('dist/llms.txt', 'utf8');
const links = [...llms.matchAll(/\]\((https?:\/\/[^)\s]+)\)/g)].map((m) => m[1]);
for (const u of links) {
  if (!u.startsWith(SITE)) continue; // external
  const path = u.slice(SITE.length);
  if (!existsSync(join('dist', path))) fail(`llms.txt link does not resolve: ${u}`);
}
console.log(`${checked} docs pages have a clean .md; ${links.length} llms.txt links checked; ${bad ? bad + ' failure(s)' : 'all good'}`);
process.exit(bad ? 1 : 0);
