import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

Item {
    id: rowRoot

    property var theme
    property string title: ""
    property string subtitle: ""
    property string icon: ""

    default property alias rightWidget: rightSlot.data

    width: parent ? parent.width : 400
    height: Math.max(38, Math.max(textColumn.implicitHeight, rightSlot.implicitHeight))
    implicitWidth: width
    implicitHeight: height
    Layout.fillWidth: true

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            width: 28
            height: 28
            radius: 8
            color: rowRoot.theme.getColor("surfaceVariant") + "60"
            visible: rowRoot.icon !== ""
            Layout.alignment: Qt.AlignVCenter

            UI.Icon {
                anchors.centerIn: parent
                size: 15
                icon: rowRoot.icon
                color: rowRoot.theme.getColor("primary")
            }
        }

        ColumnLayout {
            id: textColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            UI.Typography {
                theme: rowRoot.theme
                text: rowRoot.title
                variant: "bodyMedium"
                colorRole: "onSurface"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            UI.Typography {
                theme: rowRoot.theme
                text: rowRoot.subtitle
                variant: "caption"
                colorRole: "outline"
                visible: rowRoot.subtitle !== ""
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Item {
            id: rightSlot
            implicitWidth: childrenRect.width
            implicitHeight: Math.max(32, childrenRect.height)
            width: implicitWidth
            height: implicitHeight
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }
    }
}
