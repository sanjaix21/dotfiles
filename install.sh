#!/bin/bash
# K2 installer: packages -> backup conflicting files -> stow dotfiles -> hooks
# Usage: ./install.sh [--dry-run] [--no-aur]
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

DRY=0 AUR=1
for a in "$@"; do case $a in --dry-run) DRY=1;; --no-aur) AUR=0;; *) echo "unknown flag $a"; exit 1;; esac; done
run() { if [ $DRY = 1 ]; then echo "[dry] $*"; else "$@"; fi; }
list() { grep -vE '^\s*(#|$)' "$1"; }

[ -f /etc/arch-release ] || { echo "K2 installer needs Arch"; exit 1; }

echo "== packages (pacman)"
mapfile -t PKGS < <(list packages/pacman.txt)
run sudo pacman -S --needed --noconfirm "${PKGS[@]}"

if [ $AUR = 1 ] && [ -s packages/aur.txt ] && list packages/aur.txt | grep -q .; then
  echo "== packages (AUR)"
  helper=$(command -v paru || command -v yay || true)
  if [ -z "$helper" ]; then echo "no paru/yay, skipping AUR"; else
    mapfile -t APKGS < <(list packages/aur.txt)
    run "$helper" -S --needed --noconfirm "${APKGS[@]}"
  fi
fi

echo "== dotfiles"
BK="$HOME/.k2-backup/$(date +%Y%m%d-%H%M%S)"
SKIP=" legacy packages hooks "
for pkg in */; do pkg=${pkg%/}
  case "$SKIP" in *" $pkg "*) continue;; esac
  while IFS= read -r f; do
    t="$HOME/${f#"$pkg"/}"
    if [ -e "$t" ] || [ -L "$t" ]; then
      [ "$(readlink -f "$t")" = "$(readlink -f "$f")" ] && continue
      run mkdir -p "$BK/$(dirname "${f#"$pkg"/}")"
      run mv "$t" "$BK/${f#"$pkg"/}"
    fi
  done < <(find "$pkg" -type f)
  run stow -R -t "$HOME" "$pkg"
done

echo "== hooks"
for h in hooks/*.sh; do [ -e "$h" ] && { echo "-> $h"; run bash "$h"; }; done
echo "done. backups (if any): $BK"
