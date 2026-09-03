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
    height: 52
    z: 1

    readonly property string entryText: (rawEntryData !== undefined && rawEntryData !== null) ? String(rawEntryData) : ""
    property bool isImage: (clipService && clipService.isImageEntry(entryText)) || entryText.indexOf("[[ binary data") !== -1
    property string imageSource: (isImage && clipService) ? clipService.getImagePreview(entryText) : ""
    property string cleanDisplay: {
        var t = entryText.indexOf("\t") !== -1 ? entryText.substring(entryText.indexOf("\t") + 1) : entryText;
        t = t.replace(/\r?\n|\r/g, " ").trim();
        if (t.indexOf("[[ binary data") !== -1) {
            var match = t.match(/\[\[ binary data (?:[\d.]+\s*\w+)?\s*(\w+)?\s*([\dx]+)? \]\]/);
            var res = match && match[2] ? match[2] : "";
            var fmt = match && match[1] ? match[1].toUpperCase() : "PNG";
            return res ? ("Image • " + fmt + " (" + res + ")") : ("Image • " + fmt);
        }
        return t;
    }
    property bool isPinned: clipService ? clipService.isPinned(entryText) : false

    readonly property bool isHovered: mouseArea.containsMouse || (typeof pinMouse !== "undefined" && pinMouse.containsMouse) || (typeof deleteMouse !== "undefined" && deleteMouse.containsMouse)

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
        z: 1
        onEntered: delegateWrapper.hovered(delegateWrapper.y, delegateWrapper.height)
        onExited: {
            if (!pinMouse.containsMouse && !deleteMouse.containsMouse) {
                delegateWrapper.unhovered();
            }
        }
        onClicked: delegateWrapper.itemClicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12
        z: 2

        ClippingRectangle {
            id: imgContainer
            width: 38
            height: 38
            radius: 7
            color: delegateWrapper.isSelected
                ? (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("onSecondaryContainer") || "#ffffff", 0.15) : "#35ffffff")
                : (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("surfaceVariant"), 0.70) : "#282836")
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: clipImg
                anchors.fill: parent
                source: delegateWrapper.imageSource
                visible: delegateWrapper.isImage && delegateWrapper.imageSource !== ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
            }

            IconImage {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(delegateWrapper.isImage ? "actions/image.svg" : "actions/image-copy.svg")
                visible: !delegateWrapper.isImage || delegateWrapper.imageSource === ""
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: delegateWrapper.isSelected
                        ? (delegateWrapper.theme ? delegateWrapper.theme.getColor("onSecondaryContainer") : "#ffffff")
                        : (delegateWrapper.theme ? delegateWrapper.theme.getColor("onSurfaceVariant") : "#aaaaaa")
                }
            }
        }

        UI.Typography {
            theme: delegateWrapper.theme
            Layout.fillWidth: true
            text: delegateWrapper.cleanDisplay
            variant: "bodyMedium"
            colorRole: delegateWrapper.isSelected ? "onSecondaryContainer" : "onSurface"
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.alignment: Qt.AlignVCenter
        }

        RowLayout {
            spacing: (delegateWrapper.isSelected || delegateWrapper.isHovered) ? 4 : 0
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: pinBtn
                Layout.preferredWidth: (delegateWrapper.isPinned || delegateWrapper.isSelected || delegateWrapper.isHovered) ? 28 : 0
                Layout.preferredHeight: 28
                width: Layout.preferredWidth
                height: 28
                radius: 14
                clip: true
                z: 10
                color: pinMouse.containsMouse
                    ? (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("primary"), 0.25) : "#44ffffff")
                    : (delegateWrapper.isPinned
                        ? (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("primary"), 0.15) : "#33ffffff")
                        : "transparent")
                opacity: (delegateWrapper.isPinned || delegateWrapper.isSelected || delegateWrapper.isHovered) ? 1.0 : 0.0
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
                    onEntered: delegateWrapper.hovered(delegateWrapper.y, delegateWrapper.height)
                    onExited: {
                        if (!mouseArea.containsMouse && !deleteMouse.containsMouse) {
                            delegateWrapper.unhovered();
                        }
                    }
                    onClicked: mouse => {
                        mouse.accepted = true;
                        delegateWrapper.pinRequested();
                    }
                }
            }

            Rectangle {
                id: deleteBtn
                Layout.preferredWidth: (delegateWrapper.isSelected || delegateWrapper.isHovered) ? 28 : 0
                Layout.preferredHeight: 28
                width: Layout.preferredWidth
                height: 28
                radius: 14
                clip: true
                z: 10
                color: deleteMouse.containsMouse
                    ? (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("error"), 0.25) : "#44ff5555")
                    : "transparent"
                opacity: (delegateWrapper.isSelected || delegateWrapper.isHovered) ? 1.0 : 0.0
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
                    onEntered: delegateWrapper.hovered(delegateWrapper.y, delegateWrapper.height)
                    onExited: {
                        if (!mouseArea.containsMouse && !pinMouse.containsMouse) {
                            delegateWrapper.unhovered();
                        }
                    }
                    onClicked: mouse => {
                        mouse.accepted = true;
                        delegateWrapper.deleteRequested();
                    }
                }
            }
        }
    }
}
