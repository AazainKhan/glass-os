// Optimised captures live in src/assets/media (see scripts/optimise-media.sh and the README there).
// Until a file exists, callers get empty fields and render a labelled placeholder slot instead.
const files = import.meta.glob('../assets/media/*.{mp4,webm,png,jpg,jpeg,webp,avif}', {
  eager: true,
  query: '?url',
  import: 'default',
}) as Record<string, string>;

export type Media = {
  webm?: string; mp4?: string; webm720?: string; mp4720?: string; // clips
  image?: string; avifSet?: string; webpSet?: string; // stills: 1920 webp plus srcsets
  poster?: string;
};

const byName = new Map<string, string>();
for (const [path, url] of Object.entries(files)) byName.set(path.split('/').pop()!, url);

const pick = (base: string, exts: string[]) => exts.map((e) => byName.get(`${base}.${e}`)).find(Boolean);

export function media(name: string): Media {
  const set = (ext: string) => {
    const big = byName.get(`${name}.${ext}`), small = byName.get(`${name}-960.${ext}`);
    return big && small ? `${small} 960w, ${big} 1920w` : undefined;
  };
  return {
    webm: byName.get(`${name}.webm`), mp4: byName.get(`${name}.mp4`),
    webm720: byName.get(`${name}-720.webm`), mp4720: byName.get(`${name}-720.mp4`),
    image: pick(name, ['webp', 'png', 'jpg', 'jpeg', 'avif']),
    avifSet: set('avif'), webpSet: set('webp'),
    poster: pick(`${name}-poster`, ['webp', 'png', 'jpg', 'jpeg']),
  };
}

export const hasVideo = (m?: Media) => !!(m && (m.webm || m.mp4));
