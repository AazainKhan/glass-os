import { useLayoutEffect, useRef } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import Slot from './Slot';
import type { Media } from '../lib/media';

const caps = ['One dock for everything.', 'Featured titles up top.', 'Focus with a spring.', 'Your apps, your order.'];

export default function ScaleUp({ scene }: { scene: Media }) {
  const root = useRef<HTMLElement>(null);
  const frame = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    gsap.registerPlugin(ScrollTrigger);
    const mm = gsap.matchMedia();
    mm.add('(min-width: 768px) and (prefers-reduced-motion: no-preference)', () => {
      const chips = gsap.utils.toArray<HTMLElement>('.cap-chip', root.current!);
      // Why: scrolling moves the viewer from looking at the product to sitting in front of it.
      const tl = gsap.timeline({ scrollTrigger: { trigger: root.current, start: 'top top', end: '+=260%', pin: true, scrub: 0.6, anticipatePin: 1 } });
      tl.fromTo(frame.current, { scale: 0.6, borderRadius: 47 }, { scale: 1, borderRadius: 0, ease: 'none', duration: 1 }, 0);
      // Why: captions name each scene as it plays, one at a time.
      chips.forEach((c, i) => {
        tl.fromTo(c, { autoAlpha: 0, y: 18 }, { autoAlpha: 1, y: 0, duration: 0.12, ease: 'power3.out' }, 0.04 + i * 0.24);
        if (i < chips.length - 1) tl.to(c, { autoAlpha: 0, y: -18, duration: 0.1, ease: 'power3.in' }, 0.22 + i * 0.24);
      });
    });
    return () => mm.revert();
  }, []);

  return (
    <section ref={root} className="scale" aria-label="Glass in full screen">
      <div ref={frame} className="scale-frame">
        <Slot media={scene} alt="Glass home screen filling the TV" todo="scale-up scene" w={3840} h={2160} format="webm+mp4" />
      </div>
      <ul className="caps">
        {caps.map((c) => <li key={c} className="cap-chip glass">{c}</li>)}
      </ul>
    </section>
  );
}
