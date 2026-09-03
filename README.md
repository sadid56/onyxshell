# ❄️ Onyxshell

<div align="center">

![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-00c8ff?style=for-the-badge&logo=hyprland&logoColor=white)
![Quickshell](https://img.shields.io/badge/Quickshell-Official_Package-7b2cbf?style=for-the-badge)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-100%25_Official_Repo-1793d1?style=for-the-badge&logo=archlinux&logoColor=white)
![Fedora](https://img.shields.io/badge/Fedora-Supported-51a2da?style=for-the-badge&logo=fedora&logoColor=white)
![openSUSE](https://img.shields.io/badge/openSUSE-Supported-73ba25?style=for-the-badge&logo=opensuse&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-5.4-000080?style=for-the-badge&logo=lua&logoColor=white)
![Fish Shell](https://img.shields.io/badge/Fish-Shell-38bdf8?style=for-the-badge&logo=gnubash&logoColor=white)

**An ultra-modern, fluid, and battery-efficient desktop suite for Hyprland powered by Quickshell. Tailored for daily driving with seamless animations, dynamic island notch bar, native C performance suite, and Material You theming — with modular multi-distro installation support.**

<br />

<p align="center">
  <img src="assets/desktop.png" alt="Onyxshell Desktop View" width="100%" />
</p>

</div>

---

## ✨ Key Highlights

- 🏝️ **Dynamic Island Notch Top Bar**: 
  - **Left Island**: Distro branding, real-time workspace switcher (up to 4 dynamic window icons per workspace), active window title pill, and built-in event-driven MPRIS media controls (zero background processes).
  - **Center Notch**: Sleek clock and date pill expanding into the Quick Settings & Notification Center with sliders for volume, microphone, brightness, and night light.
  - **Right Island**: Real-time network speed telemetry, system resource indicators (CPU, RAM, Battery), system tray island pill, and power menu.
- 🚀 **Built-in Application Launcher (`ALT + SPACE`)**:
  - Blazing-fast desktop search powered directly by Quickshell's native C++ `DesktopEntries` engine with real-time inotify app monitoring.
  - Seamless system icon resolution for all native desktop applications.
- ⚡ **High-Performance C Suite (`c_tools`)**:
  - Nanosecond CPU, RAM, and network telemetry daemon (`sys_telemetry`).
  - Top system resource consumers gauge monitor (`sys_resources`).
  - Smart geometric window floating manager (`toggle_float`).
  - Ultra-fast clipboard image preview decoder (`decode_clip`).
- ⚡ **Scratchpad & Dropdown Terminal**:
  - Dedicated dropdown terminal toggle (`SUPER + Q`).
  - Special workspace (`special:magic`) with quick move (`SUPER + CTRL + S`) and return shortcuts (`SUPER + CTRL + Y`).
- 🔄 **macOS-Style Alt+Tab Window Switcher**:
  - Fast quick-switching and visual preview card navigation across open windows.
- 📋 **Integrated Clipboard & Emoji Pickers**:
  - Instant searchable clipboard manager (`SUPER + V`) with cliphist integration and XDG-compliant cache storage (`~/.cache/qs/`).
  - Built-in emoji picker (`SUPER + ,`).
- 🌙 **Native Night Light (Hyprsunset)**:
  - Zero-lag hardware-accelerated blue light filter with color temperature slider and persistent state management.
- 🔤 **Crisp Font Rendering**:
  - Preconfigured fontconfig, JetBrains Mono Nerd Font, Noto fonts, and Qt5/Qt6 unified styling.

---

## 📦 Installation

Onyxshell includes an organic, modular installer with automated distribution detection and package management for **Arch Linux**, **Fedora**, and **openSUSE**.

```bash
git clone https://github.com/sadid56/onyxshell.git ~/onyxshell
cd ~/onyxshell
chmod +x install.sh
./install.sh
```

### 🔧 What the installer does:
1. **Distro Detection**: Automatically recognizes your distribution (`arch`, `fedora`, `opensuse`) and uses the appropriate native package manager (`pacman`, `dnf`, `zypper`).
2. **Package Setup**: Installs all required core dependencies without requiring any AUR helpers on Arch Linux.
3. **Safe Backup**: Automatically creates a timestamped backup of existing configs in `~/.config/onyxshell_backup_<timestamp>`.
4. **Dotfile Deployment**: Deploys configurations to `~/.config/` and sets proper script executable permissions.
5. **C Performance Suite**: Automatically builds native C tools using `make`.
6. **Display Manager**: Organically checks for active login managers (`sddm`, `gdm`, `greetd`, etc.) and optionally configures `greetd` (`tuigreet`) if no DM is active.
7. **Shell Setup**: Prompts to configure `fish` as your default shell.
8. **Wallpapers (Recommended)**: Prompts to download and install the curated wallpaper collection.

---

## 🖼️ Wallpaper Collection (Recommended)

Onyxshell integrates seamlessly with the official aesthetic wallpaper collection. You can install it anytime using:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/sadid56/wallpaper/main/install.sh)"
```

---

## ⌨️ Keybindings

All default shortcuts, window navigation rules, workspace gestures, and multimedia keys are fully documented in the dedicated Keybindings guide:

👉 **[View Full Keybindings Reference (KEYBINDS.md)](KEYBINDS.md)**

### Essential Shortcuts at a Glance

| Shortcut | Action |
| :--- | :--- |
| `ALT + SPACE` | **Open Application Launcher** |
| `SUPER + RETURN` | Open Default Terminal (Kitty) |
| `SUPER + Q` | Toggle Dropdown Scratchpad Terminal |
| `SUPER + X` | Close Focused Window |
| `SUPER + SPACE` | Toggle Window Floating |
| `SUPER + S` | Toggle Special Workspace (Scratchpad) |
| `SUPER + V` | Open Clipboard History |
| `SUPER + ,` | Open Emoji Picker |
| `SUPER + N` | Open Notification Center & Quick Settings |
| `SUPER + M` | Open Power Menu |

---

## 🔄 Sync & Update

To synchronize your live `~/.config/` modifications back into the local `onyxshell` repository:

```bash
cd ~/onyxshell
./update.sh
```
