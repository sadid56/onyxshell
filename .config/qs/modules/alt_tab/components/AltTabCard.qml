import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../../../components/ui" as UI

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

        UI.WindowPreview {
            anchors.fill: parent
            address: modelData ? (modelData.address || "") : ""
            live: altTabWindow.active
            cornerRadius: 10
            fallbackIcon: {
                if (!modelData) return "";
                var cfg = ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : (typeof root !== "undefined" ? root.shellConfig : null));
                return cfg ? ("file://" + cfg.defaultAppIcon) : "";
            }
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
