# Design: Glass site (landing v2)

Source of truth: the user's launcher landing page kit (kept local, gitignored). One dark theme, cinematic and quiet; the TV frame and remote are the recurring motif.

## Tokens (src/styles/tokens.css)
- Surfaces: bg #0A0A0B, surface #131316, surface-2 #1B1B20, hairline rgba(255,255,255,.08).
- Text: #EDEDEA, dim #8E8E96. One accent, ember #FF5B2E, used only for the primary pill and the focus ring in the Try it demo (docs also use it for links and active nav).
- Type: Geist Variable for UI and display (600, tight tracking), Geist Mono Variable for labels, code and the one key figure.
- Shape: one system. Pills for buttons and chips, 28px for panels, frames, tiles and cells, 12px reserved for inputs.
- Glass: nav and caption chips only (blur 24px, 1px border, inner highlight), solid fallback under prefers-reduced-transparency.

## Motion
House ease cubic-bezier(.16,1,.3,1). Springs stiffness 100, damping 20. GSAP + ScrollTrigger + Lenis only in the pinned scale-up and the sticky setup stack; Motion (motion/react) for hero reveal, Try it, bento tilt and spotlight, fan slider and FAQ. No scroll listeners. Reduced motion: no Lenis, no pinning, static marquee grid, no tilt, video paused, static layouts.

## Content rules
No em or en dashes (scripts/check-dashes.mjs fails the build). Say "Apple TV-style". Same CTA label "Get Glass" (links to the install chooser). Every capture is a labelled placeholder slot with exact dimensions until real media is dropped into src/assets/media (see README there). Only real figures: cold start about 0.5 s on a Fire TV Stick 4K, under 1% janky frames (from the launcher README).
