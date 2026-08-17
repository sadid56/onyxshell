function fish_prompt --description 'Modern minimal single-line dynamic prompt'
    set -l last_status $status
    set -l is_git (command git rev-parse --is-inside-work-tree 2>/dev/null)

    # Dynamic color bindings with fallbacks
    set -l c_pri (set -q prompt_color_primary; and echo $prompt_color_primary; or echo "ffb3b4")
    set -l c_sec (set -q prompt_color_secondary; and echo $prompt_color_secondary; or echo "b5ccba")
    set -l c_ter (set -q prompt_color_tertiary; and echo $prompt_color_tertiary; or echo "8cd5cf")
    set -l c_txt (set -q prompt_color_text; and echo $prompt_color_text; or echo "e6e1e5")
    set -l c_err (set -q prompt_color_error; and echo $prompt_color_error; or echo "ffb4ab")

    # Directory path
    set_color $c_pri -o
    echo -n (prompt_pwd)

    # Git Status
    if test "$is_git" = "true"
        set -l branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null)
        set -l dirty (command git status --porcelain 2>/dev/null)
        
        echo -n " "
        set_color $c_ter
        echo -n " "
        
        if test -n "$dirty"
            set_color e5c18c -o
            echo -n "$branch *"
        else
            set_color $c_sec
            echo -n "$branch 󰄬"
        end
    end

    # Status Indicator Arrow
    if test $last_status -eq 0
        set_color $c_sec -o
        echo -n " 󰁔 "
    else
        set_color $c_err -o
        echo -n " 󰅖 "
    end
    set_color normal
end
