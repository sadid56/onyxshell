import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

Rectangle {
    id: previewCard

    property var dockWindow
    property var dockPill
    property var dockRowContainer
    property var dockRowRepeater

    visible: dockWindow && dockWindow.livePreviewEnabled && (opacity > 0.001)
    width: 240
    height: 156
    radius: 16
    color: dockWindow && dockWindow.theme ? dockWindow.theme.getColor("surface") : "#131314"
    border.width: 1
    border.color: dockWindow && dockWindow.theme ? Qt.alpha(dockWindow.theme.getColor("outlineVariant"), 0.4) : "#46464c66"
    clip: true
    z: 500

    x: {
        if (!dockWindow || dockWindow.activePreviewIndex < 0 || !dockRowRepeater || dockRowRepeater.count === 0)
            return (parent.width - width) / 2;

        var child = dockRowRepeater.itemAt(dockWindow.activePreviewIndex);
        if (!child)
            return (parent.width - width) / 2;

        var childCenter = dockPill.x + dockRowContainer.x + child.x + child.width / 2;
        var targetX = childCenter - width / 2;
        return Math.max(4, Math.min(targetX, parent.width - width - 4));
    }
    y: dockPill.y - height - 12

    opacity: (dockWindow && dockWindow.livePreviewEnabled && dockWindow.activePreviewIndex >= 0 && dockWindow.isDockHovered && dockWindow.activePreviewIndex < dockWindow.displayApps.length && dockWindow.displayApps[dockWindow.activePreviewIndex].isRunning) ? 1.0 : 0.0
    scale: (dockWindow && dockWindow.livePreviewEnabled && dockWindow.activePreviewIndex >= 0 && dockWindow.isDockHovered) ? 1.0 : 0.88
    transformOrigin: Item.Bottom

    Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    layer.enabled: visible
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#60000000"
        shadowBlur: 0.8
        shadowVerticalOffset: 8
    }

    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 6
        height: parent.height - previewTitleBar.height - 6
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: dockWindow && dockWindow.theme ? dockWindow.theme.getColor("surfaceVariant") : "#28292e"
            clip: true

            Repeater {
                model: dockWindow ? dockWindow.displayApps : []
                delegate: UI.WindowPreview {
                    anchors.fill: parent
                    addresses: modelData ? (modelData.addresses || []) : []
                    address: modelData ? (modelData.address || "") : ""
                    live: dockWindow && dockWindow.livePreviewEnabled && (index === dockWindow.activePreviewIndex) && dockWindow.isDockHovered && (modelData && modelData.isRunning)
                    visible: index === dockWindow.activePreviewIndex && (modelData && modelData.isRunning)
                    opacity: (index === dockWindow.activePreviewIndex && modelData && modelData.isRunning) ? 1.0 : 0.0
                    cornerRadius: 12
                    fallbackIcon: modelData ? (modelData.icon || modelData.className || "") : ""

                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
            }
        }
    }

    Item {
        id: previewTitleBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 30

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 6

            IconImage {
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                source: {
                    if (!dockWindow || dockWindow.activePreviewIndex < 0 || dockWindow.activePreviewIndex >= dockWindow.displayApps.length)
                        return "";

                    var app = dockWindow.displayApps[dockWindow.activePreviewIndex];
                    if (!app || !app.icon) return "";
                    var ic = app.icon;
                    if (ic.indexOf("/") === 0) return "file://" + ic;
                    if (ic.startsWith("file://") || ic.startsWith("image://") || ic.startsWith("qrc:/")) return ic;
                    return "image://icon/" + ic;
                }
            }

            UI.Typography {
                theme: dockWindow ? dockWindow.theme : null
                Layout.fillWidth: true
                text: {
                    if (!dockWindow || dockWindow.activePreviewIndex < 0 || dockWindow.activePreviewIndex >= dockWindow.displayApps.length)
                        return "";

                    var app = dockWindow.displayApps[dockWindow.activePreviewIndex];
                    return app ? (app.name || app.className || "") : "";
                }
                variant: "labelSmall"
                colorRole: "onSurfaceVariant"
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.preferredWidth: previewCountText.implicitWidth + 10
                Layout.preferredHeight: 16
                radius: 8
                color: dockWindow && dockWindow.theme ? Qt.alpha(dockWindow.theme.getColor("primaryContainer"), 0.6) : "#434453"
                visible: {
                    if (!dockWindow || dockWindow.activePreviewIndex < 0 || dockWindow.activePreviewIndex >= dockWindow.displayApps.length)
                        return false;

                    var app = dockWindow.displayApps[dockWindow.activePreviewIndex];
                    return app && app.windowCount > 1;
                }

                UI.Typography {
                    id: previewCountText
                    theme: dockWindow ? dockWindow.theme : null
                    anchors.centerIn: parent
                    text: {
                        if (!dockWindow || dockWindow.activePreviewIndex < 0 || dockWindow.activePreviewIndex >= dockWindow.displayApps.length)
                            return "1";

                        var app = dockWindow.displayApps[dockWindow.activePreviewIndex];
                        return app ? (app.windowCount || 1).toString() : "1";
                    }
                    variant: "labelSmall"
                    colorRole: "onPrimaryContainer"
                    font.bold: true
                }
            }
        }
    }
}
