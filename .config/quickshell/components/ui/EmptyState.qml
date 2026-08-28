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

        Typography {
            theme: emptyStateRoot.theme
            text: emptyStateRoot.title !== ""
                ? emptyStateRoot.title
                : (emptyStateRoot.searchQuery === "" ? "No items found" : "No matching items found")
            variant: "bodyMedium"
            font.bold: true
            colorRole: "onSurface"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Typography {
            theme: emptyStateRoot.theme
            text: emptyStateRoot.subtitle
            variant: "bodySmall"
            colorRole: "outline"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: emptyStateRoot.subtitle !== ""
        }
    }
}
