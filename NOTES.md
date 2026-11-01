# K2 notes

Things changed on this machine that the installer does not cover yet.
Turn each into a line in `packages/*.txt`, a file in a stow package, or a script in `hooks/`, then delete it here.

- [ ] swaync theme (config.json + style.css) and autostart line
- [ ] decide notification daemon / bar once Noctalia is gone
- [ ] re-add fastfetch config and logo.sh if wanted
- [ ] fonts/icons: GTK+Qt set to Noto Sans 11 + Papirus-Dark (gsettings, gtk-3.0/4.0 settings.ini, qt6ct.conf). Needs packages noto-fonts, papirus-icon-theme and a hook for the gsettings lines.
- [ ] zsh git prompt rewritten (branch icon, staged/changed/untracked/ahead/behind) + kitty symbol_map for Nerd glyphs (MesloLGM Nerd Font Mono; add ttf-meslo-nerd or switch to JetBrains Nerd)
- [ ] bar+notifications swap: waybar + swaync configs written (~/.config/waybar, ~/.config/swaync, teal accent). Pending: install waybar hyprlock wlogout cliphist, rewrite noctalia binds, autostart waybar+swaync, drop noctalia. Add stow packages waybar, swaync.

## Bar work (waybar-island from rhythmcreative/hyprland, bar only)
Installed live: ~/.config/quickshell/waybar-island/*.qml + helpers in ~/.local/bin:
notch-workspaces/hypr/audio/wifi/bt-helper, notch-sys-stats, notch-system-monitor, toggle-dnd/caffeine/nightlight,
island-fullscreens, privacy-status, clipboard-list, open-notification-app, screen-recorder-helper, battery-info, rofi-wifi-menu.
Skipped on purpose (sudo / self-update): system-ota, toggle-powersave, gpu-profile, battery-charge-limit, rust-dock-toggle-all, language + wallpaper helpers.
- [ ] sudo pacman -S quickshell; start with `quickshell -p ~/.config/quickshell/waybar-island`
- [ ] island has its own notification server -> conflicts with swaync; decide which owns notifications
- [ ] pywal optional (AUR python-pywal16-git) for ~/.cache/wal/colors.json colors
TODO list:
1. workspaces look ugly -> restyle
2. (add more)
