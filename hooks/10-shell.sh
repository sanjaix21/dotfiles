#!/bin/bash
# set zsh as login shell
[ "$(basename "$SHELL")" = zsh ] || chsh -s "$(command -v zsh)"
