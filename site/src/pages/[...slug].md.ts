import type { APIRoute, GetStaticPaths } from 'astro';
import { getCollection } from 'astro:content';
import { SITE, pathFor } from '../lib/site';

// Raw Markdown for every docs page, generated at build time: frontmatter dropped, Starlight asides
// turned into blockquotes, fence titles stripped, internal links made absolute.
export const getStaticPaths = (async () => {
  const docs = await getCollection('docs');
  return docs.map((entry) => ({ params: { slug: pathFor(entry.id).slice(1) }, props: { entry } }));
}) satisfies GetStaticPaths;

export function toMarkdown(title: string, description: string | undefined, body: string): string {
  let out = body
    .replace(/^:::(\w+)(?:\[([^\]]*)\])?\s*\n([\s\S]*?)\n:::\s*$/gm, (_m, type: string, label: string | undefined, text: string) => {
      const head = label ?? type[0].toUpperCase() + type.slice(1);
      return [`> **${head}**`, ...text.split('\n').map((l) => (l ? `> ${l}` : '>'))].join('\n') + '\n\n';
    })
    .replace(/^(```\w*)\s+title="[^"]*"/gm, '$1')
    .replace(/\]\(\/glass-os\//g, `](${SITE}/`)
    .replace(/<\/?(Card|CardGrid|LinkCard|Tabs|TabItem)[^>]*>/g, '');
  const intro = description ? `${description}\n\n` : '';
  return `# ${title}\n\n${intro}${out.trim()}\n`;
}

export const GET: APIRoute = ({ props }) => {
  const { entry } = props as { entry: Awaited<ReturnType<typeof getCollection<'docs'>>>[number] };
  const md = toMarkdown(entry.data.title, entry.data.description, entry.body ?? '');
  return new Response(md, { headers: { 'Content-Type': 'text/markdown; charset=utf-8' } });
};
