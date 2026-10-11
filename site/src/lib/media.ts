// Real captures are dropped into src/assets/media (see README.txt there). Until a file exists,
// callers get empty sources and render a labelled placeholder slot instead.
const files = import.meta.glob('../assets/media/*.{mp4,webm,png,jpg,jpeg,webp}', {
  eager: true,
  query: '?url',
  import: 'default',
}) as Record<string, string>;

const legacy = import.meta.glob('../assets/hero.png', { eager: true, query: '?url', import: 'default' }) as Record<string, string>;

export type Media = { webm?: string; mp4?: string; image?: string; poster?: string };

const byBase = new Map<string, string>();
for (const [path, url] of [...Object.entries(files), ...Object.entries(legacy)]) {
  const base = path.split('/').pop()!.replace(/\.[^.]+$/, '');
  const ext = path.split('.').pop()!;
  byBase.set(`${base}.${ext}`, url);
}

export function media(name: string): Media {
  const get = (ext: string) => byBase.get(`${name}.${ext}`);
  const poster = ['png', 'jpg', 'jpeg', 'webp'].map((e) => byBase.get(`${name}-poster.${e}`)).find(Boolean)
    ?? (name === 'hero-loop' ? byBase.get('hero.png') : undefined);
  const image = ['png', 'jpg', 'jpeg', 'webp'].map(get).find(Boolean);
  return { webm: get('webm'), mp4: get('mp4'), image, poster };
}
