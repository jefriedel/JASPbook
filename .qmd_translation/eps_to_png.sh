#!/usr/bin/env bash
# One-time: make a .png next to every .eps / .pdf figure in img/ (skips ones that already exist).
#   EPS -> PNG with Ghostscript (gs)
#   PDF -> PNG with pdftocairo (poppler)
# Usage: .qmd_translation/eps_to_png.sh [folder]    (default: img)

set -euo pipefail

dir="${1:-img}"

find "$dir" -path '*/defunct_images' -prune -o \( -name '*.eps' -o -name '*.pdf' \) -print |
while read -r f; do
  case "$f" in *-eps-converted-to.pdf) continue ;; esac   # LaTeX build leftovers
  png="${f%.*}.png"
  [ -e "$png" ] && continue
  echo "-> $png"
  case "$f" in
    *.eps) gs -q -dSAFER -dBATCH -dNOPAUSE -dEPSCrop -sDEVICE=png16m -r200 \
             -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -o "$png" "$f" ;;
    *.pdf) pdftocairo -png -singlefile -r 200 "$f" "${png%.png}" ;;
  esac
done
