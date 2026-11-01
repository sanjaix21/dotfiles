# dotfiles

Stow-style packages. Each top-level folder mirrors `$HOME`:

    nvim/.config/nvim/...   ->  ~/.config/nvim
    zsh/.zshrc              ->  ~/.zshrc
    bin/.local/bin/...      ->  ~/.local/bin/...

Link a package: `stow <package>` from this directory. Remove: `stow -D <package>`.

- `legacy/` is the previous layout, kept for reference.
- `noctalia/` holds `config.toml` only. GUI overrides live in `~/.local/state/noctalia/settings.toml` and are not tracked.
- Secrets (`.ssh`, tokens, keys) are never stored here.

Phase 1: collect configs (done). Phase 2: `install.sh`. Phase 3: Arch ISO.
