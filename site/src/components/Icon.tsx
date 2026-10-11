import {
  Television, DownloadSimple, PlayCircle, List, X, GithubLogo, FilmSlate, Image as ImageIcon,
  CaretUp, CaretDown, CaretLeft, CaretRight, ArrowUUpLeft, House, Plus, Minus, ArrowRight,
} from '@phosphor-icons/react';

const icons = { Television, DownloadSimple, PlayCircle, List, X, GithubLogo, FilmSlate, ImageIcon, CaretUp, CaretDown, CaretLeft, CaretRight, ArrowUUpLeft, House, Plus, Minus, ArrowRight };
export type IconName = keyof typeof icons;

// One stroke weight everywhere: regular.
export default function Icon({ name, size = 20, label }: { name: IconName; size?: number; label?: string }) {
  const C = icons[name];
  return <C size={size} weight="regular" aria-hidden={label ? undefined : true} aria-label={label} />;
}
