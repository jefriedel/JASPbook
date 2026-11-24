#!/usr/bin/env bash
# Split a converted chapter into one file per "## " section.
# Usage (from repo root): .qmd_translation/split_sections.sh chapter09_hypothesistesting [qmd_root]
#
#   reads  <qmd_root>/.raw/<chapter>.qmd
#   writes <qmd_root>/.sections/<chapter>/<label>.qmd   (one per section)
#          <qmd_root>/.sections/<chapter>/_order.txt    (section order in the original chapter)
#
# <label> comes from the LaTeX \label, e.g. "## Making decisions []{#sec:decisionmaking ...}"
# becomes sec-decisionmaking.qmd. Headings without a label get a name made from the title.
# Everything before the first "## " (the chapter title and intro text) goes to intro.qmd.
# These files are the merge BASE for pull_upstream.sh — never edit them.

set -euo pipefail

name="$1"
root="${2:-qmd}"
src="$root/.raw/$name.qmd"
out="$root/.sections/$name"

rm -rf "$out"
mkdir -p "$out"

awk -v out="$out" '
  function start(label,   n) {
    n = ++seen[label]
    if (n > 1) label = label "-" n          # avoid duplicate names
    if (file) close(file)
    file = out "/" label ".qmd"
    print label >> (out "/_order.txt")
  }
  BEGIN { start("intro") }
  /^## / {
    if (match($0, /\{#sec:[^ }]+/)) {
      label = "sec-" substr($0, RSTART + 6, RLENGTH - 6)
    } else {
      label = tolower(substr($0, 4))
      gsub(/[^a-z0-9]+/, "-", label)
      gsub(/^-+|-+$/, "", label)
    }
    start(label)
  }
  { print > file }
' "$src"

echo "split $src -> $out ($(wc -l < "$out/_order.txt" | tr -d ' ') sections)"
