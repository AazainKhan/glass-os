import { useState } from 'react';
import { motion, useMotionValue, useSpring, useTransform, useMotionTemplate } from 'motion/react';
import Slot from './Slot';
import Icon from './Icon';
import type { Media } from '../lib/media';

const ease = [0.16, 1, 0.3, 1] as const;

function Tilt({ className, children, delay = 0 }: { className: string; children: React.ReactNode; delay?: number }) {
  const mx = useMotionValue(0.5), my = useMotionValue(0.5);
  const sx = useSpring(mx, { stiffness: 100, damping: 20 }), sy = useSpring(my, { stiffness: 100, damping: 20 });
  const rx = useTransform(sy, [0, 1], [6, -6]), ry = useTransform(sx, [0, 1], [-6, 6]);
  const px = useTransform(sx, (v) => `${v * 100}%`), py = useTransform(sy, (v) => `${v * 100}%`);
  const spot = useMotionTemplate`radial-gradient(420px circle at ${px} ${py}, rgba(237,237,234,0.13), transparent 60%)`;
  return (
    <motion.article className={`cell ${className}`} style={{ rotateX: rx, rotateY: ry, transformPerspective: 900 }}
      initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true, margin: '-10%' }} transition={{ duration: 0.6, ease, delay }}
      whileHover={{ y: -4 }}
      onPointerMove={(e) => { if (e.pointerType !== 'mouse') return; const r = e.currentTarget.getBoundingClientRect(); mx.set((e.clientX - r.left) / r.width); my.set((e.clientY - r.top) / r.height); }}
      onPointerLeave={() => { mx.set(0.5); my.set(0.5); }}>
      <motion.span className="spotlight" aria-hidden style={{ background: spot }} />
      {children}
    </motion.article>
  );
}

export default function Bento({ dock, featured, themes, remote }: { dock: Media; featured: Media; themes: Media[]; remote: Media }) {
  const [active, setActive] = useState(2);
  const n = themes.length;
  return (
    <div className="bento">
      <Tilt className="c-dock">
        <div className="cell-media"><Slot media={dock} alt="The Glass dock with app rows below" todo="dock capture" w={3840} h={2160} /></div>
        <div className="cell-copy"><h3>A dock for your apps.</h3><p>Up to six apps on a glass shelf, with folders and rows below. Move, hide and rename anything.</p></div>
      </Tilt>
      <Tilt className="c-feat" delay={0.06}>
        <div className="cell-media tall"><Slot media={featured} alt="Featured titles on poster artwork" todo="featured shelf capture" w={1080} h={1920} /></div>
        <div className="cell-copy"><h3>Featured titles up top.</h3><p>Pick Stremio, TMDB, YouTube or Plex as the source. Select a title and it opens in the matching app.</p></div>
      </Tilt>
      <Tilt className="c-themes" delay={0.12}>
        <div className="fan" role="group" aria-label="Wallpaper themes">
          {themes.map((m, i) => {
            const d = i - active;
            return (
              <motion.div key={i} className="fan-item" animate={{ x: `${d * 34}%`, rotate: d * 5, scale: d === 0 ? 1 : 0.86, filter: d === 0 ? 'blur(0px)' : 'blur(3px)', opacity: Math.abs(d) > 2 ? 0 : d === 0 ? 1 : 0.7, zIndex: 10 - Math.abs(d) }} transition={{ type: 'spring', stiffness: 100, damping: 20 }}>
                <Slot media={m} alt={`Wallpaper ${i + 1}`} todo="wallpaper" w={1920} h={1080} />
              </motion.div>
            );
          })}
        </div>
        <div className="cell-copy row">
          <div><h3>Wallpapers and themes.</h3><p>Gradients or your own image, with separate light and dark wallpapers.</p></div>
          <div className="fan-ctl">
            <button type="button" className="icon-btn" aria-label="Previous wallpaper" onClick={() => setActive((a) => (a + n - 1) % n)}><Icon name="CaretLeft" /></button>
            <button type="button" className="icon-btn" aria-label="Next wallpaper" onClick={() => setActive((a) => (a + 1) % n)}><Icon name="CaretRight" /></button>
          </div>
        </div>
      </Tilt>
      <Tilt className="c-fast" delay={0.18}>
        <div className="cell-copy">
          <p className="fig mono">0.5 s</p>
          <h3>Fast launch.</h3>
          <p>Cold start on a Fire TV Stick 4K. Under 1% janky frames while you browse.</p>
        </div>
      </Tilt>
      <Tilt className="c-remote" delay={0.24}>
        <div className="cell-media"><Slot media={remote} alt="Focus moving across the dock with a remote" todo="focus-move loop" w={1920} h={1080} format="webm+mp4" /></div>
        <div className="cell-copy"><h3>Built for the remote.</h3><p>Focus lifts on a spring and tilts toward the direction you pressed.</p></div>
      </Tilt>
    </div>
  );
}
