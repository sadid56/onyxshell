# Fish Shell Modern Configuration

# Disable default welcome greeting
set -g fish_greeting ""

# Fastfetch Pokemon / Minimal banner on interactive startup
if status is-interactive
    fastfetch -c ~/.config/fastfetch/config-pokemon.jsonc 2>/dev/null
end

# Environment Variables
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL kitty
set -gx BROWSER brave-origin

# Starship Prompt Integration
if command -q starship
    starship init fish | source
end



# Fuzzy Finder (FZF) Integration
if command -q fzf
    # Key bindings: Ctrl+T (files), Ctrl+R (history), Alt+C (cd into dir)
    fzf --fish | source 2>/dev/null
    
    set -gx FZF_DEFAULT_OPTS "--height 45% --layout=reverse --border rounded --prompt='󰍉 ' --pointer='󰁔 ' --marker='󰄬 ' --color=bg+:#2b2a27,fg+:#f0dede,hl:#ffb3b4,hl+:#ffb3b4,pointer:#ffb3b4,prompt:#ffb3b4,border:#49454f,info:#757680"
    set -gx FZF_DEFAULT_COMMAND "find . -maxdepth 5 -not -path '*/.*'"
    set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    set -gx FZF_ALT_C_COMMAND "find . -maxdepth 4 -type d -not -path '*/.*'"
end

# Helpful Productivity Functions
function fcd --description "Fuzzy jump into directories"
    set -l dir (find . -maxdepth 4 -type d -not -path '*/.*' 2>/dev/null | fzf --prompt="󰉋 Jump to: ")
    if test -n "$dir"
        cd "$dir"
    end
end

function fkill --description "Fuzzy interactive process killer"
    set -l pid (ps -ef | sed 1d | fzf -m --prompt="󰅖 Kill Process: " | awk '{print $2}')
    if test -n "$pid"
        echo $pid | xargs kill -9
        echo "Terminated PID(s): $pid"
    end
end

function fv --description "Fuzzy open files in Neovim"
    set -l file (fzf --prompt="󰈔 Open with Neovim: ")
    if test -n "$file"
        nvim "$file"
    end
end

# Useful Aliases
alias c="clear"
alias q="exit"
alias reload-hypr="~/.config/hypr/scripts/reload.sh"
alias v="nvim"
alias vi="nvim"

# Git Quick Aliases
alias gs="git status -sb"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate -n 10"
alias gd="git diff"

# LS with colors
alias ls="ls --color=auto --group-directories-first"
alias ll="ls -la --color=auto --group-directories-first"
alias la="ls -A --color=auto"
