# Check if terminal supports advanced features
if [[ "$TERM" != "dumb" && "$TERM" != "linux" ]]; then
  _ADVANCED_TERMINAL=1
else
  _ADVANCED_TERMINAL=0
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if (( _ADVANCED_TERMINAL )); then
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi
fi

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
export SUDO_EDITOR=vim
export EDITOR=vim

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if (( _ADVANCED_TERMINAL )); then
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fi

# basic prompt for tty, forcing it here since prezto disables themes for dumb terminals
if [[ "$TERM" == "linux" ]]; then
  prompt skwp
fi

# fnm
FNM_PATH="/home/ivan/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

if (( _ADVANCED_TERMINAL )); then
  source <(fzf --zsh)
fi


# zoxide
eval "$(zoxide init zsh)"

# aliases
alias bat="batcat"

# Base ls replacement: directories first, icons, git
alias ls='eza --group-directories-first --icons --git'

# Single column, include hidden files
alias l='eza -1 -a --icons --git'

# Long list, human-readable sizes
alias ll='eza -lh --icons --git --header'

# Recursive, long, human-readable
alias lr='eza -lhR --icons --git'

# Long list, human-readable, include hidden
alias la='eza -lha --icons --git'

# Long list, hidden, piped to pager
alias lm='eza -lha --icons --git | less -R'

# Sort by extension
alias lx='eza -lh --sort=extension --icons --git'

# Sort by size (largest last)
alias lk='eza -lh --sort=size --reverse --icons --git'

# Sort by date (most recent last)
alias lt='eza -lh --sort=modified --reverse --icons --git --time-style=long-iso'

# Sort by change time (ctime)
alias lc='eza -lh --sort=changed --reverse --icons --git --time-style=long-iso'

# Sort by access time (atime)
alias lu='eza -lh --sort=accessed --reverse --icons --git --time-style=long-iso'
