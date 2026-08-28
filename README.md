# ❄️ Onyxshell

<div align="center">

![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-00c8ff?style=for-the-badge&logo=hyprland&logoColor=white)
![Quickshell](https://img.shields.io/badge/Quickshell-Official_Package-7b2cbf?style=for-the-badge)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-100%25_Official_Repo-1793d1?style=for-the-badge&logo=archlinux&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-5.4-000080?style=for-the-badge&logo=lua&logoColor=white)
![Fish Shell](https://img.shields.io/badge/Fish-Shell-38bdf8?style=for-the-badge&logo=gnubash&logoColor=white)

**An ultra-modern, fluid, and battery-efficient desktop suite for Hyprland powered by Quickshell. Tailored for daily driving with seamless animations, dynamic islands, smart dock, and Material You theming — 100% installable via official Arch Linux repositories without any AUR dependency.**

---

</div>

## ✨ Key Highlights

- 🏝️ **Dynamic Island Top Bar**: 
  - **Left Island**: Real-time workspaces, active window title pill, and event-driven MPRIS Media visualizer.
  - **Center Notch**: Sleek clock pill expanding into a full calendar with quick action controls.
  - **Right Island**: Live network telemetry, system resource monitor with real-time graphs & process manager, system tray, and power menu.
  - **Smart Spacing**: Leftward smooth island displacement whenever right popups expand, preventing any visual overlaps.
- 🚢 **Smart Dock**:
  - Auto-hides when windows are present on workspace; auto-shows on empty desktop.
  - Live window thumbnail previews, running indicators, pinned apps, and dynamic unpinned client tracking.
  - Complete dropdown scratchpad isolation.
- ⚡ **Scratchpad & Dropdown**:
  - Dedicated dropdown terminal (`SUPER + Q`).
  - Special workspace (`special:magic`) with quick move and toggle shortcuts.
- 🎨 **Settings GUI**:
  - Full graphical settings app (`SUPER + I` or via control center) for live accent color, border width, corner radius, window opacity, and dock preferences.
- 🔤 **Crisp Font Rendering**:
  - Built-in fontconfig and Qt/KDE global profiles ensuring perfect subpixel rendering, antialiasing, and hinting across Qt (Kdenlive, Dolphin) and GTK apps.

---

## 📦 Installation (Arch Linux / Arch-based Distros)

> [!NOTE]
> Onyxshell is 100% installable using the official **Arch Linux `pacman`** repository without needing `yay`, `paru`, or any AUR helpers. All core desktop packages (including `quickshell`, `hyprland`, and fonts) are pulled from official repos.

### Quick Install

```bash
git clone https://github.com/sadid56/onyxshell.git ~/onyxshell
cd ~/onyxshell
chmod +x install.sh
./install.sh
```

The installer will:
1. Detect Arch Linux and install all required official packages (`hyprland`, `quickshell`, `kitty`, `fish`, `python-psutil`, fonts, etc.) via `pacman`.
2. Automatically back up any existing configurations in `~/.config/`.
3. Copy all dotfiles into place and configure executable permissions.

---

## ⌨️ Keybindings Cheat Sheet

### Application Launchers
| Shortcut | Description |
| :--- | :--- |
| `SUPER + RETURN` | Open Default Terminal (`$TERMINAL` / Kitty) |
| `ALT + SPACE` | Open Quickshell Application Launcher |
| `SUPER + E` | Open File Manager (Yazi / Dolphin) |
| `SUPER + B` | Launch Default Browser |
| `SUPER + Q` | Toggle Dropdown Terminal |
| `SUPER + V` | Open Clipboard History |
| `SUPER + PERIOD` | Open Emoji Picker |

### Window Management
| Shortcut | Description |
| :--- | :--- |
| `SUPER + C` | Close Focused Window |
| `SUPER + SPACE` | Toggle Window Floating |
| `SUPER + F` | Toggle Fullscreen |
| `SUPER + P` | Pin Window across All Workspaces |
| `SUPER + J` | Toggle Split Layout |

### Workspaces & Special Scratchpad
| Shortcut | Description |
| :--- | :--- |
| `SUPER + 1..9` | Switch to Workspace 1-9 |
| `SUPER + SHIFT + 1..9` | Move Focused Window to Workspace 1-9 |
| `SUPER + S` | **Toggle Special Workspace (Scratchpad)** |
| `SUPER + CTRL + S` | **Move Window to Special Workspace** |
| `SUPER + CTRL + Y` | **Move Window out of Special Workspace** |

### System & Power
| Shortcut | Description |
| :--- | :--- |
| `SUPER + M` | Open Power Menu (with Arrow Keys & Enter navigation) |
| `SUPER + L` | Lock Screen (Hyprlock) |
| `SUPER + SHIFT + S` | Interactive Region Screenshot |
| `PRINT` | Fullscreen Screenshot |
| `SUPER + SHIFT + R` | Reload Hyprland & Desktop Shell |

---

## 🔄 Sync & Update

To synchronize your live `~/.config/` modifications back into the local `onyxshell` repository:

```bash
cd ~/onyxshell
./update.sh
```

---

## 🛠️ Stack & Technologies

- **Compositor**: Hyprland (Configured via modular Lua)
- **Shell & UI**: Quickshell (QML / QtQuick)
- **Terminal**: Kitty / Yazi / Fastfetch / Cava
- **Shell**: Fish with Starship prompt
- **Dependencies**: `python-psutil`, `playerctl`, `wl-clipboard`, `cliphist`, `wireplumber`
