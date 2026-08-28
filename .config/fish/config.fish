# Fish Shell Modern Configuration

# Disable default welcome greeting
set -g fish_greeting ""

# Fastfetch Pokemon / Minimal banner on interactive startup
if status is-interactive
    fastfetch -c ~/.config/fastfetch/config-pokemon.jsonc 2>/dev/null
end

# Curated Developer Syntax Highlighting Theme (Catppuccin Pastel Palette)
set -g fish_color_normal cdd6f4
set -g fish_color_command 89b4fa --bold
set -g fish_color_keyword cba6f7 --bold
set -g fish_color_quote a6e3a1
set -g fish_color_redirection f5c2e7
set -g fish_color_end fab387
set -g fish_color_error f38ba8
set -g fish_color_param cdd6f4
set -g fish_color_comment 6c7086
set -g fish_color_selection --background=313244
set -g fish_color_search_match --background=313244
set -g fish_color_operator 94e2d5
set -g fish_color_escape f2cdcd
set -g fish_color_autosuggestion 6c7086
set -g fish_pager_color_prefix 89b4fa --bold
set -g fish_pager_color_completion cdd6f4
set -g fish_pager_color_description 6c7086
set -g fish_pager_color_progress 94e2d5

# Environment Variables
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL kitty
set -gx BROWSER brave-origin
set -gx QT_LOGGING_RULES "qt.svg.warning=false"

# Starship Prompt Integration
if command -q starship
    starship init fish | source
end

# Fuzzy Finder (FZF) Integration
if command -q fzf
    # Key bindings: Ctrl+T (files), Ctrl+R (history), Alt+C (cd into dir)
    fzf --fish | source 2>/dev/null
    
    set -gx FZF_DEFAULT_OPTS "--height 45% --layout=reverse --border rounded --prompt='󰍉 ' --pointer='󰁔 ' --marker='󰄬 ' --color=bg+:#2b2a27,fg+:#f0dede,hl:#89b4fa,hl+:#a6e3a1,pointer:#89b4fa,prompt:#89b4fa,border:#45475a,info:#6c7086"
    set -gx FZF_DEFAULT_COMMAND "find . -maxdepth 5 -not -path '*/.*'"
    set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    set -gx FZF_ALT_C_COMMAND "find . -maxdepth 4 -type d -not -path '*/.*'"
end

# Helpful Productivity Functions
function mkcd --description "Create directory and cd into it"
    mkdir -p $argv && cd $argv
end

function extract --description "Smart universal archive extractor"
    if test -f "$argv[1]"
        switch "$argv[1]"
            case "*.tar.bz2" "*.tbz2"; tar xjf "$argv[1]"
            case "*.tar.gz" "*.tgz";   tar xzf "$argv[1]"
            case "*.tar.xz" "*.txz";   tar xJf "$argv[1]"
            case "*.bz2";              bunzip2 "$argv[1]"
            case "*.rar";              unrar x "$argv[1]"
            case "*.gz";               gunzip "$argv[1]"
            case "*.tar";              tar xf "$argv[1]"
            case "*.zip";              unzip "$argv[1]"
            case "*.7z";               7z x "$argv[1]"
            case "*";                  echo "Unknown archive format: $argv[1]"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
end

function gi --description "Fetch gitignore template from gitignore.io"
    curl -sL "https://www.toptal.com/developers/gitignore/api/$argv"
end

function ports --description "View active listening TCP/UDP ports"
    sudo ss -tulpn | grep LISTEN
end

function myip --description "Display local and public IP addresses"
    echo -e "\033[1;34mLocal IP:\033[0m" (ip -br a | grep UP | awk '{print $3}')
    echo -e "\033[1;32mPublic IP:\033[0m" (curl -s ifconfig.me)
end

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
alias cls="clear"
alias q="exit"
alias reload-hypr="~/.config/hypr/scripts/reload.sh"
alias v="nvim"
alias vi="nvim"
alias nv="nvim"
alias clip="wl-copy"

# Git Quick Aliases
alias g="git"
alias gs="git status -sb"
alias ga="git add"
alias gaa="git add -A"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --oneline --graph --decorate -n 10"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"

# Docker Shortcuts
alias d="docker"
alias dc="docker compose"
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# Node / Package Managers
alias pn="pnpm"
alias yr="yarn"

# LS with colors & icons
alias ls="ls --color=auto --group-directories-first"
alias ll="ls -la --color=auto --group-directories-first"
alias la="ls -A --color=auto"

# Added by Antigravity CLI installer
set -gx PATH "$HOME/.local/bin" $PATH
