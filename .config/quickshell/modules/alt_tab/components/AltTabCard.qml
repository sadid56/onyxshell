import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Hyprland
import Quickshell.Wayland

Rectangle {
    id: thumbItem
    readonly property bool isSelected: index === altTabWindow.selectedIndex
    width: 260
    height: 200
    radius: 14
    color: isSelected
           ? (altTabWindow.theme ? altTabWindow.theme.getColor("surfaceVariant") : "#2b1c1d")
           : (altTabWindow.theme ? altTabWindow.theme.getColor("surface") : "#1b1111")
    border.width: isSelected ? 2 : 1
    border.color: isSelected
                  ? (altTabWindow.theme ? altTabWindow.theme.getColor("primary") : "#ffb3b4")
                  : (altTabWindow.theme ? altTabWindow.theme.getColor("outlineVariant") : "#574142")

    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on color { ColorAnimation { duration: 150 } }

    Item {
        anchors.fill: parent
        anchors.margins: 4
        clip: true

        ScreencopyView {
            id: winPreview
            anchors.fill: parent
            captureSource: {
                if (ToplevelManager && ToplevelManager.toplevels && ToplevelManager.toplevels.values) {
                    var rawAddr = (modelData && modelData.address) ? modelData.address.toLowerCase() : "";
                    var strippedAddr = rawAddr.replace(/^0x/, "");
                    var list = ToplevelManager.toplevels.values;
                    for (var t = 0; t < list.length; t++) {
                        var top = list[t];
                        if (top && top.HyprlandToplevel) {
                            var topAddr = (top.HyprlandToplevel.address || "").toLowerCase();
                            if (topAddr === rawAddr || topAddr === strippedAddr || ("0x" + topAddr) === rawAddr) {
                                return top;
                            }
                        }
                    }
                }
                return null;
            }
            live: altTabWindow.active
            visible: captureSource !== null
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            altTabWindow.selectedIndex = index;
            altTabWindow.selectAndClose();
        }
    }
}
