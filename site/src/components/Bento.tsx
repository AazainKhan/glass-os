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

export default function Bento({ coverFlow, control, switcher, themes }: { coverFlow: Media; control: Media; switcher: Media; themes: Media[] }) {
  const [active, setActive] = useState(2);
  const n = themes.length;
  return (
    <div className="bento">
      <Tilt className="c-dock">
        <div className="cell-media"><Slot media={coverFlow} alt="Spotify Cover Flow in the Glass Top Shelf" todo="cover flow capture" w={1920} h={1080} sizes="(min-width: 1024px) 50vw, 100vw" /></div>
        <div className="cell-copy"><h3>Spotify as Cover Flow.</h3><p>Square covers in the Top Shelf turn into a Cover Flow of your albums and playlists.</p></div>
      </Tilt>
      <Tilt className="c-feat" delay={0.06}>
        <div className="cell-media tall"><Slot media={control} alt="Glass Control Center over a title" todo="control center capture" w={1920} h={1080} sizes="(min-width: 1024px) 25vw, 100vw" /></div>
        <div className="cell-copy"><h3>Control Center, your layout.</h3><p>Opens in about 200 ms from the status pill on Home. Add, remove and resize the controls, and add the Remotes panel to see and pair your remote.</p></div>
      </Tilt>
      <Tilt className="c-themes" delay={0.12}>
        <div className="fan" role="group" aria-label="Wallpaper themes">
          {themes.map((m, i) => {
            const d = i - active;
            return (
              <motion.div key={i} className="fan-item" animate={{ x: `${d * 34}%`, rotate: d * 5, scale: d === 0 ? 1 : 0.86, filter: d === 0 ? 'blur(0px)' : 'blur(3px)', opacity: Math.abs(d) > 2 ? 0 : d === 0 ? 1 : 0.7, zIndex: 10 - Math.abs(d) }} transition={{ type: 'spring', stiffness: 100, damping: 20 }}>
                <Slot media={m} alt={`Glass theme ${i + 1} of ${n}`} todo="theme" w={1920} h={1080} sizes="30vw" />
              </motion.div>
            );
          })}
        </div>
        <div className="cell-copy row">
          <div><h3>Dark and light themes.</h3><p>Aurora, Ember, Abyss, Dawn, Mist and more, or your own image. Light and dark wallpapers are set separately.</p></div>
          <div className="fan-ctl">
            <button type="button" className="icon-btn" aria-label="Previous theme" onClick={() => setActive((a) => (a + n - 1) % n)}><Icon name="CaretLeft" /></button>
            <button type="button" className="icon-btn" aria-label="Next theme" onClick={() => setActive((a) => (a + 1) % n)}><Icon name="CaretRight" /></button>
          </div>
        </div>
      </Tilt>
      <Tilt className="c-fast" delay={0.18}>
        <div className="cell-copy">
          <h3>Aerial screensaver.</h3>
          <p>Apple's Aerial videos, cached for offline replay. Fire OS only runs Amazon's screensavers, so Glass starts Aerials itself after a wait.</p>
        </div>
      </Tilt>
      <Tilt className="c-remote" delay={0.24}>
        <div className="cell-media"><Slot media={switcher} alt="The Glass app switcher" todo="app switcher capture" w={1920} h={1080} sizes="25vw" /></div>
        <div className="cell-copy"><h3>App switcher.</h3><p>Recent apps as cards. Press up to close one.</p></div>
      </Tilt>
    </div>
  );
}
