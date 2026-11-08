#!/bin/bash
# K2 installer: pick packages by category -> install/remove -> stow configs -> services -> hooks
# Safe to re-run: shows what is installed or has updates, and offers to remove unchecked packages.
# Usage: ./install.sh [--dry-run] [--no-aur] [--list]
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

DRY=0 AUR=1 LIST=0
for a in "$@"; do case $a in
  --dry-run) DRY=1;; --no-aur) AUR=0;; --list) LIST=1;;
  -h|--help) sed -n 2,4p "$0"; exit 0;;
  *) echo "unknown flag $a"; exit 1;;
esac; done
run() { if [ $DRY = 1 ]; then echo "[dry] $*"; else "$@"; fi; }
die() { echo "error: $*" >&2; exit 1; }
trim() { local s=$1; s=${s#"${s%%[![:space:]]*}"}; printf %s "${s%"${s##*[![:space:]]}"}"; }

[ -f /etc/arch-release ] || die "K2 installer needs Arch"
[ "$EUID" -ne 0 ] || die "run as your user; sudo is used when needed"

CATALOG=packages/catalog.txt EXTRAS=packages/extras.txt

# == bootstrap: tools the menu needs, then yay
need=()
for t in git:git makepkg:base-devel gum:gum fzf:fzf jq:jq curl:curl stow:stow checkupdates:pacman-contrib; do
  command -v "${t%%:*}" >/dev/null || need+=("${t#*:}")
done
if [ ${#need[@]} -gt 0 ] && [ $LIST = 0 ]; then
  [ $DRY = 1 ] && die "dry run needs these installed first: ${need[*]}"
  echo "== bootstrap: ${need[*]}"
  sudo pacman -S --needed --noconfirm "${need[@]}"
fi
if [ $AUR = 1 ] && ! command -v yay >/dev/null; then
  if [ $DRY = 1 ] || [ $LIST = 1 ]; then echo "[dry] yay missing, AUR packages skipped"; AUR=0; else
    echo "== bootstrap: yay"
    tmp=$(mktemp -d)
    git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
  fi
fi

# == catalog: pkg -> category / options / note, kept in file order
declare -A CAT=() OPT=() NOTE=()
ORDER=() CATS=()
load() {
  local cat pkg rest opts note
  [ -f "$1" ] || return 0
  while IFS='|' read -r cat pkg rest; do
    cat=$(trim "$cat"); [[ -z $cat || $cat == \#* ]] && continue
    pkg=$(trim "$pkg"); [ -n "$pkg" ] && [ -z "${CAT[$pkg]+x}" ] || continue
    if [[ $rest == *--* ]]; then opts=${rest%%--*}; note=$(trim "${rest#*--}"); else opts=$rest note=; fi
    CAT[$pkg]=$cat OPT[$pkg]=$(trim "$opts") NOTE[$pkg]=${note//,/;}
    ORDER+=("$pkg")
    [[ " ${CATS[*]} " == *" $cat "* ]] || CATS+=("$cat")
  done < "$1"
}
load "$CATALOG"
load "$EXTRAS"
# opt PKG KEY: value of key=value, "1" for a bare flag, empty if absent
opt() { local t; for t in ${OPT[$1]:-}; do case $t in "$2") echo 1; return;; "$2"=*) echo "${t#*=}"; return;; esac; done; }

# == desktops: decide which de= packages are shown
declare -A DE=()
DES=(hypr:Hyprland:hyprland i3:i3:i3-wm xfce:XFCE:xfce4-session)
declare -A INST=()
while read -r p; do INST[$p]=1; done < <(pacman -Qq)
if [ $LIST = 1 ]; then
  for d in "${DES[@]}"; do DE[${d%%:*}]=1; done
else
  labels=() pre=()
  for d in "${DES[@]}"; do IFS=: read -r key label marker <<< "$d"; labels+=("$label"); [ -n "${INST[$marker]+x}" ] && pre+=("$label"); done
  args=(--no-limit --header "Which desktops? (space toggle, enter next)")
  [ ${#pre[@]} -gt 0 ] && args+=(--selected "$(IFS=,; echo "${pre[*]}")")
  picked=$(gum choose "${args[@]}" "${labels[@]}") || exit 130
  for d in "${DES[@]}"; do IFS=: read -r key label marker <<< "$d"; grep -qx "$label" <<< "$picked" && DE[$key]=1; done
fi
visible() {
  local de d; de=$(opt "$1" de); [ -z "$de" ] && return 0
  for d in ${de//,/ }; do [ -n "${DE[$d]+x}" ] && return 0; done
  return 1
}
VIS=()
for p in "${ORDER[@]}"; do visible "$p" && VIS+=("$p"); done

# == live info: source, version, size, updates
declare -A SRC=() VER=() SIZE=() SIZEK=() UPD=()
lookup() {
  local n v s k ood rest=() q
  [ $# -gt 0 ] || return 0
  while IFS=$'\t' read -r n v s k; do SRC[$n]=Official VER[$n]=$v SIZE[$n]=$s SIZEK[$n]=$k; done < <(
    LC_ALL=C pacman -Si "$@" 2>/dev/null | awk -F' *: ' '
      /^Name/ {n=$2} /^Version/ {v=$2}
      /^Installed Size/ {
        split($2, a, " "); m = a[2]=="GiB" ? 1048576 : a[2]=="MiB" ? 1024 : a[2]=="KiB" ? 1 : 1/1024
        k = a[1]*m; s = k>=1048576 ? sprintf("%.1f GiB", k/1048576) : k>=1024 ? sprintf("%.1f MiB", k/1024) : sprintf("%d KiB", k)
        if (!(n in seen)) { seen[n]=1; printf "%s\t%s\t%s\t%d\n", n, v, s, k }
      }')
  for n in "$@"; do [ -n "${SRC[$n]+x}" ] || rest+=("$n"); done
  [ ${#rest[@]} -gt 0 ] || return 0
  for n in "${rest[@]}"; do SRC[$n]="?"; done
  [ $AUR = 1 ] || return 0
  q=$(printf '&arg[]=%s' "${rest[@]//+/%2B}")
  while IFS=$'\t' read -r n v ood; do
    SRC[$n]=AUR VER[$n]=$v
    [ "$ood" = ood ] && NOTE[$n]="AUR: flagged out of date${NOTE[$n]:+; ${NOTE[$n]}}"
  done < <(curl -fsS --max-time 15 "https://aur.archlinux.org/rpc/v5/info?${q#&}" 2>/dev/null |
    jq -r '.results[] | [.Name, .Version, (if .OutOfDate then "ood" else "-" end)] | @tsv' 2>/dev/null || true)
  for n in "${rest[@]}"; do [ "${SRC[$n]}" = "?" ] && NOTE[$n]="not found in repos or AUR${NOTE[$n]:+; ${NOTE[$n]}}"; done
  return 0
}
echo "== checking repos, AUR and updates..."
lookup "${VIS[@]}"
while read -r n _ _ v; do [ -n "$n" ] && UPD[$n]=$v; done < <(
  { checkupdates 2>/dev/null; [ $AUR = 1 ] && yay -Qua 2>/dev/null; } || true)

row() {
  local p=$1 st= r
  if [ -n "${UPD[$p]+x}" ]; then st="update"; elif [ -n "${INST[$p]+x}" ]; then st="installed"; fi
  r=$(printf '%-30s %-8s %10s  %-9s %s' "$p" "${SRC[$p]:-?}" "${SIZE[$p]:--}" "$st" "${NOTE[$p]:-}")
  printf '%s' "${r%"${r##*[! ]}"}"
}
HEAD=$(printf '%-30s %-8s %10s  %-9s %s' package source size status note)

if [ $LIST = 1 ]; then
  for c in "${CATS[@]}"; do
    echo; echo "── $c"; echo "   $HEAD"
    for p in "${VIS[@]}"; do [ "${CAT[$p]}" = "$c" ] && echo "   $(row "$p")"; done
  done
  exit 0
fi

# == menus: one screen per category
declare -A PICK=()
n=0
for c in "${CATS[@]}"; do n=$((n + 1))
  rows=() pre=()
  for p in "${VIS[@]}"; do
    [ "${CAT[$p]}" = "$c" ] || continue
    r=$(row "$p"); rows+=("$r")
    if [ -n "${INST[$p]+x}" ] || [ "$(opt "$p" on)" = 1 ]; then pre+=("$r"); fi
  done
  [ ${#rows[@]} -gt 0 ] || continue
  args=(--no-limit --height $((${#rows[@]} + 4)) --header "[$n/${#CATS[@]}] $c   (space toggle, enter next, esc quit)
  $HEAD")
  [ ${#pre[@]} -gt 0 ] && args+=(--selected "$(IFS=,; echo "${pre[*]}")")
  out=$(gum choose "${args[@]}" "${rows[@]}") || exit 130
  while read -r r; do [ -n "$r" ] && PICK[${r%% *}]=1; done <<< "$out"
done

# == search: any official or AUR package, remembered in packages/extras.txt
if gum confirm --default=false "Search for more apps (official + AUR)?"; then
  picks=$({
      pacman -Sl | awk '!seen[$2]++ {printf "%-40s %s\n", $2, $1}'
      [ $AUR = 1 ] && yay -Sl aur 2>/dev/null | awk '{printf "%-40s aur\n", $2}'
    } | fzf --multi --prompt "search> " --header "tab select, enter done, esc skip" \
        --preview 'yay -Si {1} 2>/dev/null || pacman -Si {1}' --preview-window right,60%,wrap) || true
  new=()
  for p in $(awk '{print $1}' <<< "$picks"); do
    PICK[$p]=1
    [ -n "${CAT[$p]+x}" ] && continue
    CAT[$p]=Extras ORDER+=("$p") VIS+=("$p") new+=("$p")
    if [ $DRY = 1 ]; then echo "[dry] remember $p in $EXTRAS"; else
      [ -f "$EXTRAS" ] || echo "# apps added from the installer search; same format as catalog.txt" > "$EXTRAS"
      echo "Extras | $p" >> "$EXTRAS"
    fi
  done
  lookup "${new[@]}"
fi

# == checks: missing requirements, redundant roles, login screen
has() { [ -n "${PICK[$1]+x}" ] || [ -n "${INST[$1]+x}" ]; }
changed=1
while [ $changed = 1 ]; do changed=0
  for p in "${ORDER[@]}"; do
    [ -n "${PICK[$p]+x}" ] || continue
    for alts in $(opt "$p" needs | tr , ' '); do
      ok=0; for d in ${alts//\// }; do has "$d" && ok=1; done
      [ $ok = 1 ] && continue
      d=${alts%%/*}
      ans=$(gum choose --header "$p needs ${alts//\// or }, which is not selected or installed" "Add $d" "Drop $p" "Keep anyway") || exit 130
      case $ans in
        Add*) PICK[$d]=1; changed=1
              [ -n "${CAT[$d]+x}" ] || { CAT[$d]=Extras; ORDER+=("$d"); }
              [ -n "${SRC[$d]+x}" ] || lookup "$d";;
        Drop*) unset "PICK[$p]"; break;;
      esac
    done
  done
done

declare -A RM=()
for p in "${VIS[@]}"; do [ -n "${INST[$p]+x}" ] && [ -z "${PICK[$p]+x}" ] && RM[$p]=1; done
KEPT=()
if [ ${#RM[@]} -gt 0 ]; then
  while IFS=$'\t' read -r p by; do [ "$by" != None ] && { unset "RM[$p]"; KEPT+=("$p (needed by $by)"); }; done < <(
    LC_ALL=C pacman -Qi "${!RM[@]}" | awk -F' *: ' '/^Name/ {n=$2} /^Required By/ {print n "\t" $2}')
fi

WARN=()
for d in "${DES[@]}"; do IFS=: read -r key label marker <<< "$d"
  [ -n "${DE[$key]+x}" ] || continue
  declare -A ROLE=()
  for p in "${VIS[@]}"; do
    { [ -n "${PICK[$p]+x}" ] || { [ -n "${INST[$p]+x}" ] && [ -z "${RM[$p]+x}" ]; }; } || continue
    de=$(opt "$p" de); [ -z "$de" ] || [[ ",$de," == *",$key,"* ]] || continue
    for r in $(opt "$p" role | tr , ' '); do ROLE[$r]="${ROLE[$r]:-} $p"; done
  done
  for r in "${!ROLE[@]}"; do
    # shellcheck disable=SC2086
    set -- ${ROLE[$r]}; [ $# -gt 1 ] && WARN+=("$label: redundant $r:$(printf ' %s' "$@") (your config uses one)")
  done
  unset ROLE
done
login=0
for p in "${ORDER[@]}"; do [ "$(opt "$p" role)" = login ] && has "$p" && [ -z "${RM[$p]+x}" ] && login=1; done
[ $login = 1 ] || WARN+=("no login screen picked: you will start the desktop from a tty")

# == plan
OFF=() AURP=() total=0
for p in "${ORDER[@]}"; do
  [ -n "${PICK[$p]+x}" ] && [ -z "${INST[$p]+x}" ] || continue
  if [ "${SRC[$p]:-}" = Official ]; then OFF+=("$p"); total=$((total + ${SIZEK[$p]:-0})); else AURP+=("$p"); fi
done
STOW=() SVC=() USVC=() HOOKS=() UNSTOW=()
for p in "${ORDER[@]}"; do
  [ -n "${PICK[$p]+x}" ] || continue
  for s in $(opt "$p" stow | tr , ' '); do [[ " ${STOW[*]} " == *" $s "* ]] || STOW+=("$s"); done
  s=$(opt "$p" svc); [ -n "$s" ] && SVC+=("$s")
  s=$(opt "$p" usvc); [ -n "$s" ] && USVC+=("$s")
  s=$(opt "$p" hook); [ -n "$s" ] && HOOKS+=("$s")
done
for p in "${!RM[@]}"; do
  for s in $(opt "$p" stow | tr , ' '); do
    [[ " ${STOW[*]} " == *" $s "* || " ${UNSTOW[*]} " == *" $s "* ]] || UNSTOW+=("$s")
  done
done
[ $AUR = 1 ] || { [ ${#AURP[@]} -gt 0 ] && WARN+=("--no-aur: skipping ${AURP[*]}"); AURP=(); }

show() { [ $# -gt 1 ] && printf '  %-16s %s\n' "$1" "${*:2}"; return 0; }
echo
gum style --bold "Plan"
show "official:" "${OFF[@]}"
[ ${#OFF[@]} -gt 0 ] && printf '  %-16s %s\n' "" "$(awk -v k=$total 'BEGIN { if (k >= 1048576) printf "%.1f GiB", k/1048576; else printf "%.1f MiB", k/1024 }') installed size"
show "AUR:" "${AURP[@]}"
show "remove:" "${!RM[@]}"
show "unlink config:" "${UNSTOW[@]}"
show "kept:" "${KEPT[@]}"
show "link config:" "${STOW[@]}"
show "services:" "${SVC[@]}" "${USVC[@]}"
show "hooks:" "${HOOKS[@]}"
[ ${#UPD[@]} -gt 0 ] && printf '  %-16s %s\n' "updates:" "${#UPD[@]} available; installing runs a full upgrade (pacman -Syu)"
for w in "${WARN[@]}"; do echo "  ! $w"; done
echo
gum confirm "Apply this plan?" || exit 0

# == apply
if [ ${#OFF[@]} -gt 0 ]; then
  echo "== official packages"; run sudo pacman -Syu --needed "${OFF[@]}"
elif [ ${#UPD[@]} -gt 0 ] && gum confirm --default=false "Nothing new from the repos. Run a full upgrade anyway?"; then
  run yay -Syu
fi
if [ ${#AURP[@]} -gt 0 ]; then echo "== AUR packages"; run yay -S --needed --aur "${AURP[@]}"; fi
if [ ${#RM[@]} -gt 0 ] && gum confirm --default=false "Remove ${!RM[*]}? (pacman -Rns, also removes their unused deps)"; then
  echo "== remove"; run sudo pacman -Rns "${!RM[@]}"
  for s in "${UNSTOW[@]}"; do run stow -D -t "$HOME" "$s"; done
fi

echo "== dotfiles"
BK="$HOME/.k2-backup/$(date +%Y%m%d-%H%M%S)"
for pkg in "${STOW[@]}"; do
  [ -d "$pkg" ] || { echo "no stow package $pkg/, skipping"; continue; }
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

echo "== services"
for u in "${SVC[@]}"; do
  systemctl is-enabled -q "$u" 2>/dev/null && continue
  # login screens start on next boot, not mid-install
  case $u in lightdm.service|sddm.service) now=();; *) now=(--now);; esac
  run sudo systemctl enable "${now[@]}" "$u" || echo "could not enable $u"
done
for u in "${USVC[@]}"; do
  systemctl --user is-enabled -q "$u" 2>/dev/null || run systemctl --user enable --now "$u" || echo "could not enable $u"
done

echo "== hooks"
for h in "${HOOKS[@]}"; do [ -f "hooks/$h" ] && { echo "-> $h"; run bash "hooks/$h"; }; done
echo "done. backups (if any): $BK"
