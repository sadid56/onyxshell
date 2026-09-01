import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

UI.AnimatedListView {
    id: entriesListRoot
    spacing: 4
    pillMargin: 4
    pillRadius: 16
    pillColor: entriesListRoot.theme ? entriesListRoot.theme.getColor("secondaryContainer") : "#3d3a48"

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
            currentIndex = -1;
            currentIndex = 0;
            hoverItem(0, 0, 52);
            positionViewAtBeginning();
            Qt.callLater(() => {
                if (entriesListRoot && entriesListRoot.count > 0) {
                    if (entriesListRoot.currentIndex < 0) entriesListRoot.currentIndex = 0;
                    entriesListRoot.updateSelectionPill();
                }
            });
        } else {
            currentIndex = -1;
            unhoverItem(0);
        }
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

    function getEntryAt(idx) {
        if (idx >= 0 && idx < dynamicClipModel.count) {
            var item = dynamicClipModel.get(idx);
            return item ? (item.entryData || "") : "";
        }
        return "";
    }

    ListModel { id: dynamicClipModel }

    model: dynamicClipModel
    currentIndex: 0

    delegate: ClipboardEntryDelegate {
        width: entriesListRoot.width
        theme: entriesListRoot.theme
        clipService: entriesListRoot.clipService
        rawEntryData: (typeof entryData !== "undefined") ? entryData : modelData
        isSelected: entriesListRoot.currentIndex === index
        onHovered: (yPos, itemH) => {
            entriesListRoot.currentIndex = index;
            entriesListRoot.hoverItem(index, yPos, itemH);
            entriesListRoot.forceActiveFocus();
        }
        onUnhovered: entriesListRoot.unhoverItem(index)
        onItemClicked: entriesListRoot.entryClicked(entryText)
        onPinRequested: entriesListRoot.pinClicked(entryText)
        onDeleteRequested: entriesListRoot.removeEntryOptimistically(index, entryText)
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_P) {
            if (currentIndex >= 0 && currentIndex < dynamicClipModel.count) {
                var pItem = dynamicClipModel.get(currentIndex);
                if (pItem) {
                    pinClicked(pItem.entryData || "");
                    event.accepted = true;
                }
            }
        } else if (event.key === Qt.Key_D || event.key === Qt.Key_Delete) {
            if (currentIndex >= 0 && currentIndex < dynamicClipModel.count) {
                var dItem = dynamicClipModel.get(currentIndex);
                if (dItem) {
                    removeEntryOptimistically(currentIndex, dItem.entryData || "");
                    event.accepted = true;
                }
            }
        }
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
