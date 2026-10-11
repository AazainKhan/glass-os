import { useLayoutEffect, useRef } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import Slot from './Slot';
import type { Media } from '../lib/media';

type Panel = { title: string; lines: string[]; m: Media; todo: string; alt: string };

export default function Setup({ panels }: { panels: Panel[] }) {
  const root = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    gsap.registerPlugin(ScrollTrigger);
    const mm = gsap.matchMedia();
    mm.add('(min-width: 768px) and (prefers-reduced-motion: no-preference)', () => {
      const els = gsap.utils.toArray<HTMLElement>('.sp', root.current!);
      els.forEach((p, i) => {
        if (i === els.length - 1) return;
        // Why: each panel stays put and the next one slides over it, so the three steps read as one stack.
        ScrollTrigger.create({ trigger: p, start: 'top top', endTrigger: root.current, end: 'bottom bottom', pin: true, pinSpacing: false });
        gsap.to(p, { scale: 0.92, autoAlpha: 0.55, ease: 'none', scrollTrigger: { trigger: els[i + 1], start: 'top bottom', end: 'top top', scrub: true } });
      });
    });
    return () => mm.revert();
  }, []);
  return (
    <div ref={root} className="setup-stack">
      {panels.map((p) => (
        <section key={p.title} className="sp">
          <div className="sp-copy"><h3>{p.title}</h3>{p.lines.map((l) => <p key={l}>{l}</p>)}</div>
          <div className="sp-media tv-frame"><Slot media={p.m} alt={p.alt} todo={p.todo} w={1920} h={1080} format="webm+mp4" /></div>
        </section>
      ))}
    </div>
  );
}
