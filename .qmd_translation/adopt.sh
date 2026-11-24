#!/usr/bin/env bash
# Start editing an upstream section: copy it into qmd/_sections/ with a marker line
# that records which upstream section it came from.
# Usage (from repo root): .qmd_translation/adopt.sh chapter09_hypothesistesting/sec-decisionmaking nhst-decisions
#
#   creates qmd/_sections/nhst-decisions.qmd, starting with
#   <!-- upstream: chapter09_hypothesistesting/sec-decisionmaking -->
#
# After this, rename or move the file freely with `git mv`; the marker travels with it.
# Don't edit or delete the marker line — pull_upstream.sh uses it.

set -euo pipefail

key="${1%.qmd}"
dest="qmd/_sections/${2%.qmd}.qmd"
base="qmd/.sections/$key.qmd"

[ -f "$base" ] || { echo "no such upstream section: $base" >&2; exit 1; }
[ -e "$dest" ] && { echo "already exists: $dest" >&2; exit 1; }

mkdir -p "$(dirname "$dest")"
{ echo "<!-- upstream: $key -->"; cat "$base"; } > "$dest"
git add "$dest"
echo "created $dest"
echo "include it with: {{< include ${dest#qmd/} >}}"
