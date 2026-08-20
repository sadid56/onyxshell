import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./components"
import "../../components/containers"
import "../../components/ui" as UIInputs

Popup {
    id: clipWindow

    popupWidth: 480
    popupHeight: Math.min(520, mainLayout.implicitHeight + 48)
    closeOnHoverOutside: false

    property var clipService
    property string searchQuery: ""

    function getFilteredEntries() {
        if (!clipService || !clipService.entries) return [];
        if (searchQuery === "") return clipService.entries;
        var scored = [];
        var query = searchQuery.trim().toLowerCase();
        for (var i = 0; i < clipService.entries.length; i++) {
            var entry = clipService.entries[i];
            var cleanText = entry.substring(entry.indexOf("\t") + 1).toLowerCase();

            var score = 0;
            if (cleanText === query) {
                score += 1000;
            } else if (cleanText.indexOf(query) === 0) {
                score += 500;
            } else if (cleanText.indexOf(" " + query) !== -1) {
                score += 300;
            } else if (cleanText.indexOf(query) !== -1) {
                score += 150;
            }

            if (score > 0) {
                score += Math.max(0, 50 - Math.abs(cleanText.length - query.length)) + Math.max(0, 30 - i);
                scored.push({ entry: entry, score: score });
            }
        }

        scored.sort((a, b) => b.score - a.score);
        var res = [];
        for (var j = 0; j < scored.length; j++) {
            res.push(scored[j].entry);
        }
        return res;
    }

    onActiveChanged: {
        if (active) {
            searchInput.forceFocus();
            clipService.refresh();
        }
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        spacing: 12

        UIInputs.Input {
            id: searchInput
            theme: clipWindow.theme
            placeholder: "Search clipboard history..."
            icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("search.svg")

            onTextChanged: clipWindow.searchQuery = text
            onEscapePressed: clipWindow.active = false

            onDownPressed: {
                entriesList.focus = true;
                if (entriesList.count > 0) entriesList.currentIndex = 0;
            }

            onReturnPressed: {
                var filtered = clipWindow.getFilteredEntries();
                if (filtered.length > 0) {
                    var entry = filtered[0];
                    clipWindow.clipService.copyEntry(entry);
                    clipWindow.active = false;
                }
            }
        }

        EmptyState {
            theme: clipWindow.theme
            searchQuery: clipWindow.searchQuery
            visible: entriesList.count === 0
        }

        EntriesList {
            id: entriesList
            theme: clipWindow.theme
            clipService: clipWindow.clipService
            searchQuery: clipWindow.searchQuery
            entriesModel: {
                if (!clipService) return [];
                var _ = clipService.entries;
                var __ = searchQuery;
                var ___ = clipService.imagePreviews;
                return clipWindow.getFilteredEntries();
            }
            visible: entriesList.count > 0

            onEntryClicked: entryText => {
                clipWindow.clipService.copyEntry(entryText);
                clipWindow.active = false;
            }

            onDeleteClicked: entryText => {
                clipWindow.clipService.deleteEntry(entryText);
            }

            onUpPressedAtStart: searchInput.forceFocus()
            onEscapePressed: clipWindow.active = false
        }
    }

}
