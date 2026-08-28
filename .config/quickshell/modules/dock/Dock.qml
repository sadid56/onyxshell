import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "./components"
import "../bar/widgets"
import "../../components/ui" as UI

PanelWindow {
    id: dockWindow

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 270
    color: "transparent"
    mask: Region { item: dockContainer }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0

    property var theme: (typeof root !== "undefined" && root && root.rootTheme) ? root.rootTheme : null
    property var settingsService: (typeof root !== "undefined" && root && root.settingsService) ? root.settingsService : null
    property var popupManager: (typeof root !== "undefined" && root && root.popupManager) ? root.popupManager : null
    property int dockCornerRadius: (typeof root !== "undefined" && root && root.settingsService && root.settingsService.cornerRadius !== undefined) ? root.settingsService.cornerRadius : ((typeof root !== "undefined" && root && root.shellConfig) ? root.shellConfig.cornerRadius : 16)

    readonly property bool livePreviewEnabled: (settingsService && settingsService.dockLivePreview !== undefined) ? settingsService.dockLivePreview : true
    readonly property bool autoShowEmptyEnabled: (settingsService && settingsService.dockAutoShowEmpty !== undefined) ? settingsService.dockAutoShowEmpty : true
    readonly property int dockItemSize: (settingsService && settingsService.dockIconSize !== undefined) ? (settingsService.dockIconSize + 16) : 44
    readonly property int dockPillHeight: dockItemSize + 16
    readonly property int dockSpacing: (settingsService && settingsService.dockSpacing !== undefined) ? settingsService.dockSpacing : 6

    property bool isDockHovered: false
    property bool isDismissed: false
    property int hoveredIndex: -1
    property int activePreviewIndex: -1

    readonly property var displayApps: tracker.displayApps
    readonly property string focusedClass: tracker.focusedClass
    readonly property bool currentWorkspaceHasWindows: tracker.currentWorkspaceHasWindows

    readonly property bool shouldShowDock: !isDismissed && (isDockHovered || (autoShowEmptyEnabled && !currentWorkspaceHasWindows && displayApps.length > 0))

    DockWindowTracker {
        id: tracker
        dockWindow: dockWindow
    }

    onHoveredIndexChanged: {
        if (hoveredIndex >= 0) {
            previewHideTimer.stop();
            activePreviewIndex = hoveredIndex;
        } else {
            previewHideTimer.restart();
        }
    }

    Timer {
        id: previewHideTimer
        interval: 220
        repeat: false
        onTriggered: dockWindow.activePreviewIndex = -1
    }

    Timer {
        id: hideDelayTimer
        interval: 400
        repeat: false
        onTriggered: {
            dockWindow.isDockHovered = false;
            dockWindow.hoveredIndex = -1;
            dockWindow.activePreviewIndex = -1;
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(name, data) {
            if (name === "openwindow" || name === "closewindow" || name === "workspace") {
                dockWindow.isDismissed = false;
            }
        }
    }

    function handleAppClick(app) {
        if (!app) return;
        dockWindow.isDismissed = true;
        dockWindow.isDockHovered = false;
        dockWindow.hoveredIndex = -1;
        dockWindow.activePreviewIndex = -1;
        if (app.address && app.address !== "") {
            var scriptPath = (typeof shellConfig !== "undefined" && shellConfig)
                ? shellConfig.getScript("focus_app.sh")
                : (Quickshell.env("HOME") + "/.config/quickshell/scripts/focus_app.sh");
            Quickshell.execDetached([scriptPath, app.className || "", app.name || "", ""]);
        } else if (app.exec && app.exec !== "") {
            var cmd = app.exec.replace(/%[a-zA-Z]/g, "").trim();
            var cliTools = ["nvim", "vim", "htop", "btop", "yazi", "ranger", "fastfetch"];
            var baseName = cmd.split(/\s/)[0].split("/").pop().toLowerCase();
            if (cliTools.indexOf(baseName) !== -1 && !cmd.startsWith("kitty") && !cmd.startsWith("alacritty") && !cmd.startsWith("foot") && !cmd.startsWith("wezterm") && !cmd.startsWith("ghostty")) {
                var term = (typeof Quickshell !== "undefined" && Quickshell.env("TERMINAL")) ? Quickshell.env("TERMINAL") : "kitty";
                cmd = term + " -e " + cmd;
            }
            Quickshell.execDetached(["bash", "-c", "nohup " + cmd + " >/dev/null 2>&1 &"]);
        }
        tracker.refreshClients();
    }

    function updateHoveredIndex(mouseX, mouseY) {
        if (!dockRowRepeater || dockRowRepeater.count === 0) {
            hoveredIndex = -1;
            return;
        }
        var pos = masterMouseArea.mapToItem(dockRow, mouseX, mouseY);
        if (pos.y < -6 || pos.y > dockRow.height + 6) {
            hoveredIndex = -1;
            return;
        }
        var halfSpacing = (dockRow.spacing > 0) ? (dockRow.spacing / 2) : 3;
        for (var i = 0; i < dockRowRepeater.count; i++) {
            var child = dockRowRepeater.itemAt(i);
            if (child) {
                var childLeft = child.x - halfSpacing;
                var childRight = child.x + child.width + halfSpacing;
                if (pos.x >= childLeft && pos.x < childRight) {
                    hoveredIndex = i;
                    return;
                }
            }
        }
        if (pos.x < 0) hoveredIndex = 0;
        else if (pos.x >= dockRow.width) hoveredIndex = dockRowRepeater.count - 1;
    }

    Item {
        id: dockContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: Math.max(340, dockRow.implicitWidth + 16 + (dockWindow.dockCornerRadius * 2) + 32)
        height: dockWindow.shouldShowDock ? (dockWindow.dockPillHeight + 4) : 10

        MouseArea {
            id: masterMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: (hoveredIndex >= 0 && isDockHovered && !isDismissed) ? Qt.PointingHandCursor : Qt.ArrowCursor
            onEntered: {
                hideDelayTimer.stop();
                dockWindow.isDismissed = false;
                dockWindow.isDockHovered = true;
                tracker.refreshClients();
            }
            onExited: {
                dockWindow.isDismissed = false;
                hideDelayTimer.restart();
            }
            onPositionChanged: function(mouse) {
                if (!dockWindow.isDismissed) {
                    dockWindow.updateHoveredIndex(mouse.x, mouse.y);
                }
            }
            onClicked: function(mouse) {
                if (hoveredIndex >= 0 && hoveredIndex < displayApps.length) {
                    handleAppClick(displayApps[hoveredIndex]);
                }
            }
        }

        Corner {
            anchors.bottom: dockPill.bottom
            anchors.right: dockPill.left
            anchors.rightMargin: -0.5
            alignRight: true
            alignBottom: true
            color: dockPill.color
            cornerRadius: dockWindow.dockCornerRadius
            visible: dockPill.visible && dockPill.opacity > 0.05
            opacity: dockPill.opacity
            scale: dockPill.scale
            transformOrigin: Item.BottomRight
        }

        Rectangle {
            id: dockPill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: dockWindow.shouldShowDock ? 0 : -dockPill.height
            width: dockRow.implicitWidth > 0 ? (dockRow.implicitWidth + 16) : 60
            height: dockWindow.dockPillHeight
            topLeftRadius: dockWindow.dockCornerRadius
            topRightRadius: dockWindow.dockCornerRadius
            color: dockWindow.theme ? dockWindow.theme.getColor("surface") : "#131314"
            visible: dockWindow.displayApps.length > 0
            opacity: dockWindow.shouldShowDock ? 1.0 : 0.0
            scale: dockWindow.shouldShowDock ? 1.0 : 0.90
            transformOrigin: Item.Bottom

            Behavior on anchors.bottomMargin { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            layer.enabled: dockWindow.shouldShowDock
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#50000000"
                shadowBlur: 0.6
                shadowVerticalOffset: -4
            }

            Item {
                id: dockRowContainer
                anchors.centerIn: parent
                width: dockRow.implicitWidth
                height: dockWindow.dockItemSize

                Rectangle {
                    id: activeHoverPill
                    z: 0
                    width: dockWindow.dockItemSize
                    height: dockWindow.dockItemSize
                    radius: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: dockWindow.theme ? Qt.alpha(dockWindow.theme.getColor("primaryContainer"), 0.65) : "#434453A6"
                    x: {
                        if (dockWindow.activePreviewIndex < 0 || dockRowRepeater.count === 0) return 0;
                        var child = dockRowRepeater.itemAt(dockWindow.activePreviewIndex);
                        return child ? child.x : 0;
                    }
                    opacity: (dockWindow.activePreviewIndex >= 0 && dockWindow.isDockHovered) ? 1.0 : 0.0
                    scale: (dockWindow.activePreviewIndex >= 0 && dockWindow.isDockHovered) ? 1.0 : 0.85

                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                Row {
                    id: dockRow
                    anchors.fill: parent
                    spacing: dockWindow.dockSpacing
                    z: 1

                    Repeater {
                        id: dockRowRepeater
                        model: dockWindow.displayApps
                        delegate: DockItem {
                            theme: dockWindow.theme
                            itemData: ({
                                name: modelData.name || "",
                                icon: modelData.icon || "",
                                windowCount: modelData.windowCount || 0
                            })
                            isRunning: Boolean(modelData.isRunning)
                            isFocused: Boolean(modelData.isRunning && modelData.isFocused)
                            isHovered: dockWindow.activePreviewIndex === index
                        }
                    }
                }
            }
        }

        Corner {
            anchors.bottom: dockPill.bottom
            anchors.left: dockPill.right
            anchors.leftMargin: -0.5
            alignRight: false
            alignBottom: true
            color: dockPill.color
            cornerRadius: dockWindow.dockCornerRadius
            visible: dockPill.visible && dockPill.opacity > 0.05
            opacity: dockPill.opacity
            scale: dockPill.scale
            transformOrigin: Item.BottomLeft
        }

        DockLivePreviewCard {
            dockWindow: dockWindow
            dockPill: dockPill
            dockRowContainer: dockRowContainer
            dockRowRepeater: dockRowRepeater
        }
    }
}
