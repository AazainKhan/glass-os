import { useEffect, useRef, useState } from 'react';
import { motion, useReducedMotion } from 'motion/react';
import Slot from './Slot';
import Icon from './Icon';
import type { Media } from '../lib/media';

const ease = [0.16, 1, 0.3, 1] as const;

export default function Hero({ hero, install, demo }: { hero: Media; install: string; demo: Media }) {
  const calm = useReducedMotion();
  const video = useRef<HTMLVideoElement>(null);
  const glow = useRef<HTMLDivElement>(null);
  const dialog = useRef<HTMLDialogElement>(null);
  const [open, setOpen] = useState(false);
  const words = 'Your TV deserves a better home.'.split(' ');
  const hasVideo = !!(hero.webm || hero.mp4);

  // Ambient glow: sample the playing frame into a 32x18 canvas twice a second and tint a blurred layer behind the TV (bias lighting).
  useEffect(() => {
    const v = video.current, g = glow.current;
    if (!v || !g || calm) return;
    const c = document.createElement('canvas'); c.width = 32; c.height = 18;
    const ctx = c.getContext('2d', { willReadFrequently: true });
    if (!ctx) return;
    const zone = (x0: number, x1: number) => {
      const d = ctx.getImageData(x0, 0, x1 - x0, 18).data; let r = 0, gg = 0, b = 0, n = 0;
      for (let i = 0; i < d.length; i += 4) { r += d[i]; gg += d[i + 1]; b += d[i + 2]; n++; }
      return `rgb(${Math.round(r / n)} ${Math.round(gg / n)} ${Math.round(b / n)})`;
    };
    const id = setInterval(() => {
      if (v.paused || v.readyState < 2) return;
      ctx.drawImage(v, 0, 0, 32, 18);
      g.style.setProperty('--g1', zone(0, 11)); g.style.setProperty('--g2', zone(11, 22)); g.style.setProperty('--g3', zone(22, 32));
    }, 500);
    return () => clearInterval(id);
  }, [calm, hasVideo]);

  useEffect(() => {
    const d = dialog.current; if (!d) return;
    if (open && !d.open) d.showModal();
    if (!open && d.open) d.close();
  }, [open]);

  return (
    <section className="hero" id="top">
      <div className="hero-text">
        <h1 aria-label="Your TV deserves a better home.">
          {words.map((w, i) => (
            <motion.span key={i} aria-hidden className="word" initial={calm ? false : { opacity: 0, y: '0.55em' }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.8, ease, delay: i * 0.06 }}>
              {w}&nbsp;
            </motion.span>
          ))}
        </h1>
        <motion.p className="hero-sub" initial={calm ? false : { opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, ease, delay: 0.4 }}>
          An Apple TV-style launcher for Fire TV and Android TV. Dock, full-screen previews, built for the remote.
        </motion.p>
        <motion.div className="hero-actions" initial={calm ? false : { opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, ease, delay: 0.5 }}>
          <a className="pill primary" href={install}><span className="chip"><Icon name="DownloadSimple" size={18} /></span>Get Glass</a>
          <button type="button" className="textbtn" onClick={() => setOpen(true)}><Icon name="PlayCircle" size={22} />Watch the demo</button>
        </motion.div>
      </div>

      <motion.div className="hero-tv" initial={calm ? false : { opacity: 0, y: 70 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 1.1, ease, delay: 0.55 }}>
        {hasVideo && <div ref={glow} className="ambient" aria-hidden />}
        <div className="tv-frame">
          <Slot media={hero} alt="Glass home screen on a Fire TV, focus moving along the dock" todo="hero loop" w={1920} h={1080} format="webm+mp4" videoRef={video} eager />
        </div>
      </motion.div>

      <dialog ref={dialog} className="demo-dialog" onClose={() => setOpen(false)} onClick={(e) => { if (e.target === dialog.current) setOpen(false); }} aria-label="Full demo">
        <div className="demo-box">
          <button type="button" className="icon-btn" aria-label="Close demo" onClick={() => setOpen(false)}><Icon name="X" /></button>
          <div className="tv-frame"><Slot media={demo} alt="Full Glass demo" todo="full demo" w={1920} h={1080} format="mp4, 45 to 60 s, light music bed" /></div>
        </div>
      </dialog>
    </section>
  );
}
