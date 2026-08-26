import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

UI.AnimatedListView {
    id: entriesListRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: Math.min(380, count * 54)
    spacing: 4
    focus: true
    pillColor: "transparent"

    property var clipService
    property string searchQuery: ""
    property var entriesModel: []

    function normalizeEntries(src) {
        if (!src) return [];
        var res = [];
        for (var i = 0; i < src.length; i++) {
            var item = src[i];
            res.push((typeof item === "object" && item.entryData !== undefined) ? item : { "entryData": String(item) });
        }
        return res;
    }

    onEntriesModelChanged: {
        syncListModel(dynamicClipModel, normalizeEntries(entriesModel), "entryData", 25);
        if (dynamicClipModel.count > 0) {
            currentIndex = 0;
            updatePillPosition();
            positionViewAtBeginning();
        } else {
            currentIndex = -1;
            hoverPill.isHovered = false;
        }
    }

    function updatePillPosition() {
        if (currentIndex >= 0 && currentIndex < count) {
            unhoverTimer.stop();
            hoverPill.targetY = currentIndex * (48 + spacing);
            hoverPill.isHovered = true;
        } else {
            hoverPill.isHovered = false;
        }
    }

    Timer {
        id: unhoverTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (currentIndex < 0) {
                hoverPill.isHovered = false;
            }
        }
    }

    onCurrentIndexChanged: {
        updatePillPosition();
        if (currentIndex === 0) {
            positionViewAtBeginning();
        } else if (currentIndex === count - 1) {
            positionViewAtEnd();
        } else if (currentIndex > 0 && currentIndex < count) {
            positionViewAtIndex(currentIndex, ListView.Contain);
        }
    }

    signal entryClicked(string entryText)
    signal deleteClicked(string entryText)
    signal pinClicked(string entryText)
    signal upPressedAtStart()
    signal escapePressed()

    function removeEntryOptimistically(idx, entryText) {
        if (idx >= 0 && idx < dynamicClipModel.count) {
            dynamicClipModel.remove(idx);
        }
        deleteClicked(entryText);
    }

    ListModel { id: dynamicClipModel }

    model: dynamicClipModel
    currentIndex: 0

    Rectangle {
        id: hoverPill
        parent: entriesListRoot.contentItem
        z: 0
        x: 8
        width: Math.max(0, entriesListRoot.width - 16)
        height: 48
        radius: 10
        color: entriesListRoot.theme ? entriesListRoot.theme.getColor("surfaceVariant") : "#2b2a27"
        visible: entriesListRoot.count > 0

        property real targetY: 0
        property bool isHovered: entriesListRoot.count > 0

        y: targetY
        opacity: isHovered ? 1.0 : 0.0

        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    delegate: Item {
        id: delegateWrapper
        width: entriesListRoot.width
        height: 48
        z: 1

        readonly property string entryText: entryData !== undefined ? entryData : (modelData !== undefined ? modelData : "")
        readonly property bool isHovered: mouseArea.containsMouse || pinMouse.containsMouse || deleteMouse.containsMouse
        readonly property bool isHighlighted: isHovered || (entriesListRoot.currentIndex === index)
        property bool isImage: entriesListRoot.clipService ? entriesListRoot.clipService.isImageEntry(entryText) : false
        property string imageSource: (isImage && entriesListRoot.clipService) ? entriesListRoot.clipService.getImagePreview(entryText) : ""
        property string cleanDisplay: entryText.indexOf("\t") !== -1 ? entryText.substring(entryText.indexOf("\t") + 1).replace(/\r?\n|\r/g, " ") : entryText.replace(/\r?\n|\r/g, " ")
        property bool isPinned: entriesListRoot.clipService ? entriesListRoot.clipService.isPinned(entryText) : false

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                unhoverTimer.stop();
                entriesListRoot.currentIndex = index;
                hoverPill.targetY = index * (48 + entriesListRoot.spacing);
                hoverPill.isHovered = true;
            }
            onExited: {
                unhoverTimer.restart();
            }
            onClicked: entriesListRoot.entryClicked(delegateWrapper.entryText)
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
                color: entriesListRoot.theme ? entriesListRoot.theme.getColor("surface") : "#1b1b1b"
                Layout.alignment: Qt.AlignVCenter
                clip: true

                Image {
                    anchors.fill: parent
                    source: delegateWrapper.imageSource
                    fillMode: Image.PreserveAspectCrop
                    visible: delegateWrapper.isImage && delegateWrapper.imageSource !== ""
                }

                IconImage {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(delegateWrapper.isImage ? "actions/image.svg" : "actions/image-copy.svg")
                    visible: !delegateWrapper.isImage || delegateWrapper.imageSource === ""
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: delegateWrapper.isHighlighted ?
                               (entriesListRoot.theme ? entriesListRoot.theme.getColor("primary") : "#ffb3b4") :
                               (entriesListRoot.theme ? entriesListRoot.theme.getColor("outline") : "#757680")
                    }
                }
            }

            Text {
                text: delegateWrapper.cleanDisplay
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 13
                font.bold: false
                color: delegateWrapper.isHighlighted ?
                       (entriesListRoot.theme ? entriesListRoot.theme.getColor("primary") : "#ffb3b4") :
                       (entriesListRoot.theme ? entriesListRoot.theme.getColor("onSurface") : "#f0dede")
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            Rectangle {
                id: pinBtn
                width: 28
                height: 28
                radius: 14
                Layout.alignment: Qt.AlignVCenter
                color: pinMouse.containsMouse
                    ? (entriesListRoot.theme ? entriesListRoot.theme.getColor("surface") : "#1b1b1b")
                    : (delegateWrapper.isPinned ? (entriesListRoot.theme ? Qt.rgba(entriesListRoot.theme.getColor("primary").r, entriesListRoot.theme.getColor("primary").g, entriesListRoot.theme.getColor("primary").b, 0.15) : "#25D0BCFF") : "transparent")
                opacity: (delegateWrapper.isHighlighted || delegateWrapper.isPinned || pinMouse.containsMouse) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 140 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 13
                    height: 13
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(delegateWrapper.isPinned ? "actions/pin-filled.svg" : "actions/pin.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: delegateWrapper.isPinned
                            ? (entriesListRoot.theme ? entriesListRoot.theme.getColor("primary") : "#D0BCFF")
                            : (pinMouse.containsMouse ? (entriesListRoot.theme ? entriesListRoot.theme.getColor("onSurface") : "#FFFFFF") : (entriesListRoot.theme ? entriesListRoot.theme.getColor("outline") : "#757680"))
                    }
                }

                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        mouse.accepted = true;
                        entriesListRoot.pinClicked(delegateWrapper.entryText);
                    }
                }
            }

            Rectangle {
                id: deleteBtn
                width: 28
                height: 28
                radius: 14
                Layout.alignment: Qt.AlignVCenter
                color: deleteMouse.containsMouse
                    ? (entriesListRoot.theme ? entriesListRoot.theme.getColor("surface") : "#1b1b1b")
                    : "transparent"
                opacity: (delegateWrapper.isHighlighted || deleteMouse.containsMouse) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 140 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/dismiss.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: entriesListRoot.theme ? entriesListRoot.theme.getColor("error") : "#FF5555"
                    }
                }

                MouseArea {
                    id: deleteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        mouse.accepted = true;
                        entriesListRoot.removeEntryOptimistically(index, delegateWrapper.entryText);
                    }
                }
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Down) {
            if (currentIndex < count - 1) currentIndex++;
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            if (currentIndex > 0) currentIndex--;
            else if (currentIndex === 0) { currentIndex = -1; entriesListRoot.upPressedAtStart(); }
            event.accepted = true;
        } else if (event.key === Qt.Key_Return) {
            if (currentIndex >= 0 && currentIndex < count) {
                var itm = dynamicClipModel.get(currentIndex);
                if (itm) entriesListRoot.entryClicked(itm.entryData !== undefined ? itm.entryData : itm);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_P) {
            if (currentIndex >= 0 && currentIndex < count) {
                var pItm = dynamicClipModel.get(currentIndex);
                if (pItm) entriesListRoot.pinClicked(pItm.entryData !== undefined ? pItm.entryData : pItm);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_D || event.key === Qt.Key_Delete) {
            if (currentIndex >= 0 && currentIndex < count) {
                var dItm = dynamicClipModel.get(currentIndex);
                if (dItm) entriesListRoot.removeEntryOptimistically(currentIndex, dItm.entryData !== undefined ? dItm.entryData : dItm);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            entriesListRoot.escapePressed();
            event.accepted = true;
        }
    }
}
