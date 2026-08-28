import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: wallpaperRoot

    property string currentWallpaperPath: ""
    property bool isSplashActive: (typeof root !== "undefined" && root.splashScreen && !root.splashScreen.isFadingOut && !root.splashScreen.isFinished)

    function setWallpaper(filePath) {
        if (filePath && filePath !== "") {
            wallpaperRoot.currentWallpaperPath = filePath;
        }
    }

    FileView {
        id: currentWallpaperFile
        path: (typeof shellConfig !== "undefined" && shellConfig) ? (shellConfig.quickshellDir + "/current_wallpaper") : ""
        watchChanges: true
        onTextChanged: {
            var fileText = (typeof currentWallpaperFile.text === "function") ? currentWallpaperFile.text() : currentWallpaperFile.text;
            if (fileText && fileText.trim().length > 0) {
                wallpaperRoot.currentWallpaperPath = fileText.trim();
            } else if (!wallpaperRoot.currentWallpaperPath && typeof shellConfig !== "undefined" && shellConfig) {
                wallpaperRoot.currentWallpaperPath = shellConfig.defaultWallpaper;
            }
        }
    }

    Component.onCompleted: {
        var fileText = (typeof currentWallpaperFile.text === "function") ? currentWallpaperFile.text() : currentWallpaperFile.text;
        if (fileText && fileText.trim().length > 0) {
            wallpaperRoot.currentWallpaperPath = fileText.trim();
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: wallpaperWindow
            property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: 0
            color: "#1b1111"

            visible: !wallpaperRoot.isSplashActive

            property bool isInitialLoad: true

            function formatSource(p) {
                if (!p || p === "") return "";
                if (p.startsWith("file://")) return p;
                if (p.startsWith("/")) return "file://" + p;
                return p;
            }

            function applyWallpaper(newPath) {
                var src = formatSource(newPath);
                if (!src || src === "") return;

                if (isInitialLoad || currentImg.source.toString() === "") {
                    currentImg.source = src;
                    currentImg.opacity = 1;
                    isInitialLoad = false;
                    return;
                }

                if (currentImg.source.toString() === src) {
                    return;
                }

                fadeAnim.stop();
                nextImg.opacity = 0;
                nextImg.source = src;

                if (nextImg.status === Image.Ready) {
                    fadeAnim.start();
                }
            }

            Connections {
                target: wallpaperRoot
                function onCurrentWallpaperPathChanged() {
                    wallpaperWindow.applyWallpaper(wallpaperRoot.currentWallpaperPath);
                }
            }

            Component.onCompleted: {
                if (wallpaperRoot.currentWallpaperPath !== "") {
                    wallpaperWindow.applyWallpaper(wallpaperRoot.currentWallpaperPath);
                }
            }

            Image {
                id: currentImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
                cache: true
                sourceSize: Qt.size(wallpaperWindow.width > 0 ? wallpaperWindow.width : 1920, wallpaperWindow.height > 0 ? wallpaperWindow.height : 1080)
                opacity: 1
            }

            Image {
                id: nextImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize: Qt.size(wallpaperWindow.width > 0 ? wallpaperWindow.width : 1920, wallpaperWindow.height > 0 ? wallpaperWindow.height : 1080)
                opacity: 0

                onStatusChanged: {
                    if (status === Image.Ready && source.toString() !== "" && !fadeAnim.running && opacity < 1) {
                        fadeAnim.start();
                    } else if (status === Image.Error) {
                        currentImg.source = source;
                        currentImg.opacity = 1;
                        opacity = 0;
                        source = "";
                    }
                }
            }

            NumberAnimation {
                id: fadeAnim
                target: nextImg
                property: "opacity"
                from: 0
                to: 1
                duration: 320
                easing.type: Easing.OutCubic
                onFinished: {
                    currentImg.source = nextImg.source;
                    currentImg.opacity = 1;
                    nextImg.opacity = 0;
                    nextImg.source = "";
                }
            }
        }
    }
}
