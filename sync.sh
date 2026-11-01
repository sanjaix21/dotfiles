#!/bin/bash
# copy live configs of tracked packages from $HOME into this repo (live -> repo)
# Usage: ./sync.sh [--dry-run]
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
OPT=(-a --exclude .git --exclude '*.bak*' --exclude __pycache__)
[ "${1:-}" = --dry-run ] && OPT+=(-n -v)
for pkg in */; do pkg=${pkg%/}
  case " legacy packages hooks " in *" $pkg "*) continue;; esac
  # whole app dirs under .config: sync dir (also picks up new files)
  for d in "$pkg"/.config/*/; do
    [ -d "$d" ] || continue
    rel=${d#"$pkg"/}; rel=${rel%/}
    [ -d "$HOME/$rel" ] && rsync "${OPT[@]}" "$HOME/$rel/" "$d"
  done
  # every other tracked file: copy live version if it exists
  while IFS= read -r f; do
    rel=${f#"$pkg"/}
    case $rel in .config/*/*) continue;; esac
    [ -f "$HOME/$rel" ] && rsync "${OPT[@]}" "$HOME/$rel" "$f"
  done < <(find "$pkg" -type f)
done
git status --short
