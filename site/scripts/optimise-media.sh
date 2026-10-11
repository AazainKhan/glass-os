#!/usr/bin/env bash
# Turns raw captures (site/.media-raw, gitignored) into the optimised files the site commits
# (site/src/assets/media). Needs ffmpeg and ImageMagick with AVIF + WebP support.
set -euo pipefail
cd "$(dirname "$0")/.."
RAW=.media-raw
OUT=src/assets/media
ONLY=${1:-} # optional: a clip name (for example hero-loop) to rebuild just that clip
mkdir -p "$OUT"

# still NAME SRC [CROP]: 1920 and 960 wide, WebP and AVIF. CROP is WxH+X+Y on the source.
still() {
  local name=$1 src=$2 crop=${3:-}
  local base=(magick "$RAW/$src")
  [[ -n $crop ]] && base+=(-crop "$crop" +repage)
  "${base[@]}" -resize '1920x>' -quality 82 "$OUT/$name.webp"
  "${base[@]}" -resize '1920x>' -quality 55 "$OUT/$name.avif"
  "${base[@]}" -resize '960x>'  -quality 82 "$OUT/$name-960.webp"
  "${base[@]}" -resize '960x>'  -quality 55 "$OUT/$name-960.avif"
}
# tile NAME SRC CROP: a small crop, WebP only.
tile() { magick "$RAW/$2" -crop "$3" +repage -quality 85 "$OUT/$1.webp"; }

# clip NAME SRC: webm + mp4 at 1080p and 720p (30 fps, no audio) and a first-frame poster.
clip() {
  local name=$1 src=$2
  ffmpeg -v error -y -i "$RAW/$src" -an -vf "fps=30,scale=out_color_matrix=bt709:out_range=tv,format=yuv420p" -colorspace bt709 -color_primaries bt709 -color_trc bt709 -c:v libvpx-vp9 -b:v 0 -crf 33 -row-mt 1 "$OUT/$name.webm"
  ffmpeg -v error -y -i "$RAW/$src" -an -vf "fps=30,scale=out_color_matrix=bt709:out_range=tv,format=yuv420p" -colorspace bt709 -color_primaries bt709 -color_trc bt709 -c:v libx264 -preset slow -crf 24 -movflags +faststart "$OUT/$name.mp4"
  ffmpeg -v error -y -i "$RAW/$src" -an -vf "fps=30,scale=1280:-2:out_color_matrix=bt709:out_range=tv,format=yuv420p" -colorspace bt709 -color_primaries bt709 -color_trc bt709 -c:v libvpx-vp9 -b:v 0 -crf 33 -row-mt 1 "$OUT/$name-720.webm"
  ffmpeg -v error -y -i "$RAW/$src" -an -vf "fps=30,scale=1280:-2:out_color_matrix=bt709:out_range=tv,format=yuv420p" -colorspace bt709 -color_primaries bt709 -color_trc bt709 -c:v libx264 -preset slow -crf 24 -movflags +faststart "$OUT/$name-720.mp4"
  local tmp; tmp=$(mktemp -t poster).png
  ffmpeg -v error -y -i "$RAW/$src" -frames:v 1 "$tmp"
  magick "$tmp" -resize "1920x>" -quality 82 "$OUT/$name-poster.webp"; rm -f "$tmp"
}

if [[ -z $ONLY ]]; then
still dock          still-home-dock.png
still featured      still-featured.png
still preview-1     still-control-center.png
still preview-2     still-app-switcher.png
still preview-3     still-cover-flow.png
still preview-4     still-settings.png
still setup-home    still-settings.png
still setup-customise still-settings-appearance.png
i=1; for t in theme-1-dark-aurora theme-2-dark-ember theme-3-dark-abyss theme-4-light-dawn theme-5-light-mist; do still "theme-$i" "$t.png"; i=$((i+1)); done

# Real dock tiles and featured posters cropped from the captures.
tile dock-1 still-home-dock.png 249x149+91+808
tile dock-2 still-home-dock.png 250x150+380+812
tile dock-3 still-home-dock.png 249x149+687+808
tile dock-4 still-home-dock.png 249x149+984+808
tile dock-5 still-home-dock.png 248x149+1283+808
tile dock-6 still-home-dock.png 249x149+1580+808
tile shelf-1 still-featured.png 300x170+90+790
tile shelf-2 still-featured.png 300x170+768+790
tile shelf-3 still-featured.png 294x170+1116+790

fi

if [[ -z $ONLY || $ONLY == clip-remote-focus ]]; then clip clip-remote-focus remote-focus.mp4; fi
if [[ -z $ONLY || $ONLY == hero-loop ]]; then clip hero-loop hero-loop.mp4; fi
ls -la "$OUT"
