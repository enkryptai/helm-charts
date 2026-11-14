#!/usr/bin/env bash
# Moves releasenotes/unreleased/*.md into a new RELEASENOTES.md section; see releasenotes/README.md.
set -euo pipefail
[[ $# -eq 1 && -n $1 ]] || { echo "usage: $0 \"<section heading>\"" >&2; exit 2; }
root=$(git rev-parse --show-toplevel)
notes=$root/RELEASENOTES.md
shopt -s nullglob
frags=("$root"/releasenotes/unreleased/*.md)
(( ${#frags[@]} )) || { echo "no fragments in releasenotes/unreleased/" >&2; exit 1; }
grep -q '^## ' "$notes" || { echo "no '## ' section in $notes to insert above" >&2; exit 1; }
section=$(mktemp)
trap 'rm -f "$section"' EXIT
{ printf '## %s\n\n' "$1"; for f in "${frags[@]}"; do cat "$f"; [[ $(tail -c1 "$f") == "" ]] || echo; done; echo; } > "$section"
awk -v s="$section" '!done && /^## / { while ((getline l < s) > 0) print l; done = 1 } { print }' "$notes" > "$notes.new"
mv "$notes.new" "$notes"
rm -f -- "${frags[@]}"; git -C "$root" add -A -- releasenotes/unreleased
echo "added '$1' with ${#frags[@]} fragment(s) to RELEASENOTES.md"
