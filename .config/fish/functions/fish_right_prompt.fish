function fish_right_prompt --description 'Modern right prompt timestamp'
    set_color 757680
    echo -n "󱑂 "
    echo -n (date "+%H:%M:%S")
    set_color normal
end
