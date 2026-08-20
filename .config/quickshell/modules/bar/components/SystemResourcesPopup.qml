import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../../../components/containers"
import "../../../core"
import "./"

Popup {
    id: resourceWindow
    popupWidth: 380
    popupHeight: 490

    property var telemetryData: ({
        "cpu": { "usage": 0, "cores": 0, "freq": 0 },
        "memory": { "used_gb": 0, "total_gb": 0, "usage": 0 },
        "swap": { "used_gb": 0, "total_gb": 0, "usage": 0 },
        "top_apps": []
    })

    ListModelUtils { id: modelUtils }
    ListModel { id: appsModel }

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
        command: ["python", shellConfig.getScript("sys_resources.py")]
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
            resourceProc.running = false;
            resourceProc.running = true;
        } else {
            resourceProc.running = false;
            processCtxMenu.hide();
            appsModel.clear();
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0
        RowLayout {
            Layout.fillWidth: true; Layout.bottomMargin: 16; spacing: 8
            IconImage {
                width: 15; height: 15; Layout.alignment: Qt.AlignVCenter
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getCpuIcon()
                layer.enabled: true
                layer.effect: MultiEffect { colorization: 1.0; colorizationColor: resourceWindow.theme ? resourceWindow.theme.getColor("primary") : "#adc6ff" }
            }
            Text {
                text: "System Resources"; font.family: "Google Sans Flex, sans-serif"; font.pixelSize: 13; font.bold: true
                color: resourceWindow.theme ? resourceWindow.theme.getColor("onSurface") : "#FFFFFF"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: (resourceWindow.telemetryData.cpu.cores || 0) + " Cores · " + (resourceWindow.telemetryData.cpu.freq || 0) + " GHz"
                font.family: "Google Sans Flex, sans-serif"; font.pixelSize: 10
                color: resourceWindow.theme ? resourceWindow.theme.getColor("outline") : "#8c909f"
            }
        }
        ResourceGaugeCard {
            theme: resourceWindow.theme
            title: "CPU"
            valueText: Math.round(resourceWindow.telemetryData.cpu.usage || 0) + "%"
            subText: (resourceWindow.telemetryData.cpu.freq || 0) + " GHz"
            iconSource: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getCpuIcon()
            progress: resourceWindow.telemetryData.cpu.usage || 0
            Layout.bottomMargin: 6
        }
        ResourceGaugeCard {
            theme: resourceWindow.theme
            title: "Memory"
            valueText: Math.round(resourceWindow.telemetryData.memory.usage || 0) + "%"
            subText: (resourceWindow.telemetryData.memory.used_gb || 0) + " / " + (resourceWindow.telemetryData.memory.total_gb || 0) + " GB"
            iconSource: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getMemoryIcon()
            progress: resourceWindow.telemetryData.memory.usage || 0
            Layout.bottomMargin: 6
        }
        ResourceGaugeCard {
            theme: resourceWindow.theme
            title: "ZRAM"
            valueText: Math.round(resourceWindow.telemetryData.swap.usage || 0) + "%"
            subText: (resourceWindow.telemetryData.swap.used_gb || 0) + " / " + (resourceWindow.telemetryData.swap.total_gb || 0) + " GB"
            iconSource: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getSwapIcon()
            progress: resourceWindow.telemetryData.swap.usage || 0
            Layout.bottomMargin: 14
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.06)
            Layout.bottomMargin: 10
        }
        RowLayout {
            Layout.fillWidth: true; Layout.bottomMargin: 4; Layout.leftMargin: 6; Layout.rightMargin: 6; spacing: 0
            Text { text: "Top Processes"; font.family: "Google Sans Flex, sans-serif"; font.pixelSize: 11; font.bold: true; color: resourceWindow.theme ? resourceWindow.theme.getColor("onSurface") : "#FFFFFF" }
            Item { Layout.fillWidth: true }
            Text { text: "CPU"; font.family: "Google Sans Flex, sans-serif"; font.pixelSize: 9; color: resourceWindow.theme ? resourceWindow.theme.getColor("outline") : "#8c909f"; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
            Text { text: "RAM"; font.family: "Google Sans Flex, sans-serif"; font.pixelSize: 9; color: resourceWindow.theme ? resourceWindow.theme.getColor("outline") : "#8c909f"; Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight }
        }

        ListView {
            id: topAppsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 1
            boundsBehavior: Flickable.StopAtBounds
            model: appsModel

            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                    NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
                }
            }
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0.0; duration: 160; easing.type: Easing.OutQuad }
                    NumberAnimation { property: "scale"; to: 0.95; duration: 160; easing.type: Easing.OutCubic }
                }
            }
            move: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }
            moveDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }
            displaced: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }
            removeDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }
            addDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }

            delegate: TopAppItemRow {
                width: ListView.view.width
                theme: resourceWindow.theme
                appData: ({ "name": model.name, "cpu": model.cpu, "mem": model.mem, "rss_mb": model.rss_mb, "count": model.count })
                rank: index + 1
                onRightClicked: (data, gx, gy) => {
                    var local = resourceWindow.contentRect.mapFromItem(null, gx, gy);
                    processCtxMenu.show(data, Math.min(local.x, resourceWindow.popupWidth - 170), Math.min(local.y, resourceWindow.popupHeight - 140));
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 42
                z: 10
                enabled: false
                visible: topAppsList.count > 3
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(resourceWindow.theme ? resourceWindow.theme.getColor("surface").r : 0.11, resourceWindow.theme ? resourceWindow.theme.getColor("surface").g : 0.11, resourceWindow.theme ? resourceWindow.theme.getColor("surface").b : 0.11, 0.0) }
                    GradientStop { position: 1.0; color: resourceWindow.theme ? resourceWindow.theme.getColor("surface") : "#1b1b1b" }
                }
            }
        }
    }

    ProcessContextMenu {
        id: processCtxMenu
        parent: resourceWindow.contentRect
        theme: resourceWindow.theme
    }

    MouseArea {
        parent: resourceWindow.contentRect
        anchors.fill: parent
        visible: processCtxMenu.visible
        z: 99
        onClicked: processCtxMenu.hide()
    }
}
