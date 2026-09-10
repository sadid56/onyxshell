import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import "../components/containers"
import "./components"

Popup {
    id: wallpaperWindow

    popupWidth: Screen.width * 0.82
    popupHeight: 250
    topOverlap: 10
    showCorners: false

    contentRectY: active ? Screen.height - popupHeight - 20 : Screen.height + 20

    readonly property string quickshellDir: (typeof root !== "undefined" && root && root.shellConfig)
        ? root.shellConfig.quickshellDir
        : (Quickshell.env("HOME") + "/.config/qs")
    readonly property string wallpapersDir: (typeof root !== "undefined" && root && root.shellConfig)
        ? (root.shellConfig.homeDir + "/Pictures/wallpapers")
        : (Quickshell.env("HOME") + "/Pictures/wallpapers")

    property var wallpapersList: []
    property bool animationsEnabled: false

    FileView {
        id: currentWallpaperFile
        path: wallpaperWindow.quickshellDir + "/current_wallpaper"
        watchChanges: true
        blockLoading: true
    }

    Component.onCompleted: {
        refreshWallpapers();
    }

    onActiveChanged: {
        if (active) {
            wallpaperWindow.animationsEnabled = false;
            if (currentWallpaperFile && typeof currentWallpaperFile.reload === "function") {
                currentWallpaperFile.reload();
            }
            if (!wallpapersList || wallpapersList.length === 0) {
                refreshWallpapers();
            } else {
                selectCurrentWallpaper(false);
                Qt.callLater(() => {
                    selectCurrentWallpaper(false);
                    wallpapersListInst.forceActiveFocus();
                });
            }
        } else {
            wallpaperWindow.animationsEnabled = false;
        }
    }

    function refreshWallpapers() {
        wallpaperFetcher.running = false;
        wallpaperFetcher.running = true;
    }

    function getScrollTarget(index) {
        if (!wallpapersList || wallpapersList.length === 0) return 0;
        var cardTotalWidth = 280 + 32;
        var totalW = wallpapersList.length * cardTotalWidth - 32;
        var listW = wallpapersListInst.width > 0 ? wallpapersListInst.width : wallpaperWindow.popupWidth;
        var targetX = index * cardTotalWidth - (listW - 280) / 2;
        var maxScroll = Math.max(0, totalW - listW);
        return Math.max(0, Math.min(targetX, maxScroll));
    }

    function selectCurrentWallpaper(animate) {
        if (!wallpapersList || wallpapersList.length === 0) return;
        var currentPath = "";
        if (typeof wallpaperBackground !== "undefined" && wallpaperBackground && wallpaperBackground.currentWallpaperPath) {
            currentPath = wallpaperBackground.currentWallpaperPath;
        } else {
            if (currentWallpaperFile && typeof currentWallpaperFile.reload === "function") {
                currentWallpaperFile.reload();
            }
            var fileText = (typeof currentWallpaperFile.text === "function") ? currentWallpaperFile.text() : currentWallpaperFile.text;
            if (fileText) currentPath = fileText.trim();
        }

        var indexToSelect = 0;
        if (currentPath !== "") {
            for (var i = 0; i < wallpapersList.length; i++) {
                if (wallpapersList[i].path === currentPath) {
                    indexToSelect = i;
                    break;
                }
            }
        }
        wallpapersListInst.currentIndex = indexToSelect;
        var targetX = getScrollTarget(indexToSelect);
        if (animate === false) {
            wallpaperWindow.animationsEnabled = false;
            wallpapersListInst.contentX = targetX;
            Qt.callLater(() => {
                wallpaperWindow.animationsEnabled = true;
            });
        } else {
            wallpapersListInst.contentX = targetX;
        }
        wallpapersListInst.forceActiveFocus();
    }

    property var wallpaperFetcher: Process {
        id: wallpaperFetcher
        command: [Quickshell.env("HOME") + "/.config/qs/c_tools/bin/fast_wallpapers", wallpaperWindow.wallpapersDir]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var list = [];
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim();
                    if (path !== "") list.push({ path: path, name: path.substring(path.lastIndexOf("/") + 1) });
                }
                wallpaperWindow.wallpapersList = list;
                Qt.callLater(() => {
                    selectCurrentWallpaper(false);
                });
            }
        }
    }



    property var wallpaperSetter: Process {
        id: wallpaperSetter
        property bool shouldClose: false

        function applyWallpaper(filePath, closeWindow) {
            shouldClose = (closeWindow === true);
            if (shouldClose) {
                wallpaperWindow.active = false;
            }
            if (typeof root !== "undefined" && root && typeof root.setWallpaper === "function") {
                root.setWallpaper(filePath);
            }
            var awwwArgs = "-t none";
            if (shouldClose) {
                var transitions = ["wave", "wipe", "grow", "center", "outer", "any", "left", "right", "top", "bottom", "fade"];
                var chosen = transitions[Math.floor(Math.random() * transitions.length)];
                var angle = Math.floor(Math.random() * 360);
                awwwArgs = "--transition-type " + chosen + " --transition-angle " + angle + " --transition-duration 1.5 --transition-fps 144 --transition-bezier .54,0,.34,.99";
            }
            var qsDir = wallpaperWindow.quickshellDir;
            command = ["sh", "-c", "awww img \"" + filePath + "\" " + awwwArgs + " && echo \"" + filePath + "\" > \"" + qsDir + "/current_wallpaper\" && matugen image \"" + filePath + "\" --source-color-index 0 -t scheme-content -m dark"];
            running = false;
            running = true;
        }
        onExited: {
            if (typeof rootTheme !== "undefined" && rootTheme && typeof rootTheme.reloadColors === "function") {
                rootTheme.reloadColors();
            } else if (wallpaperWindow.theme && typeof wallpaperWindow.theme.reloadColors === "function") {
                wallpaperWindow.theme.reloadColors();
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: wallpaperWindow.active
        onActivated: wallpaperWindow.active = false
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        readonly property color themeSurface: (wallpaperWindow && wallpaperWindow.theme) ? wallpaperWindow.theme.getColor("surface") : "#1b1b1b"

        ListView {
            id: wallpapersListInst
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: 32
            clip: true
            model: wallpaperWindow.wallpapersList
            focus: true
            cacheBuffer: 1200
            boundsBehavior: Flickable.StopAtBounds
            highlightRangeMode: ListView.NoHighlightRange
            highlightFollowsCurrentItem: false

            Behavior on contentX {
                enabled: wallpaperWindow.animationsEnabled
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            WheelHandler {
                orientation: Qt.Horizontal
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    var step = (event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x) / 120 * 120;
                    var maxScroll = wallpapersListInst.contentWidth - wallpapersListInst.width;
                    wallpapersListInst.contentX = Math.max(0, Math.min(maxScroll, wallpapersListInst.contentX - step));
                }
            }

            delegate: WallpaperCard {
                wallpaperWindow: wallpaperWindow
                wallpapersListInst: wallpapersListInst
            }

            Keys.onLeftPressed: {
                if (currentIndex > 0) {
                    currentIndex--;
                    wallpapersListInst.contentX = getScrollTarget(currentIndex);
                }
            }
            Keys.onRightPressed: {
                if (currentIndex < count - 1) {
                    currentIndex++;
                    wallpapersListInst.contentX = getScrollTarget(currentIndex);
                }
            }
            Keys.onReturnPressed: {
                var wp = model[currentIndex];
                if (wp) {
                    wallpaperWindow.wallpaperSetter.applyWallpaper(wp.path, true);
                }
            }
            Keys.onEnterPressed: {
                var wp = model[currentIndex];
                if (wp) {
                    wallpaperWindow.wallpaperSetter.applyWallpaper(wp.path, true);
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 180
            z: 10
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: (wallpaperWindow && wallpaperWindow.theme) ? wallpaperWindow.theme.getColor("surface") : "#1b1b1b" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 180
            z: 10
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: (wallpaperWindow && wallpaperWindow.theme) ? wallpaperWindow.theme.getColor("surface") : "#1b1b1b" }
            }
        }
    }
}
