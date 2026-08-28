import QtQuick

QtObject {
    id: appIconUtils

    function mapClassToIcon(cls, title) {
        if (!cls) return "";
        cls = cls.toLowerCase();
        title = (title || "").toLowerCase();

        if (title.indexOf("nvim") !== -1 || title.indexOf("vim") !== -1) return "";
        if (title.indexOf("btop") !== -1 || title.indexOf("htop") !== -1) return "";
        if (title.indexOf("yazi") !== -1) return "󰇥";
        if (title.indexOf("spotify") !== -1) return "";

        if (cls === "kitty" || cls === "alacritty" || cls === "wezterm" || cls === "foot" || cls === "kitty-dropdown") return "";

        if (cls === "code" || cls === "code-url-handler" || cls.indexOf("cursor") !== -1 || cls === "vscodium") return "󰨞";
        if (cls === "antigravity-ide" || cls.indexOf("antigravity") !== -1) return "";
        if (cls.indexOf("jetbrains-") === 0 || cls === "idea") return "󰘦";
        if (cls === "emacs") return "";
        if (cls === "neovim" || cls === "nvim") return "";

        if (cls.indexOf("brave") !== -1) return "󰈹";
        if (cls === "firefox" || cls.indexOf("zen") !== -1) return "󰈹";
        if (cls === "google-chrome" || cls === "chromium" || cls === "vivaldi-stable") return "";

        if (cls === "postman" || cls === "insomnia") return "󱂛";
        if (cls.indexOf("docker") === 0) return "󰡨";
        if (cls === "github-desktop" || cls === "gitkraken") return "";
        if (cls === "dbeaver" || cls.indexOf("mongodb") !== -1 || cls === "datagrip") return "󰆼";

        if (cls === "spotify") return "";
        if (cls === "vlc" || cls === "mpv") return "󰕼";
        if (cls === "com.obsproject.studio") return "󰑋";
        if (cls === "steam") return "󰓓";

        if (cls === "discord" || cls === "vesktop" || cls === "webcord") return "";
        if (cls === "org.telegram.desktop" || cls === "telegram-desktop") return "";
        if (cls === "slack") return "󰒱";
        if (cls === "teams-for-linux") return "󰊻";
        if (cls === "zoom") return "";

        if (cls === "obsidian" || cls === "notion-app") return "󱓧";
        if (cls.indexOf("localsend") !== -1 || title.indexOf("localsend") !== -1) return "";
        if (cls === "thunar" || cls.indexOf("dolphin") !== -1 || cls.indexOf("nautilus") !== -1 || cls === "nautilus") return "";

        if (cls.indexOf("clock") !== -1 || title.indexOf("clock") !== -1) return "";
        if (cls.indexOf("calendar") !== -1 || cls === "morgen" || cls === "korganizer" || title.indexOf("calendar") !== -1) return "󰸗";
        if (cls.indexOf("calc") !== -1 || cls.indexOf("qalculate") !== -1 || cls === "speedcrunch" || title.indexOf("calculator") !== -1) return "󰪚";

        if (cls.indexOf("pavucontrol") !== -1) return "󰕾";
        if (cls === "blueman-manager") return "󰂯";
        if (cls === "nm-connection-editor") return "󰤨";

        return "";
    }
}
