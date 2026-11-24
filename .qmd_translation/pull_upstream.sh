#!/usr/bin/env bash
# Bring upstream edits to the LaTeX into your own section files.
# Usage (from repo root): .qmd_translation/pull_upstream.sh [ref]     (ref defaults to upstream/master)
#
# How it works, for every file in qmd/_sections/ that has an "<!-- upstream: ... -->" marker:
#   base     = qmd/.sections/<key>.qmd      (conversion of the LaTeX you started from)
#   upstream = same section converted from the NEW LaTeX
#   mine     = your edited file
#   git merge-file applies the base->upstream changes to mine, keeping your edits.
#   Where you and upstream changed the same lines you get conflict markers:
#     <<<<<<< mine ... ||||||| base ... ======= ... >>>>>>> upstream
#
# Nothing is committed: the LaTeX merge, your updated sections and the new base all wait
# for you, so they land together in one merge commit.
#   review:  git status / git diff
#   accept:  fix conflict markers, then  git add -A qmd .qmd_translation && git commit
#   undo:    git reset --hard    (safe: the script refuses to start with uncommitted changes)

set -euo pipefail

here="$(dirname "$0")"
ref="${1:-upstream/master}"
old="$(cat "$here/UPSTREAM_BASE")"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Commit or stash your changes first, so the merge results are easy to review." >&2
  exit 1
fi

case "$ref" in upstream/*) git fetch upstream ;; esac
new="$(git rev-parse "$ref")"

if [ "$(git rev-parse "$old")" = "$new" ]; then
  echo "Already up to date with $ref."
  exit 0
fi

echo "== Upstream LaTeX changes $old..$ref =="
git diff --stat "$old" "$new" -- tex/

# Chapters that changed upstream AND that you have already converted.
chapters=""
for f in $(git diff --name-only "$old" "$new" -- 'tex/*.tex'); do
  ch="$(basename "$f" .tex)"
  if [ -f "qmd/.raw/$ch.qmd" ]; then
    chapters="$chapters $ch"
  else
    echo "(not converted yet, skipping: $ch)"
  fi
done

echo "== Merging $ref into $(git branch --show-current) =="
git merge --no-commit --no-ff "$ref"

[ -z "$chapters" ] && { echo "$new" > "$here/UPSTREAM_BASE"; echo "No converted chapters changed."; exit 0; }

# Convert the new LaTeX into a temp folder (the old base stays in qmd/ until we're done).
tmp="$(mktemp -d)"
for ch in $chapters; do "$here/tex_to_qmd.sh" "$ch" "$tmp"; done

echo "== Merging into your sections =="
clean=0; conflicted=0
while IFS= read -r mine; do
  key="$(sed -n '1s/^<!-- upstream: \(.*\) -->$/\1/p' "$mine")"
  [ -n "$key" ] || continue
  ch="${key%%/*}"
  case " $chapters " in *" $ch "*) ;; *) continue ;; esac

  base="qmd/.sections/$key.qmd"
  theirs="$tmp/.sections/$key.qmd"
  if [ ! -f "$theirs" ]; then
    echo "  REMOVED UPSTREAM: $key (used by $mine) — check by hand"
    continue
  fi

  # Give base and upstream the same marker line as mine, so it never looks like a change.
  b="$tmp/base.qmd"; t="$tmp/theirs.qmd"
  { head -n 1 "$mine"; cat "$base"; }   > "$b"
  { head -n 1 "$mine"; cat "$theirs"; } > "$t"

  if cmp -s "$b" "$t"; then continue; fi    # this section didn't change upstream

  rc=0
  git merge-file --diff3 -L mine -L base -L upstream "$mine" "$b" "$t" || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "  updated:  $mine"; clean=$((clean + 1))
  elif [ "$rc" -gt 0 ]; then
    echo "  CONFLICT: $mine ($rc)"; conflicted=$((conflicted + 1))
  else
    echo "  ERROR merging $mine" >&2; exit 1
  fi
done < <(find qmd/_sections -name '*.qmd' 2>/dev/null)

echo "== Sections added upstream (not in your book yet) =="
for ch in $chapters; do
  for label in $(cat "$tmp/.sections/$ch/_order.txt"); do
    [ -f "qmd/.sections/$ch/$label.qmd" ] || echo "  new: $ch/$label   (adopt with: $here/adopt.sh $ch/$label <name>)"
  done
done

# The new conversion becomes the base for next time.
for ch in $chapters; do
  cp "$tmp/.raw/$ch.qmd" "qmd/.raw/$ch.qmd"
  rm -rf "qmd/.sections/$ch"
  mv "$tmp/.sections/$ch" "qmd/.sections/$ch"
done
echo "$new" > "$here/UPSTREAM_BASE"
rm -rf "$tmp"

echo
echo "Done: $clean updated cleanly, $conflicted with conflicts."
echo "Nothing is committed yet. Review with 'git status' and 'git diff'."
echo "Accept: fix conflict markers (search for <<<<<<<), then: git add -A qmd .qmd_translation && git commit"
echo "Undo everything: git reset --hard"
