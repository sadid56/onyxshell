import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Item {
    id: delegateRoot
    width: parentListView.width
    height: 50
    z: 1

    property var parentListView
    property var theme
    readonly property bool isHovered: parentListView && typeof parentListView.isItemHighlighted === "function" ? parentListView.isItemHighlighted(index) : (parentListView && parentListView.hoveredIndex === index)
    readonly property string itemKeys: typeof keys !== "undefined" ? String(keys) : (typeof modelData !== "undefined" && modelData && modelData.keys ? String(modelData.keys) : "")
    readonly property string itemAction: typeof action !== "undefined" ? String(action) : (typeof modelData !== "undefined" && modelData && modelData.action ? String(modelData.action) : "")
    readonly property string itemCategory: typeof category !== "undefined" ? String(category) : (typeof modelData !== "undefined" && modelData && modelData.category ? String(modelData.category) : "General")
    readonly property var keyParts: (itemKeys || "").split("+").map(s => s.trim()).filter(s => s !== "")

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            if (parentListView && typeof parentListView.hoverItem === "function") {
                parentListView.hoverItem(index, delegateRoot.y, delegateRoot.height);
            }
        }
        onExited: {
            if (parentListView && typeof parentListView.unhoverItem === "function") {
                parentListView.unhoverItem(index);
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 14

        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: delegateRoot.theme ? delegateRoot.theme.getColor("surface") : "#1b1b1b"
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("keyboard.svg")
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: delegateRoot.isHovered ?
                           (delegateRoot.theme ? delegateRoot.theme.getColor("primary") : "#ffb3b4") :
                           (delegateRoot.theme ? delegateRoot.theme.getColor("onSurfaceVariant") : "#c4c5d0")
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: delegateRoot.itemAction
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 13
                font.bold: true
                color: delegateRoot.isHovered ?
                       (delegateRoot.theme ? delegateRoot.theme.getColor("primary") : "#ffb3b4") :
                       (delegateRoot.theme ? delegateRoot.theme.getColor("onSurface") : "#f0dede")
                elide: Text.ElideRight
                Layout.fillWidth: true
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Text {
                text: delegateRoot.itemCategory
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 10
                color: delegateRoot.theme ? delegateRoot.theme.getColor("outline") : "#757680"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: delegateRoot.keyParts
                delegate: RowLayout {
                    spacing: 4
                    Rectangle {
                        height: 28
                        width: keyLabel.implicitWidth + 16
                        radius: 8
                        color: delegateRoot.theme ? delegateRoot.theme.getColor("surface") : "#1b1b1b"
                        border.width: 0

                        Text {
                            id: keyLabel
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "Google Sans Flex, sans-serif"
                            font.pixelSize: 11
                            font.bold: true
                            color: delegateRoot.theme ? delegateRoot.theme.getColor("primary") : "#ffb3b4"
                        }
                    }

                    Text {
                        text: "+"
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 11
                        font.bold: true
                        color: delegateRoot.theme ? delegateRoot.theme.getColor("outline") : "#757680"
                        visible: index < delegateRoot.keyParts.length - 1
                    }
                }
            }
        }
    }
}
