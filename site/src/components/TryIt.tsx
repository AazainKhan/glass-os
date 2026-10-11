import { useCallback, useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'motion/react';
import Slot from './Slot';
import Icon from './Icon';
import type { Media } from '../lib/media';

type Item = { id: string; name: string; w: number; h: number; row: 'dock' | 'shelf'; m: Media };
type Key = 'up' | 'down' | 'left' | 'right' | 'select' | 'back' | 'home';
const spring = { type: 'spring', stiffness: 100, damping: 20 } as const;

export default function TryIt({ dock, shelf, previews }: { dock: Media[]; shelf: Media[]; previews: Media[] }) {
  const items: Item[] = [
    ...dock.map((m, i) => ({ id: `d${i}`, name: `Dock slot ${i + 1}`, w: 512, h: 288, row: 'dock' as const, m })),
    ...shelf.map((m, i) => ({ id: `s${i}`, name: `Featured slot ${i + 1}`, w: 1280, h: 720, row: 'shelf' as const, m })),
  ];
  const rows = { dock: items.filter((i) => i.row === 'dock'), shelf: items.filter((i) => i.row === 'shelf') };
  const [pos, setPos] = useState({ row: 'dock' as 'dock' | 'shelf', col: 0 });
  const [touched, setTouched] = useState(false);
  const [open, setOpen] = useState<Item | null>(null);
  const [pressed, setPressed] = useState<Key | null>(null);
  const box = useRef<HTMLDivElement>(null);
  const timer = useRef<number>(0);

  const act = useCallback((k: Key) => {
    setTouched(true);
    setPressed(k);
    window.clearTimeout(timer.current);
    timer.current = window.setTimeout(() => setPressed(null), 180);
    if (open) { if (k === 'back' || k === 'home') setOpen(null); return; }
    setPos((p) => {
      const r = rows[p.row];
      if (k === 'left') return { ...p, col: Math.max(0, p.col - 1) };
      if (k === 'right') return { ...p, col: Math.min(r.length - 1, p.col + 1) };
      if (k === 'down' && p.row === 'dock') return { row: 'shelf', col: Math.min(p.col, rows.shelf.length - 1) };
      if (k === 'up' && p.row === 'shelf') return { row: 'dock', col: Math.min(p.col, rows.dock.length - 1) };
      return p;
    });
    if (k === 'select') setOpen(rows[pos.row][pos.col]);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, pos]);

  const onKey = (e: React.KeyboardEvent) => {
    const map: Record<string, Key> = { ArrowUp: 'up', ArrowDown: 'down', ArrowLeft: 'left', ArrowRight: 'right', Enter: 'select', ' ': 'select', Backspace: 'back' };
    if (e.key === 'Escape') { if (open) { act('back'); e.preventDefault(); } else box.current?.blur(); return; } // Escape leaves the demo: no focus trap
    const k = map[e.key];
    if (k) { e.preventDefault(); act(k); }
  };

  useEffect(() => () => window.clearTimeout(timer.current), []);
  const focused = (it: Item) => touched && rows[pos.row][pos.col]?.id === it.id;
  const previewFor = open ? previews[items.indexOf(open) % previews.length] : undefined;

  const tile = (it: Item) => {
    const on = focused(it);
    return (
      <motion.button key={it.id} type="button" className={`tile ${it.row} ${on ? 'on' : ''}`} animate={{ scale: on ? 1.08 : 1, y: on ? -6 : 0 }} transition={spring}
        aria-label={it.name} onClick={() => { const col = rows[it.row].indexOf(it); setTouched(true); if (on) act('select'); else setPos({ row: it.row, col }); }} tabIndex={-1}>
        <Slot media={it.m} alt={it.name} todo={it.row === 'dock' ? 'dock icon art' : 'featured poster'} w={it.w} h={it.h} />
        <span className="spec" aria-hidden />
        {on && <span className="ring" aria-hidden />}
      </motion.button>
    );
  };

  const R = ({ k, icon, label, cls = '' }: { k: Key; icon: Parameters<typeof Icon>[0]['name']; label: string; cls?: string }) => (
    <button key={k} type="button" className={`rbtn ${cls} ${pressed === k ? 'lit' : ''}`} aria-label={label} onClick={() => act(k)} tabIndex={-1}><Icon name={icon} size={20} /></button>
  );

  return (
    <div className="tryit">
      <div ref={box} className="tryit-tv tv-frame" tabIndex={0} role="application" aria-label="Interactive launcher. Arrow keys move focus, Enter opens, Escape leaves the demo." onKeyDown={onKey}>
        <div className="tv-screen">
          <div className="dockrow">{rows.dock.map(tile)}</div>
          <div className="shelfrow">{rows.shelf.map(tile)}</div>
          <AnimatePresence>
            {!touched && (
              <motion.p className="hint glass" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.4 }}>
                <span className="kbd-only">Press an arrow key</span><span className="touch-only">Tap an app</span>
              </motion.p>
            )}
            {open && (
              <motion.div className="preview" initial={{ opacity: 0, scale: 0.94 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.96 }} transition={spring}>
                <Slot media={previewFor} alt={`Full-screen preview for ${open.name}`} todo="preview art" w={1920} h={1080} />
                <span className="glass preview-cap">{open.name}</span>
                <button type="button" className="glass back-pill" onClick={() => act('back')}><Icon name="ArrowUUpLeft" size={16} />Back</button>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      <div className="remote" aria-hidden="true">
        <div className="dpad">
          {R({k: 'up', icon: 'CaretUp', label: 'Up', cls: 'u'})}{R({k: 'left', icon: 'CaretLeft', label: 'Left', cls: 'l'})}
          {R({k: 'select', icon: 'Plus', label: 'Select', cls: 'c'})}{R({k: 'right', icon: 'CaretRight', label: 'Right', cls: 'r'})}{R({k: 'down', icon: 'CaretDown', label: 'Down', cls: 'd'})}
        </div>
        <div className="rrow">{R({k: 'back', icon: 'ArrowUUpLeft', label: 'Back'})}{R({k: 'home', icon: 'House', label: 'Home'})}</div>
      </div>
    </div>
  );
}
