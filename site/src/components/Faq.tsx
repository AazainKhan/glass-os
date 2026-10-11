import { useState } from 'react';
import { AnimatePresence, motion } from 'motion/react';
import Icon from './Icon';

const ease = [0.16, 1, 0.3, 1] as const;
type QA = { q: string; a: string };

export default function Faq({ items }: { items: QA[] }) {
  const [open, setOpen] = useState<number | null>(0);
  return (
    <div className="faq">
      {items.map((it, i) => {
        const on = open === i;
        const lines = it.a.split(/(?<=\.)\s+/);
        return (
          <div key={it.q} className="faq-item">
            <h3>
              <button type="button" aria-expanded={on} aria-controls={`faq-${i}`} onClick={() => setOpen(on ? null : i)}>
                <span>{it.q}</span><Icon name={on ? 'Minus' : 'Plus'} size={20} />
              </button>
            </h3>
            <AnimatePresence initial={false}>
              {on && (
                <motion.div id={`faq-${i}`} role="region" initial={{ height: 0 }} animate={{ height: 'auto' }} exit={{ height: 0 }} transition={{ duration: 0.5, ease }} style={{ overflow: 'hidden' }}>
                  <p className="faq-a">
                    {lines.map((l, k) => (
                      <motion.span key={k} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5, ease, delay: 0.08 + k * 0.07 }}>{l} </motion.span>
                    ))}
                  </p>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        );
      })}
    </div>
  );
}
