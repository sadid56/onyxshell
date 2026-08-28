import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../../../components/ui" as UI

Rectangle {
    id: ctxMenu
    width: 160
    height: menuCol.implicitHeight + 12
    radius: 10
    color: ctxMenu.theme ? ctxMenu.theme.getColor("surface") : "#1b1b1b"
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.08)
    visible: false
    z: 1000

    property var theme
    property var processData: ({})
    property string processName: ""

    signal closed()

    function show(data, lx, ly) {
        processData = data;
        processName = (data && data.name) ? data.name : "";
        var parentW = parent ? parent.width : 380;
        var parentH = parent ? parent.height : 490;
        var posX = Math.min(lx, parentW - width - 12);
        var posY = Math.min(ly, parentH - height - 12);
        ctxMenu.x = Math.max(12, posX);
        ctxMenu.y = Math.max(12, posY);
        visible = true;
    }

    function hide() {
        visible = false;
        closed();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    Process {
        id: killProc
        onRunningChanged: { if (!running) ctxMenu.hide(); }
    }

    ColumnLayout {
        id: menuCol
        anchors.fill: parent
        anchors.margins: 6
        spacing: 2

        Repeater {
            model: [
                { label: "Kill Process", cmd: "pkill", icon: "actions/dismiss.svg" },
                { label: "Force Kill", cmd: "pkill-9", icon: "system/zap.svg" },
                { label: "Open htop", cmd: "htop", icon: "system/terminal.svg" },
                { label: "Copy Name", cmd: "copy", icon: "actions/image-copy.svg" }
            ]

            delegate: Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                color: itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }

                readonly property color itemColor: modelData.cmd === "pkill-9"
                    ? (ctxMenu.theme ? ctxMenu.theme.getColor("error") : "#ff5555")
                    : (ctxMenu.theme ? ctxMenu.theme.getColor("onSurface") : "#FFFFFF")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    IconImage {
                        width: 14; height: 14
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(modelData.icon)
                        Layout.alignment: Qt.AlignVCenter
                        layer.enabled: true
                        layer.effect: MultiEffect { colorization: 1.0; colorizationColor: itemColor }
                    }

                    UI.Typography {
                        theme: ctxMenu.theme
                        text: modelData.label
                        variant: "bodySmall"
                        color: itemColor
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var cmd = modelData.cmd;
                        var name = ctxMenu.processName;
                        if (cmd === "pkill") {
                            killProc.command = ["pkill", "-x", name];
                            killProc.running = true;
                        } else if (cmd === "pkill-9") {
                            killProc.command = ["pkill", "-9", "-x", name];
                            killProc.running = true;
                        } else if (cmd === "htop") {
                            var term = Quickshell.env("TERMINAL") || "kitty";
                            killProc.command = [term, "-e", "htop", "-t", "-p", String(ctxMenu.processData.pid || "")];
                            killProc.running = true;
                            ctxMenu.hide();
                        } else if (cmd === "copy") {
                            killProc.command = ["sh", "-c", "echo -n '" + name + "' | wl-copy"];
                            killProc.running = true;
                        }
                    }
                }
            }
        }
    }
}
