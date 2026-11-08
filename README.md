# dotfiles

Stow-style packages. Each top-level folder mirrors `$HOME`:

    nvim/.config/nvim/...   ->  ~/.config/nvim
    zsh/.zshrc              ->  ~/.zshrc
    bin/.local/bin/...      ->  ~/.local/bin/...

Link a package: `stow <package>` from this directory. Remove: `stow -D <package>`.

- `legacy/` is the previous layout, kept for reference.
- `noctalia/` holds `config.toml` only. GUI overrides live in `~/.local/state/noctalia/settings.toml` and are not tracked.
- Secrets (`.ssh`, tokens, keys) are never stored here.

## install.sh

Run after a minimal `archinstall`, and again any time later:

    ./install.sh             # pick desktops, then packages per category
    ./install.sh --dry-run   # show what would happen, change nothing
    ./install.sh --list      # print the catalog with live status, no menus
    ./install.sh --no-aur    # skip AUR lookups and installs

- Installs its own tools first (`gum`, `fzf`, `jq`, `stow`, `pacman-contrib`) and `yay` from the AUR.
- Packages come from `packages/catalog.txt` (format is described at the top of that file). Source (Official/AUR), size, and installed/update status are looked up live.
- Already installed packages start checked. Unchecking one offers removal (`pacman -Rns`) after a separate confirm; packages other packages need are kept.
- The search step finds any official or AUR package; picks are saved to `packages/extras.txt` and appear under "Extras" on later runs.
- At the summary: missing requirements (`needs=`) ask add/drop/keep, and two picks with the same job (`role=`) get a "redundant" warning.
- Selected packages with `stow=` get their config linked; files in the way are moved to `~/.k2-backup/<date>/`.
- New packages are installed with `pacman -Syu`, so installing also upgrades the system (no partial upgrades).

Phase 1: collect configs (done). Phase 2: `install.sh` (done). Phase 3: Arch ISO.
