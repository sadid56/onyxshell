#!/bin/bash
CONF_FILE="$HOME/.config/hypr/keybinds.lua"

awk '
BEGIN {
    mainMod = "SUPER"
    secondMod = "ALT"
    terminal = "kitty"
    fileManager = "kitty -e yazi"
    menu = "rofi -show drun"
    browser = "brave-origin"
}
/^[ \t]*--/ { next }
/^[ \t]*$/ { next }

/^[ \t]*hl\.bind\(/ {
    # Extract arguments manually using match
    match($0, /hl\.bind\(([^,]+),\s*(.+)\)/, groups)
    key = groups[1]
    action = groups[2]
    
    # Remove trailing options if any
    sub(/,\s*\{[^}]*\}\s*$/, "", action)
    
    # Substitutions
    gsub("mainMod", mainMod, key)
    gsub("secondMod", secondMod, key)
    gsub("terminal", terminal, action)
    gsub("fileManager", fileManager, action)
    gsub("menu", menu, action)
    gsub("browser", browser, action)
    
    # Remove Lua concatenations and quotes in key
    gsub(/[ \t]*\.\.[ \t]*/, "", key)
    gsub(/"/, "", key)
    gsub(/'\''/, "", key)
    
    # Remove Lua concatenations and quotes in action
    gsub(/[ \t]*\.\.[ \t]*/, "", action)
    
    # Parse hl.dsp commands
    if (action ~ /^hl\.dsp\.exec_cmd\(/) {
        sub(/^hl\.dsp\.exec_cmd\(/, "", action)
        sub(/\)$/, "", action)
    } else {
        sub(/^hl\.dsp\./, "", action)
    }
    
    gsub(/"/, "", action)
    gsub(/'\''/, "", action)
    
    # Trim key
    gsub(/^[ \t]+|[ \t]+$/, "", key)
    
    if (key ~ /\<i\>/ || key ~ /\.\. i/ || key ~ /\.\.i/) { next }
    
    print key "  " action
}
END {
    for (i=1; i<=9; i++) {
        print "SUPER + " i "  focus workspace " i
    }
    for (i=1; i<=9; i++) {
        print "SUPER + SHIFT + " i "  move window to workspace " i
    }
    print "SUPER + 0  focus workspace 10"
    print "SUPER + SHIFT + 0  move window to workspace 10"
}
' "$CONF_FILE" |
  column -t -s '' |
  rofi -dmenu -i -p "Keybinds" -theme ~/.config/hypr/styles/keybinds.rasi
