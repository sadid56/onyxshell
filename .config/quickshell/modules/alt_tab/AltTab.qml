import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "./components"

PanelWindow {
    id: altTabWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    visible: active

    property var theme
    property int selectedIndex: 0
    property var clientsList: []

    property var clientsProc: Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var txt = this.text ? this.text.trim() : "";
                    if (!txt) return;
                    var parsed = JSON.parse(txt);
                    if (parsed) {
                        var curWsId = (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id : 1;
                        var filtered = [];
                        for (var i = 0; i < parsed.length; i++) {
                            var c = parsed[i];
                            if (c && !c.hidden && c.workspace && c.workspace.id === curWsId) {
                                filtered.push(c);
                            }
                        }
                        filtered.sort((a, b) => (a.focusHistoryID || 0) - (b.focusHistoryID || 0));
                        var wasZero = (altTabWindow.selectedIndex === 0);
                        altTabWindow.clientsList = filtered;
                        if (altTabWindow.active && wasZero && filtered.length > 1) {
                            altTabWindow.selectedIndex = 1;
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(name, data) {
            if (!altTabWindow.active) {
                altTabWindow.refreshClients();
            }
        }
    }

    Component.onCompleted: {
        refreshClients();
    }

    function refreshClients() {
        clientsProc.running = false;
        clientsProc.running = true;
    }

    function nextWindow() {
        if (clientsList.length === 0) return;
        selectedIndex = (selectedIndex + 1) % clientsList.length;
    }

    function previousWindow() {
        if (clientsList.length === 0) return;
        selectedIndex = (selectedIndex - 1 + clientsList.length) % clientsList.length;
    }

    function selectAndClose() {
        if (!altTabWindow.active) return;
        var target = (selectedIndex >= 0 && selectedIndex < clientsList.length) ? clientsList[selectedIndex] : null;
        altTabWindow.active = false;
        if (target && target.address) {
            var addr = target.address;
            var script = "hl.dispatch(hl.dsp.focus({ window = 'address:" + addr + "' }))\n" +
                         "hl.dispatch(hl.dsp.window.bring_to_top({ window = 'address:" + addr + "' }))\n" +
                         "hl.dispatch(hl.dsp.window.alter_zorder({ mode = 'top', window = 'address:" + addr + "' }))";
            Quickshell.execDetached(["hyprctl", "eval", script]);
        }
    }

    function cancelAndClose() {
        altTabWindow.active = false;
    }

    onSelectedIndexChanged: {
        if (cardsRepeater.count > 0 && selectedIndex >= 0 && selectedIndex < cardsRepeater.count) {
            var cardItem = cardsRepeater.itemAt(selectedIndex);
            if (cardItem && flickableArea.contentWidth > flickableArea.width) {
                var targetX = cardItem.x - (flickableArea.width - cardItem.width) / 2;
                flickableArea.contentX = Math.max(0, Math.min(targetX, flickableArea.contentWidth - flickableArea.width));
            }
        }
    }

    onActiveChanged: {
        if (active) {
            refreshClients();
            selectedIndex = (clientsList.length > 1) ? 1 : 0;
        }
    }

    Item {
        id: rootContentItem
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: altTabWindow.cancelAndClose()
        }

        Rectangle {
            id: switcherCard
            anchors.centerIn: parent
            width: Math.min(altTabWindow.width * 0.85, Math.max(cardsRow.implicitWidth + 32, 280))
            height: 250
            radius: 20
            color: altTabWindow.theme ? altTabWindow.theme.getColor("surface") : "#1b1111"
            border.width: 1
            border.color: altTabWindow.theme ? altTabWindow.theme.getColor("outline") : "#574142"

            layer.enabled: altTabWindow.active
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#80000000"
                shadowBlur: 1.0
                shadowVerticalOffset: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            Item {
                anchors.fill: parent
                anchors.margins: 16
                clip: true

                Flickable {
                    id: flickableArea
                    anchors.fill: parent
                    contentWidth: cardsRow.implicitWidth
                    contentHeight: parent.height
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds

                    Behavior on contentX {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }

                    Row {
                        id: cardsRow
                        spacing: 16
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            id: cardsRepeater
                            model: altTabWindow.clientsList
                            AltTabCard {}
                        }
                    }
                }
            }
        }
    }
}
