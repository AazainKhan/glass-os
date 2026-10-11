// Fails if site sources or built output contain a device serial or a home-directory path.
import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const pattern = /G072JM|\/Users\/|\/home\/[a-z]/;
let hits = 0;
function walk(dir) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) { walk(p); continue; }
    if (!/\.(md|mdx|astro|mjs|ts|json|txt|html|xml|css)$/.test(name)) continue;
    readFileSync(p, 'utf8').split('\n').forEach((l, i) => {
      if (pattern.test(l)) { hits++; console.error(`${p}:${i + 1}: ${l.trim().slice(0, 100)}`); }
    });
  }
}
for (const d of ['src', 'dist']) if (existsSync(d)) walk(d);
console.log(hits ? `${hits} leak(s)` : 'clean');
process.exit(hits ? 1 : 0);
