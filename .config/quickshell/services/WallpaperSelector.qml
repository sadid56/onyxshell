import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../components/containers"

Popup {
    id: wallpaperWindow
    
    popupWidth: Screen.width * 0.8
    popupHeight: 240
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
        var targetX = index * (280 + 28) - (wallpapersListInst.width - 280) / 2;
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
        command: ["find", root.shellConfig.homeDir + "/Pictures/Images", "-maxdepth", "2", "-type", "f", "-and", "(", "-name", "*.jpg", "-o", "-name", "*.png", "-o", "-name", "*.jpeg", "-o", "-name", "*.gif", ")"]
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

            command = ["sh", "-c", "echo \"" + filePath + "\" > " + root.shellConfig.quickshellDir + "/current_wallpaper && awww img \"" + filePath + "\" --transition-type " + type + " --transition-step 90 --transition-fps 60 && matugen image \"" + filePath + "\" --source-color-index 0 -m dark"];
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
        duration: 380
        easing.type: Easing.OutCubic
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        readonly property color themeSurface: wallpaperWindow.theme.getColor("surface")

        ListView {
            id: wallpapersListInst
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: 28
            clip: true
            model: wallpaperWindow.wallpapersList
            focus: true

            highlightRangeMode: ListView.NoHighlightRange
            highlightFollowsCurrentItem: false

            delegate: Item {
                id: delegateRoot
                width: 280
                height: 190

                property bool isCurrent: ListView.isCurrentItem

                Item {
                    id: cardContainer
                    width: 280
                    height: 158
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    scale: delegateRoot.isCurrent ? 1.12 : (hoverArea.containsMouse ? 1.03 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    Item {
                        id: contentContainer
                        width: 280
                        height: 158

                        Image {
                            id: imgSource
                            anchors.fill: parent
                            source: "file://" + modelData.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width: 280
                            sourceSize.height: 158

                            onStatusChanged: {
                                if (status === Image.Ready) {
                                    Qt.callLater(() => {
                                        contentSource.scheduleUpdate();
                                    });
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: maskRect
                        width: 280
                        height: 158
                        radius: 16
                    }

                    ShaderEffectSource {
                        id: contentSource
                        sourceItem: contentContainer
                        hideSource: true
                        live: true
                    }

                    ShaderEffectSource {
                        id: maskSourceItem
                        sourceItem: maskRect
                        hideSource: true
                        live: true
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: contentSource
                        maskEnabled: true
                        maskSource: maskSourceItem
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
            width: 200
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
            width: 200
            z: 10
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: wallpaperWindow.theme.getColor("surface") }
            }
        }
    }
}
