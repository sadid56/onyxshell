import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

RowLayout {
    id: headerRow
    Layout.fillWidth: true
    spacing: 10

    property var cardItem
    property var theme

    ClippingRectangle {
        id: iconWrapper
        width: 36
        height: 36
        radius: 18
        color: headerRow.cardItem.theme ? headerRow.cardItem.theme.getColor("surfaceVariant") : "#2b2a2a"
        Layout.alignment: Qt.AlignTop

        IconImage {
            anchors.fill: parent
            anchors.margins: 0
            source: headerRow.cardItem.getNotifIcon()
            onStatusChanged: {
                if (status === Image.Error) source = "file://" + shellConfig.defaultAppIcon;
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: headerRow.cardItem.summaryText
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 12
                font.bold: true
                color: headerRow.cardItem.theme ? headerRow.cardItem.theme.getColor("onSurface") : "#FFFFFF"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: headerRow.cardItem.theme ? headerRow.cardItem.theme.getColor("surface") : "#1b1b1b"
                opacity: arrowMouse.containsMouse ? 0.7 : 1.0
                Layout.alignment: Qt.AlignVCenter
                z: 2
                Behavior on opacity { NumberAnimation { duration: 120 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/chevron-down.svg")
                    rotation: headerRow.cardItem.expanded ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: headerRow.cardItem.theme ? headerRow.cardItem.theme.getColor("onSurface") : "#f0dede"
                    }
                }

                MouseArea {
                    id: arrowMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: headerRow.cardItem.toggleExpandedRequested()
                }
            }
        }

        Text {
            text: headerRow.cardItem.bodyText
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 11
            color: headerRow.cardItem.theme ? headerRow.cardItem.theme.getColor("onSurfaceVariant") : "#8f8f9f"
            elide: headerRow.cardItem.expanded ? Text.ElideNone : Text.ElideRight
            maximumLineCount: headerRow.cardItem.expanded ? 8 : 2
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            visible: headerRow.cardItem.bodyText !== ""
        }
    }
}
