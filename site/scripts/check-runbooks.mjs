// Extracts every ```bash block from the runbook and checks it parses with `bash -n`.
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

const file = 'src/content/docs/agents/runbook.md';
const text = readFileSync(file, 'utf8');
const blocks = [...text.matchAll(/```bash[^\n]*\n([\s\S]*?)```/g)].map((m) => m[1]);
let bad = 0;
blocks.forEach((b, i) => {
  const r = spawnSync('bash', ['-n'], { input: b, encoding: 'utf8' });
  if (r.status !== 0) { bad++; console.error(`block ${i + 1} failed:\n${b}\n${r.stderr}`); }
});
console.log(`${blocks.length} bash blocks checked, ${bad} failed`);
process.exit(bad ? 1 : 0);
