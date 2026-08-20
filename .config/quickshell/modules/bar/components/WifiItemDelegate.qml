import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Item {
    id: delegateWrapper
    width: parentListView.width
    height: 42
    z: 1

    property var parentListView
    property var theme
    readonly property var netInfo: modelData
    readonly property bool isHighlighted: parentListView.isItemHighlighted(index)

    signal itemClicked(var info)

    MouseArea {
        id: mouseArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -2
        hoverEnabled: true
        cursorShape: delegateWrapper.netInfo.active ? Qt.ArrowCursor : Qt.PointingHandCursor
        onEntered: parentListView.hoverItem(index, delegateWrapper.y, delegateWrapper.height)
        onExited: parentListView.unhoverItem(index)
        onClicked: delegateWrapper.itemClicked(delegateWrapper.netInfo)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        IconImage {
            width: 14
            height: 14
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getWifiIcon(delegateWrapper.netInfo.signal, true, true)
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: delegateWrapper.netInfo.active ? delegateWrapper.theme.getColor("primary") : (delegateWrapper.isHighlighted ? delegateWrapper.theme.getColor("primary") : delegateWrapper.theme.getColor("onSurface"))
            }
        }

        Text {
            text: delegateWrapper.netInfo.ssid
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 13
            font.bold: delegateWrapper.netInfo.active || delegateWrapper.netInfo.saved
            color: delegateWrapper.netInfo.active ? delegateWrapper.theme.getColor("primary") : (delegateWrapper.isHighlighted ? delegateWrapper.theme.getColor("primary") : delegateWrapper.theme.getColor("onSurface"))
            Layout.fillWidth: true
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: delegateWrapper.netInfo.active ? "Connected" : (delegateWrapper.netInfo.saved ? "Saved" : "")
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 10
                font.bold: true
                color: delegateWrapper.netInfo.active ? delegateWrapper.theme.getColor("primary") : (delegateWrapper.netInfo.saved ? delegateWrapper.theme.getColor("primary") : delegateWrapper.theme.getColor("outline"))
                visible: delegateWrapper.netInfo.active || delegateWrapper.netInfo.saved
                Layout.alignment: Qt.AlignVCenter
            }

            IconImage {
                width: 12
                height: 12
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("lock-closed.svg")
                visible: !delegateWrapper.netInfo.active && !delegateWrapper.netInfo.saved && delegateWrapper.netInfo.security !== ""
                Layout.alignment: Qt.AlignVCenter
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: delegateWrapper.theme.getColor("outline")
                }
            }
        }
    }
}
