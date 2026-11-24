#!/usr/bin/env bash
# Convert one LaTeX chapter to Quarto markdown, then split it into sections.
# Usage (from repo root): .qmd_translation/tex_to_qmd.sh chapter09_hypothesistesting [qmd_root]
#
#   writes <qmd_root>/.raw/<chapter>.qmd and <qmd_root>/.sections/<chapter>/*.qmd
#   qmd_root defaults to qmd; pull_upstream.sh passes a temp folder instead.

set -euo pipefail

name="$1"
root="${2:-qmd}"
here="$(dirname "$0")"
mkdir -p "$root/.raw"

# pandoc doesn't understand \epsfig, so rewrite it as \includegraphics.
# \begin{center}, \end{center} and \HR inside a figure make pandoc output raw HTML
# instead of a markdown figure, so drop them.
# Done on a temporary copy so tex/ is never modified.
tmp="$(mktemp -t "$name").tex"
perl -pe '
  s/\\epsfig\{\s*file\s*=\s*([^,}]+?)\s*,.*?width\s*=\s*([^,}]+?)\s*\}/\\includegraphics[width=$2]{$1}/g;
  s/\\(begin|end)\{center\}//g;
  s/^\s*\\HR\s*$//;
' "tex/$name.tex" > "$tmp"

# Lua filter changes image extensions to .png (see fix-images.lua).
quarto pandoc "$tmp" -f latex -t markdown --wrap=none \
  --lua-filter="$here/fix-images.lua" \
  -o "$root/.raw/$name.qmd"

rm "$tmp"

"$here/split_sections.sh" "$name" "$root"
