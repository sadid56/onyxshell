import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "./applauncher"

PanelWindow {
    id: wallpaperWindow
    
    // Spans the entire screen to capture clicks outside
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    // Theme passed from root
    property var theme
    property bool active: false
    property var wallpapersList: []
    property string searchQuery: ""

    // Dynamic Filtered List
    property var filteredWallpapersList: {
        if (searchQuery === "") return wallpapersList;
        var arr = [];
        var query = searchQuery.toLowerCase();
        for (var i = 0; i < wallpapersList.length; i++) {
            var wp = wallpapersList[i];
            if (wp.name.toLowerCase().indexOf(query) !== -1) {
                arr.push(wp);
            }
        }
        return arr;
    }

    visible: active || contentRect.opacity > 0.0

    onActiveChanged: {
        if (active) {
            refreshWallpapers();
            searchBar.forceFocus();
        } else {
            searchBar.text = "";
            searchQuery = "";
        }
    }

    function refreshWallpapers() {
        wallpaperFetcher.running = false;
        wallpaperFetcher.running = true;
    }

    property var wallpaperFetcher: Process {
        id: wallpaperFetcher
        command: ["find", "/home/sadid/Pictures/Images", "-type", "f", "-name", "*.jpg", "-o", "-name", "*.png", "-o", "-name", "*.jpeg", "-o", "-name", "*.gif"]
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

            command = ["sh", "-c", "echo \"" + filePath + "\" > /home/sadid/.config/quickshell/current_wallpaper && awww img \"" + filePath + "\" --transition-type " + type + " --transition-step 90 --transition-fps 60"];
            running = false;
            running = true;
        }
        onExited: {
            wallpaperWindow.active = false;
        }
    }

    // Escape shortcut to close
    Shortcut {
        sequence: "Escape"
        enabled: wallpaperWindow.active
        onActivated: wallpaperWindow.active = false
    }

    // Capture clicks outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: wallpaperWindow.active = false
    }

    Rectangle {
        id: contentRect
        x: (parent.width - width) / 2
        y: wallpaperWindow.active ? (parent.height - height) / 2 : (parent.height - height) / 2 - 10
        
        width: 960
        height: 600
        radius: 20
        color: wallpaperWindow.theme.getColor("surface")
        border.width: 0

        // Prevent click through
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        opacity: wallpaperWindow.active ? 1.0 : 0.0
        scale: wallpaperWindow.active ? 1.0 : 0.97
        
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        
        transform: Translate {
            y: wallpaperWindow.active ? 0 : -10
            Behavior on y {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Header Section
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Select Wallpaper"
                    font.family: "Noto Sans"
                    font.pixelSize: 20
                    font.bold: true
                    color: wallpaperWindow.theme.getColor("onSurface")
                    Layout.fillWidth: true
                }

                // Close Button
                Text {
                    text: "󰅖"
                    font.family: "Noto Sans"
                    font.pixelSize: 20
                    color: wallpaperWindow.theme.getColor("primary")
                    font.bold: true
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wallpaperWindow.active = false
                    }
                }
            }

            // Material Styled Search Bar
            SearchBar {
                id: searchBar
                theme: wallpaperWindow.theme
                Layout.fillWidth: true
                onTextChanged: wallpaperWindow.searchQuery = text
                onEscapePressed: wallpaperWindow.active = false
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: wallpaperWindow.theme.getColor("surfaceVariant")
            }

            // Grid View of Wallpapers
            GridView {
                id: wallpapersGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: wallpaperWindow.filteredWallpapersList
                topMargin: 15
                cellWidth: wallpapersGrid.width / 4
                cellHeight: 140

                delegate: Item {
                    id: delegateRoot
                    width: wallpapersGrid.cellWidth
                    height: 140

                    Item {
                        id: cardContainer
                        width: parent.width - 16
                        height: 120
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            clip: true
                            color: "transparent"

                            Image {
                                id: imgSource
                                anchors.fill: parent
                                source: "file://" + modelData.path
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            // Add border on hover
                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: "transparent"
                                border.width: hoverArea.containsMouse ? 2 : 0
                                border.color: wallpaperWindow.theme.getColor("primary")
                                
                                Behavior on border.width { NumberAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wallpaperWindow.wallpaperSetter.applyWallpaper(modelData.path);
                            }
                        }

                        // Hover Zoom scale
                        scale: hoverArea.containsMouse ? 1.03 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }
}
