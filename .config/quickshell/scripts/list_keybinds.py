import os
import re
import json

def parse_keybinds():
    filepath = os.path.expanduser("~/.config/hypr/keybinds.lua")
    if not os.path.exists(filepath):
        return []

    keybinds = []
    
    # Pre-defined variables in keybinds.lua context
    variables = {
        "mainMod": "SUPER",
        "secondMod": "ALT",
        "terminal": "kitty",
        "fileManager": "kitty -e yazi",
        "menu": "Launcher",
        "browser": "brave-origin"
    }

    bind_pattern = re.compile(r'hl\.bind\(\s*(.*?)\s*,\s*(.*?)\s*\)')

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            # Ignore comments
            if line.startswith('--') or not line:
                continue
            
            match = bind_pattern.search(line)
            if match:
                key_expr = match.group(1)
                action_expr = match.group(2)

                # Skip loops/iterators
                if "i" in key_expr and not '"i"' in key_expr:
                    continue

                # Clean up keys expression
                # Replace Lua string concatenation and variables
                keys = key_expr
                for var, val in variables.items():
                    keys = re.sub(r'\b' + var + r'\b', val, keys)
                
                # Clean up dots and quotes
                keys = keys.replace('..', '').replace('"', '').replace("'", '').strip()
                keys = re.sub(r'\s*\+\s*', ' + ', keys)

                # Clean up action expression
                action = action_expr
                # Parse hl.dsp commands
                if action.startswith('hl.dsp.exec_cmd('):
                    action = action[16:-1] # Strip hl.dsp.exec_cmd( and )
                elif action.startswith('hl.dsp.'):
                    action = action[7:]
                
                # Replace variables in action
                for var, val in variables.items():
                    action = re.sub(r'\b' + var + r'\b', val, action)
                
                action = action.replace('"', '').replace("'", '').strip()

                keybinds.append({
                    "keys": keys,
                    "action": action
                })

    # Add workspace defaults as in awk script
    for i in range(1, 10):
        keybinds.append({"keys": f"SUPER + {i}", "action": f"focus workspace {i}"})
        keybinds.append({"keys": f"SUPER + SHIFT + {i}", "action": f"move window to workspace {i}"})
    
    keybinds.append({"keys": "SUPER + 0", "action": "focus workspace 10"})
    keybinds.append({"keys": "SUPER + SHIFT + 0", "action": "move window to workspace 10"})

    return keybinds

if __name__ == "__main__":
    print(json.dumps(parse_keybinds()))
