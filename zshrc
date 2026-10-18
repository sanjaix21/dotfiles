# Flightman's config for zoomer shell

# PATH Config
path_prepend() {
  [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"
}

# prepend your paths here:
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.scripts"
path_prepend "$HOME/.cargo/bin/"
path_prepend "$HOME/go/bin/"
path_prepend "$HOME/.spicetify/"
path_prepend "$HOME/.scripts/Antigravity/"

# Aliases, add more in $HOME/.config/aliasrc
source "$HOME/.config/aliasrc"

# History settings
HISTSIZE=5000
SAVEHIST=5000
HISTFILE="$HOME/.zsh_history"

setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY       # share across shells
unsetopt INC_APPEND_HISTORY
setopt HIST_SUBST_PATTERN

# Load Colours
autoload -Uz colors && colors
autoload -Uz compinit && compinit

# case-insensitive + mid-word completion (pattern matching)
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z} r:|=*' \
  'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*' \
  'm:{a-zA-Z}={A-Za-z}'

# Menu like completion
zstyle ':completion:*' menu select

# plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null # autosuggestion

# prefix/substring search
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Disable magenta highlighting in history search
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=none'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=none'

# plugin settings
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#555555"

# Git prompt 
# git_info() {
#   git rev-parse --is-inside-work-tree &>/dev/null || return
#   local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
#   local dirty=$(git diff --name-only 2>/dev/null)
#   local staged=$(git diff --cached --name-only 2>/dev/null)
#   local untracked=$(git ls-files --others --exclude-standard 2>/dev/null)
#   local repo_icon="\ue65d"
#   local status_icon
#   if [ -n "$dirty" ] || [ -n "$untracked" ]; then
#     status_icon="%{$fg[red]%}\uf467%{$reset_color%}"
#   elif [ -n "$staged" ]; then
#     status_icon="%{$fg[yellow]%}\uf41e%{$reset_color%}"
#   else
#     status_icon="%{$fg[green]%}\ue315%{$reset_color%}"
#   fi
#   echo "-[ %{$fg[cyan]%}$repo_icon%{$reset_color%} $branch $status_icon %{$fg[cyan]%}]%{$reset_color%}"
# }

git_info() {
  git rev-parse --is-inside-work-tree &>/dev/null || return
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  local repo_icon="\ue65d"
  local status_icon
  
  if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
    status_icon="%{$fg[green]%}\ue315%{$reset_color%}"
  else
    status_icon="%{$fg[yellow]%}\uf467%{$reset_color%}"
  fi
  
  echo "-[ %{$fg[cyan]%}$repo_icon%{$reset_color%} $branch $status_icon %{$fg[cyan]%}]%{$reset_color%}"
}

# prompt
setopt prompt_subst
PROMPT='%{$fg[cyan]%}┌[%{$fg_bold[white]%}%n%{$reset_color%}%{$fg[cyan]%}@%{$fg_bold[white]%}%M%{$reset_color%}%{$fg[cyan]%}]%{$fg[white]%}-%{$fg[cyan]%}(%{$fg_bold[white]%}%~%{$reset_color%}%{$fg[cyan]%})$(git_info)%{$reset_color%}
└🪐 % '

# Keybindings

# autosuggest accept (Ctrl+Space)
bindkey '^ ' autosuggest-accept

# word navigation (Ctrl + ← / →)
bindkey "$terminfo[kLFT]" backward-word
bindkey "$terminfo[kRIT]" forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# open new terminal with same path as current terminal
if [[ "$COLORTERM" == "xfce4-terminal" ]] || [[ "$TERM" == "xterm" ]]; then
    precmd() {
        print -Pn "\e]7;file://${HOST}${PWD}\e\\"
    }
fi

# exit in current directory while exiting yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}


# Globbing
setopt dot_glob
setopt extended_glob

# Autostart scripts
conky_avatar.py

# Syntax highlighting plugin; should be at last
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
