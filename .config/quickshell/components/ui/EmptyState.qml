import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

ColumnLayout {
    id: emptyStateRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 10
    Layout.topMargin: 16
    Layout.bottomMargin: 16

    property var theme
    property string icon: ""
    property string defaultIcon: "actions/search.svg"
    property string title: ""
    property string subtitle: ""
    property string searchQuery: ""

    Rectangle {
        width: 48
        height: 48
        radius: 24
        color: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("surfaceVariant") : "#2b2b35"
        Layout.alignment: Qt.AlignHCenter

        Icon {
            anchors.centerIn: parent
            size: 24
            icon: emptyStateRoot.icon !== "" ? emptyStateRoot.icon : emptyStateRoot.defaultIcon
            color: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("primary") : "#ffb3b4"
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 3

        Text {
            text: emptyStateRoot.title !== ""
                ? emptyStateRoot.title
                : (emptyStateRoot.searchQuery === "" ? "No items found" : "No matching items found")
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 13
            font.bold: true
            color: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("onSurface") : "#f0dede"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: emptyStateRoot.subtitle
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 11
            color: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("outline") : "#757680"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: emptyStateRoot.subtitle !== ""
        }
    }
}
