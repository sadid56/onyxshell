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

    property var wallpapersList: []

    FileView {
        id: currentWallpaperFile
        path: root.shellConfig.quickshellDir + "/current_wallpaper"
    }

    Component.onCompleted: {
        refreshWallpapers();
    }

    onActiveChanged: {
        if (active) {
            selectCurrentWallpaper();
            refreshWallpapers();
            Qt.callLater(() => {
                selectCurrentWallpaper();
                wallpapersListInst.forceActiveFocus();
            });
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
        var targetX = index * cardTotalWidth - (wallpapersListInst.width - 280) / 2;
        var maxScroll = totalW - wallpapersListInst.width;
        return maxScroll > 0 ? Math.max(0, Math.min(targetX, maxScroll)) : 0;
    }

    function selectCurrentWallpaper() {
        if (!wallpapersList || wallpapersList.length === 0) return;
        var currentPath = "";
        if (typeof wallpaperBackground !== "undefined" && wallpaperBackground && wallpaperBackground.currentWallpaperPath) {
            currentPath = wallpaperBackground.currentWallpaperPath;
        } else {
            var fileText = (typeof currentWallpaperFile.text === "function") ? currentWallpaperFile.text() : currentWallpaperFile.text;
            if (fileText) currentPath = fileText.trim();
        }

        var indexToSelect = 0;
        for (var i = 0; i < wallpapersList.length; i++) {
            if (wallpapersList[i].path === currentPath) {
                indexToSelect = i;
                break;
            }
        }
        wallpapersListInst.currentIndex = indexToSelect;
        var targetX = getScrollTarget(indexToSelect);
        wallpapersListInst.contentX = targetX;
        wallpapersListInst.forceActiveFocus();
    }

    property var wallpaperFetcher: Process {
        id: wallpaperFetcher
        command: ["find", root.shellConfig.homeDir + "/Pictures/wallpapers", "-maxdepth", "2", "-type", "f", "-and", "(", "-name", "*.jpg", "-o", "-name", "*.png", "-o", "-name", "*.jpeg", "-o", "-name", "*.gif", ")"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var list = [];
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim();
                    if (path !== "") list.push({ path: path, name: path.substring(path.lastIndexOf("/") + 1) });
                }
                wallpaperWindow.wallpapersList = list;
                Qt.callLater(selectCurrentWallpaper);
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
            command = ["sh", "-c", "awww img \"" + filePath + "\" " + awwwArgs + " && echo \"" + filePath + "\" > " + root.shellConfig.quickshellDir + "/current_wallpaper && matugen image \"" + filePath + "\" --source-color-index 0 -t scheme-content -m dark"];
            running = false;
            running = true;
        }
        onExited: {
            rootTheme.reloadColors();
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
            boundsBehavior: Flickable.StopAtBounds
            highlightRangeMode: ListView.NoHighlightRange
            highlightFollowsCurrentItem: false

            Behavior on contentX {
                NumberAnimation {
                    duration: 480
                    easing.type: Easing.OutQuint
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
