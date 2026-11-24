#!/usr/bin/env bash
# List key terms used in my sections that have no definition in glossary.yml yet.
# Usage (from repo root): .qmd_translation/keyterms_missing.sh [files...]   (default: qmd/_sections/*.qmd)

set -euo pipefail
files=("$@"); [ ${#files[@]} -eq 0 ] && files=(qmd/_sections/*.qmd)

# glossary keys, lower-case
keys="$(grep -E '^[^#[:space:]][^:]*:' glossary.yml | sed 's/:.*//' | tr '[:upper:]' '[:lower:]')"

# [term]{.keyterm} or [text]{.keyterm term="key"}
perl -ne 'while (/\[([^\]]+)\]\{\.keyterm(?:\s+term="([^"]+)")?\}/g) { my $t = $2 // $1; $t =~ s/\s+/ /g; print lc($t), "\t$ARGV\n" }' "${files[@]}" |
  sort -u | while IFS=$'\t' read -r term file; do
    grep -qxF "$term" <<< "$keys" || printf '%-40s %s\n' "$term" "$file"
  done
