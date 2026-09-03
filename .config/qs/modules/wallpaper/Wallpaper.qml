import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: wallpaperRoot

    property string currentWallpaperPath: ""
    property string lastAppliedSource: ""

    function formatSource(p) {
        if (!p || p === "") return "";
        if (p.startsWith("file://")) return p;
        if (p.startsWith("/")) return "file://" + p;
        return p;
    }

    function setWallpaper(filePath) {
        if (filePath && filePath !== "") {
            var formatted = formatSource(filePath);
            if (formatted !== wallpaperRoot.lastAppliedSource) {
                wallpaperRoot.lastAppliedSource = formatted;
                wallpaperRoot.currentWallpaperPath = filePath;
            }
        }
    }

    FileView {
        id: currentWallpaperFile
        path: (typeof shellConfig !== "undefined" && shellConfig) ? (shellConfig.quickshellDir + "/current_wallpaper") : ""
        watchChanges: true
        onTextChanged: {
            var fileText = (typeof currentWallpaperFile.text === "function") ? currentWallpaperFile.text() : currentWallpaperFile.text;
            if (fileText && fileText.trim().length > 0) {
                var cleanPath = fileText.trim();
                var formatted = wallpaperRoot.formatSource(cleanPath);
                if (formatted !== wallpaperRoot.lastAppliedSource) {
                    wallpaperRoot.lastAppliedSource = formatted;
                    wallpaperRoot.currentWallpaperPath = cleanPath;
                }
            }
        }
    }

    Component.onCompleted: {
        var fileText = (typeof currentWallpaperFile.text === "function") ? currentWallpaperFile.text() : currentWallpaperFile.text;
        if (fileText && fileText.trim().length > 0) {
            var cleanPath = fileText.trim();
            wallpaperRoot.lastAppliedSource = wallpaperRoot.formatSource(cleanPath);
            wallpaperRoot.currentWallpaperPath = cleanPath;
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
            visible: true

            property bool isInitialLoad: true
            property bool showingB: false
            property string currentTargetSource: ""

            function applyWallpaper(newPath) {
                var src = wallpaperRoot.formatSource(newPath);
                if (!src || src === "") return;

                if (currentTargetSource === src) return;
                currentTargetSource = src;

                if (isInitialLoad || (imgA.source.toString() === "" && imgB.source.toString() === "")) {
                    fadeAnimA.stop();
                    fadeAnimB.stop();
                    imgA.source = src;
                    imgA.opacity = 1.0;
                    imgA.z = 1;
                    imgB.opacity = 0.0;
                    imgB.z = 0;
                    showingB = false;
                    isInitialLoad = false;
                    return;
                }

                if (showingB) {
                    // Currently showing B -> load into A, fade in A, then hide B
                    fadeAnimA.stop();
                    fadeAnimB.stop();
                    imgA.opacity = 0.0;
                    imgA.z = 2;
                    imgB.z = 1;
                    imgA.source = src;
                    if (imgA.status === Image.Ready) {
                        fadeAnimA.start();
                    }
                } else {
                    // Currently showing A -> load into B, fade in B, then hide A
                    fadeAnimA.stop();
                    fadeAnimB.stop();
                    imgB.opacity = 0.0;
                    imgB.z = 2;
                    imgA.z = 1;
                    imgB.source = src;
                    if (imgB.status === Image.Ready) {
                        fadeAnimB.start();
                    }
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
                id: imgA
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                mipmap: false
                cache: true
                sourceSize: Qt.size(wallpaperWindow.width > 0 ? wallpaperWindow.width : 1920, wallpaperWindow.height > 0 ? wallpaperWindow.height : 1080)
                opacity: 1.0
                z: 1

                onStatusChanged: {
                    if (status === Image.Ready && source.toString() === wallpaperWindow.currentTargetSource && showingB && !fadeAnimA.running) {
                        fadeAnimA.start();
                    }
                }
            }

            Image {
                id: imgB
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                mipmap: false
                cache: true
                sourceSize: Qt.size(wallpaperWindow.width > 0 ? wallpaperWindow.width : 1920, wallpaperWindow.height > 0 ? wallpaperWindow.height : 1080)
                opacity: 0.0
                z: 0

                onStatusChanged: {
                    if (status === Image.Ready && source.toString() === wallpaperWindow.currentTargetSource && !showingB && !fadeAnimB.running) {
                        fadeAnimB.start();
                    }
                }
            }

            NumberAnimation {
                id: fadeAnimA
                target: imgA
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 320
                easing.type: Easing.OutCubic
                onFinished: {
                    wallpaperWindow.showingB = false;
                    imgB.opacity = 0.0;
                    imgB.source = "";
                }
            }

            NumberAnimation {
                id: fadeAnimB
                target: imgB
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 320
                easing.type: Easing.OutCubic
                onFinished: {
                    wallpaperWindow.showingB = true;
                    imgA.opacity = 0.0;
                    imgA.source = "";
                }
            }
        }
    }
}
