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

    readonly property var unhoverTimer: unhoverTimer
    readonly property var hoverPill: hoverPill

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
            if (currentIndex < 0) hoverPill.isHovered = false;
        }
    }

    onCurrentIndexChanged: {
        updatePillPosition();
        if (currentIndex === 0) positionViewAtBeginning();
        else if (currentIndex === count - 1) positionViewAtEnd();
        else if (currentIndex > 0 && currentIndex < count) positionViewAtIndex(currentIndex, ListView.Contain);
    }

    signal entryClicked(string entryText)
    signal deleteClicked(string entryText)
    signal pinClicked(string entryText)
    signal upPressedAtStart()
    signal escapePressed()

    function removeEntryOptimistically(idx, entryText) {
        if (idx >= 0 && idx < dynamicClipModel.count) dynamicClipModel.remove(idx);
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
        radius: 12
        color: entriesListRoot.theme ? entriesListRoot.theme.getColor("secondaryContainer") : "#3d3a48"
        visible: entriesListRoot.count > 0

        property real targetY: 0
        property bool isHovered: entriesListRoot.count > 0

        y: targetY
        opacity: isHovered ? 1.0 : 0.0

        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    delegate: ClipboardEntryDelegate {
        entriesListRoot: entriesListRoot
        modelIndex: index
        rawEntryData: entryData
    }

    Keys.onDownPressed: {
        if (currentIndex < count - 1) {
            currentIndex++;
        }
    }

    Keys.onUpPressed: {
        if (currentIndex > 0) {
            currentIndex--;
        } else {
            upPressedAtStart();
        }
    }

    Keys.onReturnPressed: {
        if (currentIndex >= 0 && currentIndex < dynamicClipModel.count) {
            var item = dynamicClipModel.get(currentIndex);
            if (item) {
                var text = item.entryData || "";
                entryClicked(text);
            }
        }
    }

    Keys.onEscapePressed: {
        escapePressed();
    }
}
