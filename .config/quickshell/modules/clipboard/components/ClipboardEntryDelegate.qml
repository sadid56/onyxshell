import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

Item {
    id: delegateWrapper

    property var theme
    property var clipService
    property var rawEntryData: ""
    property bool isSelected: false

    width: parent ? parent.width : 480
    height: 48
    z: 1

    readonly property string entryText: (rawEntryData !== undefined && rawEntryData !== null) ? String(rawEntryData) : ""
    property bool isImage: clipService ? clipService.isImageEntry(entryText) : false
    property string imageSource: (isImage && clipService) ? clipService.getImagePreview(entryText) : ""
    property string cleanDisplay: entryText.indexOf("\t") !== -1 ? entryText.substring(entryText.indexOf("\t") + 1).replace(/\r?\n|\r/g, " ") : entryText.replace(/\r?\n|\r/g, " ")
    property bool isPinned: clipService ? clipService.isPinned(entryText) : false

    signal itemClicked()
    signal hovered(real yPos, real itemHeight)
    signal unhovered()
    signal pinRequested()
    signal deleteRequested()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 3
        onEntered: delegateWrapper.hovered(delegateWrapper.y, delegateWrapper.height)
        onExited: delegateWrapper.unhovered()
        onClicked: delegateWrapper.itemClicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12
        z: 2

        Rectangle {
            width: 32
            height: 32
            radius: 10
            color: delegateWrapper.theme ? delegateWrapper.theme.getColor("surfaceVariant") : "#282836"
            Layout.alignment: Qt.AlignVCenter
            clip: true

            Image {
                anchors.fill: parent
                source: delegateWrapper.imageSource
                visible: delegateWrapper.isImage && delegateWrapper.imageSource !== ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
            }

            IconImage {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(delegateWrapper.isImage ? "actions/image.svg" : "actions/image-copy.svg")
                visible: !delegateWrapper.isImage || delegateWrapper.imageSource === ""
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: delegateWrapper.theme ? delegateWrapper.theme.getColor("onSurfaceVariant") : "#aaaaaa"
                }
            }
        }

        UI.Typography {
            theme: delegateWrapper.theme
            Layout.fillWidth: true
            text: delegateWrapper.cleanDisplay
            variant: "bodyMedium"
            colorRole: delegateWrapper.isSelected ? "onSecondaryContainer" : "onSurface"
            font.weight: delegateWrapper.isSelected ? Font.Medium : Font.Normal
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.alignment: Qt.AlignVCenter
        }

        RowLayout {
            spacing: (delegateWrapper.isSelected || mouseArea.containsMouse) ? 4 : 0
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: pinBtn
                Layout.preferredWidth: (delegateWrapper.isPinned || delegateWrapper.isSelected || mouseArea.containsMouse) ? 28 : 0
                Layout.preferredHeight: 28
                width: Layout.preferredWidth
                height: 28
                radius: 14
                clip: true
                z: 4
                color: pinMouse.containsMouse
                    ? (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("primary"), 0.25) : "#44ffffff")
                    : (delegateWrapper.isPinned
                        ? (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("primary"), 0.15) : "#33ffffff")
                        : "transparent")
                opacity: (delegateWrapper.isPinned || delegateWrapper.isSelected || mouseArea.containsMouse) ? 1.0 : 0.0
                Layout.alignment: Qt.AlignVCenter

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 120 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(delegateWrapper.isPinned ? "actions/pin-filled.svg" : "actions/pin.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: delegateWrapper.isPinned
                            ? (delegateWrapper.theme ? delegateWrapper.theme.getColor("primary") : "#ffb3b4")
                            : (delegateWrapper.theme ? delegateWrapper.theme.getColor("onSurfaceVariant") : "#aaaaaa")
                    }
                }

                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: delegateWrapper.pinRequested()
                }
            }

            Rectangle {
                id: deleteBtn
                Layout.preferredWidth: (delegateWrapper.isSelected || mouseArea.containsMouse) ? 28 : 0
                Layout.preferredHeight: 28
                width: Layout.preferredWidth
                height: 28
                radius: 14
                clip: true
                z: 4
                color: deleteMouse.containsMouse
                    ? (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("error"), 0.25) : "#44ff5555")
                    : "transparent"
                opacity: (delegateWrapper.isSelected || mouseArea.containsMouse) ? 1.0 : 0.0
                Layout.alignment: Qt.AlignVCenter

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 120 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/trash.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: deleteMouse.containsMouse
                            ? (delegateWrapper.theme ? delegateWrapper.theme.getColor("error") : "#ff5449")
                            : (delegateWrapper.theme ? delegateWrapper.theme.getColor("onSurfaceVariant") : "#aaaaaa")
                    }
                }

                MouseArea {
                    id: deleteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: delegateWrapper.deleteRequested()
                }
            }
        }
    }
}
