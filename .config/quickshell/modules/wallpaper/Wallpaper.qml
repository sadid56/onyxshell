import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: wallpaperRoot

    property string currentWallpaperPath: ""

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
            }
        }
    }

    Component.onCompleted: {
        var fileText = (typeof currentWallpaperFile.text === "function") ? currentWallpaperFile.text() : currentWallpaperFile.text;
        if (fileText && fileText.trim().length > 0) {
            wallpaperRoot.currentWallpaperPath = fileText.trim();
        } else if (typeof shellConfig !== "undefined" && shellConfig) {
            wallpaperRoot.currentWallpaperPath = shellConfig.defaultWallpaper;
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
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "black"

            function formatSource(p) {
                if (!p || p === "") return "";
                if (p.startsWith("file://")) return p;
                if (p.startsWith("/")) return "file://" + p;
                return p;
            }

            function applyWallpaper(newPath) {
                var src = formatSource(newPath);
                if (!src || src === "") return;

                if (currentImg.source.toString() === "") {
                    currentImg.source = src;
                    currentImg.opacity = 1;
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
                wallpaperWindow.applyWallpaper(wallpaperRoot.currentWallpaperPath);
            }

            Image {
                id: currentImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: 1
            }

            Image {
                id: nextImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
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
