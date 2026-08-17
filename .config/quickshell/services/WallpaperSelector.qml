import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import "../components/containers"

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

    onActiveChanged: {
        if (active) {
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
        var targetX = index * cardTotalWidth - (wallpapersListInst.width - 280) / 2;
        var maxScroll = wallpapersListInst.contentWidth - wallpapersListInst.width;
        if (maxScroll > 0) {
            return Math.max(0, Math.min(targetX, maxScroll));
        }
        return 0;
    }

    function selectCurrentWallpaper() {
        if (!wallpapersList || wallpapersList.length === 0) return;

        var currentPath = "";
        var fileText = (typeof currentWallpaperFile.text === "function") ? currentWallpaperFile.text() : currentWallpaperFile.text;
        if (fileText) {
            currentPath = fileText.trim();
        }

        var indexToSelect = 0;
        for (var i = 0; i < wallpapersList.length; i++) {
            if (wallpapersList[i].path === currentPath) {
                indexToSelect = i;
                break;
            }
        }

        wallpapersListInst.currentIndex = indexToSelect;
        wallpapersListInst.contentX = getScrollTarget(indexToSelect);
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
                    if (path !== "") {
                        list.push({ path: path, name: path.substring(path.lastIndexOf("/") + 1) });
                    }
                }
                wallpaperWindow.wallpapersList = list;

                Qt.callLater(() => {
                    selectCurrentWallpaper();
                });
            }
        }
    }

    property var wallpaperSetter: Process {
        id: wallpaperSetter
        function applyWallpaper(filePath) {
            var hour = new Date().getHours();
            var type = "wipe";
            if (hour < 12) type = "grow";
            else if (hour < 18) type = "wipe";
            else type = "outer";

            command = ["sh", "-c", "echo \"" + filePath + "\" > " + root.shellConfig.quickshellDir + "/current_wallpaper && awww img \"" + filePath + "\" --transition-type " + type + " --transition-step 90 --transition-fps 60 && matugen image \"" + filePath + "\" --source-color-index 0 -t scheme-content -m dark"];
            running = false;
            running = true;
        }
        onExited: {
            wallpaperWindow.active = false;
            rootTheme.reloadColors();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: wallpaperWindow.active
        onActivated: wallpaperWindow.active = false
    }

    NumberAnimation {
        id: scrollAnimation
        target: wallpapersListInst
        property: "contentX"
        duration: 320
        easing.type: Easing.OutExpo
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        readonly property color themeSurface: wallpaperWindow.theme.getColor("surface")

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

            WheelHandler {
                orientation: Qt.Horizontal
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    var step = (event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x) / 120 * 120;
                    var maxScroll = wallpapersListInst.contentWidth - wallpapersListInst.width;
                    var nextX = Math.max(0, Math.min(maxScroll, wallpapersListInst.contentX - step));
                    scrollAnimation.to = nextX;
                    scrollAnimation.start();
                }
            }

            delegate: Item {
                id: delegateRoot
                width: 280
                height: 200

                property bool isCurrent: ListView.isCurrentItem

                ClippingRectangle {
                    id: cardContainer
                    width: 280
                    height: 158
                    radius: 18
                    color: wallpaperWindow.theme ? wallpaperWindow.theme.getColor("surfaceVariant") : "#2b2a27"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    scale: delegateRoot.isCurrent ? 1.10 : (hoverArea.containsMouse ? 1.03 : 0.96)
                    opacity: delegateRoot.isCurrent ? 1.0 : (hoverArea.containsMouse ? 0.90 : 0.65)

                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutExpo } }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                    Image {
                        id: imgSource
                        anchors.fill: parent
                        source: "file://" + modelData.path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 320
                        sourceSize.height: 180
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: "transparent"
                        border.color: delegateRoot.isCurrent ?
                                      (wallpaperWindow.theme ? wallpaperWindow.theme.getColor("primary") : "#ffb3b4") :
                                      "transparent"
                        border.width: delegateRoot.isCurrent ? 2.5 : 0

                        Behavior on border.color { ColorAnimation { duration: 160 } }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wallpapersListInst.currentIndex = index;
                            scrollAnimation.to = getScrollTarget(index);
                            scrollAnimation.start();
                            wallpaperWindow.wallpaperSetter.applyWallpaper(modelData.path);
                        }
                    }
                }
            }

            Keys.onLeftPressed: {
                if (currentIndex > 0) {
                    currentIndex--;
                    scrollAnimation.to = getScrollTarget(currentIndex);
                    scrollAnimation.start();
                }
            }
            Keys.onRightPressed: {
                if (currentIndex < count - 1) {
                    currentIndex++;
                    scrollAnimation.to = getScrollTarget(currentIndex);
                    scrollAnimation.start();
                }
            }
            Keys.onReturnPressed: {
                var wp = model[currentIndex];
                if (wp) {
                    wallpaperWindow.wallpaperSetter.applyWallpaper(wp.path);
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
                GradientStop { position: 0.0; color: wallpaperWindow.theme.getColor("surface") }
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
                GradientStop { position: 1.0; color: wallpaperWindow.theme.getColor("surface") }
            }
        }
    }
}
