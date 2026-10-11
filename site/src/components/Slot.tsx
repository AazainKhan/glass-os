import { useEffect, useRef } from 'react';
import Icon from './Icon';
import type { Media } from '../lib/media';

type Props = {
  media?: Media;
  alt: string;
  todo: string; // what to capture, e.g. "hero loop"
  w: number;
  h: number;
  format?: string; // e.g. "webm+mp4"
  className?: string;
  videoRef?: React.RefObject<HTMLVideoElement | null>;
  eager?: boolean;
  sizes?: string;
};

// Real capture when present, otherwise a labelled placeholder with exact dimensions.
export default function Slot({ media, alt, todo, w, h, format, className = '', videoRef, eager, sizes = '100vw' }: Props) {
  const local = useRef<HTMLVideoElement>(null);
  const ref = videoRef ?? local;
  const hasVideo = !!(media?.webm || media?.mp4);

  useEffect(() => {
    const v = ref.current;
    if (!v) return;
    const calm = matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (calm) { v.removeAttribute('autoplay'); v.pause(); return; }
    const io = new IntersectionObserver(([e]) => { if (e.isIntersecting) v.play().catch(() => {}); else v.pause(); });
    io.observe(v);
    return () => io.disconnect();
  }, [hasVideo, ref]);

  if (hasVideo) {
    return (
      <video ref={ref} className={`slot-media ${className}`} muted loop playsInline autoPlay preload={eager ? 'auto' : 'metadata'} poster={media?.poster ?? media?.image} aria-label={alt}>
        {media?.webm720 && <source src={media.webm720} type="video/webm" media="(max-width: 800px)" />}
        {media?.mp4720 && <source src={media.mp4720} type="video/mp4" media="(max-width: 800px)" />}
        {media?.webm && <source src={media.webm} type="video/webm" />}
        {media?.mp4 && <source src={media.mp4} type="video/mp4" />}
      </video>
    );
  }
  const still = media?.image ?? media?.poster;
  if (still) {
    return (
      <picture>
        {media?.avifSet && <source type="image/avif" srcSet={media.avifSet} sizes={sizes} />}
        {media?.webpSet && <source type="image/webp" srcSet={media.webpSet} sizes={sizes} />}
        <img className={`slot-media ${className}`} src={still} alt={alt} loading={eager ? 'eager' : 'lazy'} decoding="async" {...(eager ? { fetchPriority: 'high' as const } : {})} />
      </picture>
    );
  }
  return (
    <div className={`slot ${className}`} role="img" aria-label={`Placeholder: ${alt}`} style={{ aspectRatio: `${w} / ${h}` }}>
      <span className="slot-tick tl" /><span className="slot-tick tr" /><span className="slot-tick bl" /><span className="slot-tick br" />
      <Icon name={format && /webm|mp4/.test(format) ? 'FilmSlate' : 'ImageIcon'} size={22} />
      <code>TODO: {todo} {w}x{h}{format ? ` ${format}` : ''}</code>
    </div>
  );
}
