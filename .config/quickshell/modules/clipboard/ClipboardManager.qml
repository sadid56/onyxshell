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
        var rawQuery = searchQuery.trim();
        var lowerRaw = rawQuery.toLowerCase();

        // Check if searching for pinned items specifically (e.g. >pin, >p, or pin:)
        var isPinSearch = lowerRaw.startsWith(">pin") || lowerRaw.startsWith(">p") || lowerRaw.startsWith("pin:");
        var pinQuery = "";
        if (isPinSearch) {
            if (lowerRaw.startsWith(">pin")) pinQuery = lowerRaw.substring(4).trim();
            else if (lowerRaw.startsWith(">p")) pinQuery = lowerRaw.substring(2).trim();
            else if (lowerRaw.startsWith("pin:")) pinQuery = lowerRaw.substring(4).trim();
        }

        var source = clipService.entries;
        var scored = [];

        if (isPinSearch) {
            for (var k = 0; k < source.length; k++) {
                var pEntry = source[k];
                if (!clipService.isPinned(pEntry)) continue;

                var pClean = pEntry.substring(pEntry.indexOf("\t") + 1).toLowerCase();
                if (pinQuery === "" || pClean.indexOf(pinQuery) !== -1) {
                    scored.push({ entry: pEntry, score: 1000 - k });
                }
            }
            scored.sort((a, b) => b.score - a.score);
            var pinRes = [];
            for (var p = 0; p < scored.length; p++) {
                pinRes.push(scored[p].entry);
            }
            return pinRes;
        }

        if (rawQuery === "") {
            // Sort: All pinned entries first, then recent items
            var pinned = [];
            var unpinned = [];
            for (var i = 0; i < source.length; i++) {
                var e = source[i];
                if (clipService.isPinned(e)) pinned.push(e);
                else unpinned.push(e);
            }
            return pinned.concat(unpinned);
        }

        var query = lowerRaw;
        for (var j = 0; j < source.length; j++) {
            var entry = source[j];
            var cleanText = entry.substring(entry.indexOf("\t") + 1).toLowerCase();
            var isP = clipService.isPinned(entry);

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
                if (isP) score += 2000; // Pinned priority boost
                score += Math.max(0, 50 - Math.abs(cleanText.length - query.length)) + Math.max(0, 30 - j);
                scored.push({ entry: entry, score: score });
            }
        }

        scored.sort((a, b) => b.score - a.score);
        var res = [];
        for (var m = 0; m < scored.length; m++) {
            res.push(scored[m].entry);
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
            placeholder: "Search clipboard... (type >pin for pinned)"
            icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/search.svg")

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
                var ____ = clipService.pinnedEntries;
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

            onPinClicked: entryText => {
                clipWindow.clipService.togglePin(entryText);
            }

            onUpPressedAtStart: searchInput.forceFocus()
            onEscapePressed: clipWindow.active = false
        }
    }
}
