import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

Item {
    id: delegateWrapper

    property var entriesListRoot
    property var modelIndex: index
    property var rawEntryData: entryData

    width: entriesListRoot ? entriesListRoot.width : parent.width
    height: 48
    z: 1

    readonly property string entryText: rawEntryData !== undefined ? rawEntryData : (modelData !== undefined ? modelData : "")
    readonly property bool isHovered: mouseArea.containsMouse || pinMouse.containsMouse || deleteMouse.containsMouse
    readonly property bool isHighlighted: isHovered || (entriesListRoot && entriesListRoot.currentIndex === modelIndex)
    property bool isImage: (entriesListRoot && entriesListRoot.clipService) ? entriesListRoot.clipService.isImageEntry(entryText) : false
    property string imageSource: (isImage && entriesListRoot && entriesListRoot.clipService) ? entriesListRoot.clipService.getImagePreview(entryText) : ""
    property string cleanDisplay: entryText.indexOf("\t") !== -1 ? entryText.substring(entryText.indexOf("\t") + 1).replace(/\r?\n|\r/g, " ") : entryText.replace(/\r?\n|\r/g, " ")
    property bool isPinned: (entriesListRoot && entriesListRoot.clipService) ? entriesListRoot.clipService.isPinned(entryText) : false

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            if (entriesListRoot) {
                entriesListRoot.unhoverTimer.stop();
                entriesListRoot.currentIndex = modelIndex;
                entriesListRoot.hoverPill.targetY = modelIndex * (48 + entriesListRoot.spacing);
                entriesListRoot.hoverPill.isHovered = true;
            }
        }
        onExited: {
            if (entriesListRoot) entriesListRoot.unhoverTimer.restart();
        }
        onClicked: {
            if (entriesListRoot) entriesListRoot.entryClicked(delegateWrapper.entryText);
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 12

        Rectangle {
            width: 28
            height: 28
            radius: 14
            color: (entriesListRoot && entriesListRoot.theme) ? entriesListRoot.theme.getColor("surface") : "#1b1b1b"
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
                width: 14
                height: 14
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(delegateWrapper.isImage ? "actions/image.svg" : "actions/document.svg")
                visible: !delegateWrapper.isImage || delegateWrapper.imageSource === ""
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: (entriesListRoot && entriesListRoot.theme) ? entriesListRoot.theme.getColor("onSurfaceVariant") : "#aaaaaa"
                }
            }
        }

        UI.Typography {
            theme: entriesListRoot ? entriesListRoot.theme : null
            Layout.fillWidth: true
            text: delegateWrapper.cleanDisplay
            variant: "bodyMedium"
            colorRole: delegateWrapper.isHighlighted ? "onSecondaryContainer" : "onSurface"
            font.weight: delegateWrapper.isHighlighted ? Font.Medium : Font.Normal
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            id: pinBtn
            width: 28
            height: 28
            radius: 14
            color: pinMouse.containsMouse
                ? (entriesListRoot && entriesListRoot.theme ? Qt.alpha(entriesListRoot.theme.getColor("primary"), 0.25) : "#44ffffff")
                : (delegateWrapper.isPinned
                    ? (entriesListRoot && entriesListRoot.theme ? Qt.alpha(entriesListRoot.theme.getColor("primary"), 0.15) : "#33ffffff")
                    : "transparent")
            opacity: (delegateWrapper.isPinned || delegateWrapper.isHovered) ? 1.0 : 0.0
            visible: opacity > 0.001
            Layout.alignment: Qt.AlignVCenter

            Behavior on opacity { NumberAnimation { duration: 120 } }
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
                        ? (entriesListRoot && entriesListRoot.theme ? entriesListRoot.theme.getColor("primary") : "#ffb3b4")
                        : (entriesListRoot && entriesListRoot.theme ? entriesListRoot.theme.getColor("onSurfaceVariant") : "#aaaaaa")
                }
            }

            MouseArea {
                id: pinMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (entriesListRoot) entriesListRoot.pinClicked(delegateWrapper.entryText);
                }
            }
        }

        Rectangle {
            id: deleteBtn
            width: 28
            height: 28
            radius: 14
            color: deleteMouse.containsMouse
                ? (entriesListRoot && entriesListRoot.theme ? Qt.alpha(entriesListRoot.theme.getColor("error"), 0.25) : "#44ff5555")
                : "transparent"
            opacity: delegateWrapper.isHovered ? 1.0 : 0.0
            visible: opacity > 0.001
            Layout.alignment: Qt.AlignVCenter

            Behavior on opacity { NumberAnimation { duration: 120 } }
            Behavior on color { ColorAnimation { duration: 120 } }

            IconImage {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/delete.svg")
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: deleteMouse.containsMouse
                        ? (entriesListRoot && entriesListRoot.theme ? entriesListRoot.theme.getColor("error") : "#ff5449")
                        : (entriesListRoot && entriesListRoot.theme ? entriesListRoot.theme.getColor("onSurfaceVariant") : "#aaaaaa")
                }
            }

            MouseArea {
                id: deleteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (entriesListRoot) entriesListRoot.removeEntryOptimistically(modelIndex, delegateWrapper.entryText);
                }
            }
        }
    }
}
