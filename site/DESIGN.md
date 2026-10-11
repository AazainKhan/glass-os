# Design: Glass site

World: the page is a Glass home screen at dusk. Frosted glass panels over a slowly drifting teal / violet / ember wallpaper, warm near-white pill actions, spring-eased focus.

## Tokens (src/styles/glass.css)
- Ground: ink oklch(0.14 0.035 275); wallpaper fields teal 205, violet 296, ember 58 hue.
- Glass: white at 7.5% fill, 1px 16% line, 34% inner top highlight, backdrop blur 20px saturate 1.4.
- Radius: 28px panels, 18px tiles, pill buttons. Text: oklch(0.97 0.008 260), secondary 0.80, tertiary 0.66.
- Type: Hanken Grotesk Variable (self-hosted via @fontsource-variable), mono system stack for commands. Display 750 weight, tracking -0.03em.
- Motion: expo ease-out reveals (two variants: rise, settle), spring `linear()` curve for lift and hover, 40-50 s wallpaper drift. All disabled under prefers-reduced-motion; backdrop blur dropped under prefers-reduced-transparency.

## Components
SiteNav (floating glass pill, details-based mobile menu), TvDemo (hero.png slot or labelled illustration with cycling focus), feature rows, tier cards with status pills (Available / Coming soon / In development), step cards, close panel. Docs use Starlight with docs.css (same tokens) and a Header override.

## Rules
Say "Apple TV-style", never tvOS or 1:1. Unbuilt things are marked coming soon. The hero illustration is synthetic and labelled; replace by dropping src/assets/hero.png.
