import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import "../../../components/ui" as UI
import "../../../core"
import "../widgets"
import "./"

PanelWindow {
    id: resourceWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    visible: active || morphContainer.height > 40.5

    property var theme
    property real targetX: -1
    property var statusBar: null

    readonly property int safeWidth: resourceWindow.width > 0 ? resourceWindow.width : 1920
    readonly property int expandedWidth: 380
    readonly property int collapsedWidth: (statusBar && statusBar.rightIslandBaseWidth > 0) ? statusBar.rightIslandBaseWidth : 230
    readonly property int expandedHeight: 490

    property var telemetryData: ({
        "cpu": { "usage": 0, "cores": 0, "freq": 0 },
        "memory": { "used_gb": 0, "total_gb": 0, "usage": 0 },
        "swap": { "used_gb": 0, "total_gb": 0, "usage": 0 },
        "top_apps": []
    })

    ListModelUtils { id: modelUtils }
    ListModel { id: appsModel }

    property alias closeTimer: closeTimer

    Timer {
        id: closeTimer
        interval: 220
        repeat: false
        onTriggered: resourceWindow.active = false
    }

    function applyTelemetry(parsed) {
        resourceWindow.telemetryData = parsed;
        var apps = parsed.top_apps || [];
        modelUtils.syncListModel(appsModel, apps, "name", 10);
        for (var i = 0; i < Math.min(apps.length, appsModel.count); i++) {
            appsModel.set(i, apps[i]);
        }
    }

    property var resourceProc: Process {
        id: resourceProc
        command: ["python", ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getScript("sys_resources.py")]
        running: resourceWindow.active
        stdout: SplitParser {
            onRead: data => {
                try {
                    var parsed = JSON.parse(data.trim());
                    if (parsed && parsed.cpu) resourceWindow.applyTelemetry(parsed);
                } catch(e) {}
            }
        }
    }

    onActiveChanged: {
        if (active) {
            closeTimer.stop();
            resourceProc.running = false;
            resourceProc.running = true;
        } else {
            resourceProc.running = false;
            processCtxMenu.hide();
            appsModel.clear();
        }
    }

    Shortcut { sequence: "Escape"; enabled: resourceWindow.active; onActivated: resourceWindow.active = false }

    MouseArea {
        anchors.fill: parent
        enabled: resourceWindow.active
        hoverEnabled: true
        onClicked: resourceWindow.active = false
        onEntered: { if (resourceWindow.active) closeTimer.restart(); }
    }

    Corner {
        anchors.top: parent.top
        anchors.right: morphContainer.left
        alignRight: true
        alignBottom: false
        color: morphContainer.color
        cornerRadius: (typeof root !== "undefined" && root.settingsService && root.settingsService.cornerRadius !== undefined) ? root.settingsService.cornerRadius : 16
        visible: resourceWindow.active || morphContainer.height > 40.5
        opacity: morphContainer.opacity
    }

    Corner {
        id: resourceBottomRightCorner
        anchors.top: morphContainer.bottom
        anchors.right: parent.right
        alignRight: true
        alignBottom: false
        color: morphContainer.color
        cornerRadius: (typeof root !== "undefined" && root.settingsService && root.settingsService.cornerRadius !== undefined) ? root.settingsService.cornerRadius : 16
        visible: resourceWindow.active || morphContainer.height > 40.5
        opacity: morphContainer.opacity
    }

    Rectangle {
        id: morphContainer
        anchors.top: parent.top
        anchors.right: parent.right
        width: resourceWindow.active ? resourceWindow.expandedWidth : resourceWindow.collapsedWidth
        height: resourceWindow.active ? resourceWindow.expandedHeight : 40
        radius: (typeof root !== "undefined" && root.settingsService && root.settingsService.cornerRadius !== undefined) ? root.settingsService.cornerRadius : 16
        color: resourceWindow.theme ? resourceWindow.theme.getColor("surface") : "#1e1e2e"
        clip: true
        opacity: (resourceWindow.active || morphContainer.height > 40.5) ? 1.0 : 0.0

        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
        Behavior on height { NumberAnimation { duration: 340; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.radius
            color: parent.color
        }
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: parent.radius
            color: parent.color
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: resourceWindow.active
            shadowColor: "#60000000"
            shadowBlur: 1.0
            shadowVerticalOffset: 8
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: closeTimer.stop()
            onPositionChanged: closeTimer.stop()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            opacity: resourceWindow.active ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

            RowLayout {
                Layout.fillWidth: true
                height: 24

                RowLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    IconImage {
                        width: 16
                        height: 16
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/cpu.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect { colorization: 1.0; colorizationColor: resourceWindow.theme ? resourceWindow.theme.getColor("primary") : "#adc6ff" }
                    }

                    UI.Typography {
                        theme: resourceWindow.theme
                        text: "System Monitor"
                        variant: "titleMedium"
                        font.pixelSize: 14
                        font.bold: true
                        colorRole: "onSurface"
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: resourceWindow.theme ? resourceWindow.theme.getColor("outlineVariant") : "#20FFFFFF"
                opacity: 0.35
            }

            SystemResourceGauges {
                theme: resourceWindow.theme
                telemetryData: resourceWindow.telemetryData
            }

            RowLayout {
                Layout.fillWidth: true
                UI.Typography {
                    theme: resourceWindow.theme
                    text: "Top Processes"
                    variant: "labelSmall"
                    font.bold: true
                    colorRole: "outline"
                }
                Item { Layout.fillWidth: true }
                UI.Typography {
                    theme: resourceWindow.theme
                    text: "Right click for actions"
                    variant: "labelSmall"
                    font.italic: true
                    colorRole: "outline"
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: appsListView
                    anchors.fill: parent
                    spacing: 2
                    model: appsModel
                    boundsBehavior: Flickable.StopAtBounds
                    move: Transition {
                        NumberAnimation { properties: "y"; duration: 260; easing.type: Easing.OutCubic }
                    }
                    moveDisplaced: Transition {
                        NumberAnimation { properties: "y"; duration: 260; easing.type: Easing.OutCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "y"; duration: 260; easing.type: Easing.OutCubic }
                    }
                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                    }
                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: 150 }
                    }
                    delegate: TopAppItemRow {
                        theme: resourceWindow.theme
                        appData: model
                        rank: index + 1
                        onRightClicked: (app, lx, ly) => {
                            processCtxMenu.show(app, lx, ly);
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: processCtxMenu.visible
            z: 999
            onClicked: processCtxMenu.hide()
        }

        ProcessContextMenu {
            id: processCtxMenu
            theme: resourceWindow.theme
        }
    }
}
