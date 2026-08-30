import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

ColumnLayout {
    id: cardRoot
    Layout.fillWidth: true
    spacing: 6

    property var theme
    property string title: ""
    property string description: ""

    default property alias contentData: cardContainer.data

    UI.Typography {
        theme: cardRoot.theme
        text: cardRoot.title
        variant: "labelMedium"
        font.weight: Font.DemiBold
        colorRole: "primary"
        visible: cardRoot.title !== ""
        Layout.leftMargin: 4
        Layout.bottomMargin: 2
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: cardContentCol.implicitHeight + 28
        radius: 16
        color: cardRoot.theme ? Qt.alpha(cardRoot.theme.getColor("surfaceVariant"), 0.35) : "#24232a"
        border.width: 1
        border.color: cardRoot.theme ? Qt.alpha(cardRoot.theme.getColor("outlineVariant"), 0.25) : "#38373e"

        Column {
            id: cardContentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            Column {
                id: cardContainer
                width: parent.width
                spacing: 8
            }
        }
    }
}
