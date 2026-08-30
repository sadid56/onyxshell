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
            width: 32
            height: 32
            radius: 16
            color: rowRoot.theme ? Qt.alpha(rowRoot.theme.getColor("surfaceVariant"), 0.70) : "#302f38"
            visible: rowRoot.icon !== ""
            Layout.alignment: Qt.AlignVCenter

            UI.Icon {
                anchors.centerIn: parent
                size: 16
                icon: rowRoot.icon
                color: rowRoot.theme.getColor("primary")
            }
        }

        ColumnLayout {
            id: textColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            UI.Typography {
                theme: rowRoot.theme
                text: rowRoot.title
                variant: "bodyMedium"
                font.bold: true
                colorRole: "onSurface"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            UI.Typography {
                theme: rowRoot.theme
                text: rowRoot.subtitle
                variant: "labelSmall"
                colorRole: "onSurfaceVariant"
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
