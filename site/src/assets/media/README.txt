Optimised captures committed for the site. Raw captures live in site/.media-raw (gitignored);
run scripts/optimise-media.sh to regenerate everything here.

Names the page looks for (the page falls back to a labelled placeholder slot when one is missing):
  hero-loop.webm/.mp4 (+ -720 variants, -poster.webp): the 12 s hero loop. Until it exists the hero shows dock.webp.
  demo-full.webm/.mp4: full demo for the modal. Until it exists the modal plays clip-remote-focus.
  clip-featured, clip-remote-focus: clips (webm and mp4, 1080p and -720, plus -poster.webp)
  dock, featured, preview-1..4, setup-home, setup-customise, theme-1..5: stills (webp and avif at 1920 and -960)
  dock-1..6, shelf-1..3: small crops used by the Try it demo
