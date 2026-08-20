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
    pillColor: entriesListRoot.theme ? entriesListRoot.theme.getColor("surfaceVariant") : "#2b2a27"

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
    }

    signal entryClicked(string entryText)
    signal deleteClicked(string entryText)
    signal upPressedAtStart()
    signal escapePressed()

    function removeEntryOptimistically(idx, entryText) {
        if (idx >= 0 && idx < dynamicClipModel.count) {
            unhoverItem(idx);
            dynamicClipModel.remove(idx);
        }
        deleteClicked(entryText);
    }

    ListModel { id: dynamicClipModel }

    model: dynamicClipModel
    currentIndex: -1

    delegate: Item {
        id: delegateWrapper
        width: entriesListRoot.width
        height: 48
        z: 1

        readonly property string entryText: entryData !== undefined ? entryData : (modelData !== undefined ? modelData : "")
        readonly property bool isHighlighted: entriesListRoot.isItemHighlighted(index)
        property bool isImage: entriesListRoot.clipService ? entriesListRoot.clipService.isImageEntry(entryText) : false
        property string imageSource: (isImage && entriesListRoot.clipService) ? entriesListRoot.clipService.getImagePreview(entryText) : ""
        property string cleanDisplay: entryText.indexOf("\t") !== -1 ? entryText.substring(entryText.indexOf("\t") + 1).replace(/\r?\n|\r/g, " ") : entryText.replace(/\r?\n|\r/g, " ")

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: entriesListRoot.hoverItem(index, delegateWrapper.y, delegateWrapper.height)
            onExited: {
                if (!deleteMouse.containsMouse) {
                    entriesListRoot.unhoverItem(index);
                }
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
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(delegateWrapper.isImage ? "image.svg" : "image-copy.svg")
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
                id: deleteBtn
                width: 28
                height: 28
                radius: 14
                Layout.alignment: Qt.AlignVCenter
                color: deleteMouse.containsMouse
                    ? (entriesListRoot.theme ? entriesListRoot.theme.getColor("errorContainer") : "#93000a")
                    : (delegateWrapper.isHighlighted ? (entriesListRoot.theme ? entriesListRoot.theme.getColor("surface") : "#1b1b1b") : "transparent")
                opacity: (delegateWrapper.isHighlighted || deleteMouse.containsMouse) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 140 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("dismiss.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: deleteMouse.containsMouse
                            ? (entriesListRoot.theme ? entriesListRoot.theme.getColor("error") : "#ffb4ab")
                            : (entriesListRoot.theme ? entriesListRoot.theme.getColor("outline") : "#757680")
                    }
                }

                MouseArea {
                    id: deleteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: entriesListRoot.hoverItem(index, delegateWrapper.y, delegateWrapper.height)
                    onExited: {
                        if (!mouseArea.containsMouse) {
                            entriesListRoot.unhoverItem(index);
                        }
                    }
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
        } else if (event.key === Qt.Key_Escape) {
            entriesListRoot.escapePressed();
            event.accepted = true;
        }
    }
}
