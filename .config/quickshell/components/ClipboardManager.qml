import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./clipboardmanager"

PanelWindow {
    id: clipWindow
    
    // Spans the entire screen to capture clicks outside
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool active: false
    visible: active || hideTimer.running

    property var theme
    property var clipService

    property string searchQuery: ""
    
    function getFilteredEntries() {
        if (!clipService || !clipService.entries) return [];
        if (searchQuery === "") return clipService.entries;
        var arr = [];
        var query = searchQuery.toLowerCase();
        for (var i = 0; i < clipService.entries.length; i++) {
            var entry = clipService.entries[i];
            var cleanText = entry.substring(entry.indexOf("\t") + 1);
            if (cleanText.toLowerCase().indexOf(query) !== -1) {
                arr.push(entry);
            }
        }
        return arr;
    }

    onActiveChanged: {
        if (active) {
            searchInput.forceFocus();
            clipService.refresh();
        } else {
            hideTimer.start();
        }
    }

    Timer {
        id: hideTimer
        interval: 250
        running: false
        repeat: false
    }

    // Fullscreen MouseArea: clicking outside the centered rectangle closes the panel
    MouseArea {
        anchors.fill: parent
        onClicked: clipWindow.active = false
    }

    // Centered UI container with dynamic height transition matching AppLauncher
    Rectangle {
        id: contentRect
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 480
        height: Math.min(520, mainLayout.implicitHeight + 32)
        
        Behavior on height {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        radius: 16
        color: clipWindow.theme.getColor("surface")
        border.width: 0

        // Prevent clicks inside the container from closing the panel
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        opacity: clipWindow.active ? 1.0 : 0.0
        scale: clipWindow.active ? 1.0 : 0.97
        
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        
        transform: Translate {
            y: clipWindow.active ? 0 : -10
            Behavior on y {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
        }

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header Component
            Header {
                theme: clipWindow.theme
                
                onClearAllClicked: {
                    clipWindow.clipService.wipe();
                    clipWindow.active = false;
                }
            }

            // Search Bar Component
            SearchBar {
                id: searchInput
                theme: clipWindow.theme
                
                onTextChanged: clipWindow.searchQuery = text
                onEscapePressed: clipWindow.active = false
            }

            // Empty State Placeholder
            EmptyState {
                theme: clipWindow.theme
                searchQuery: clipWindow.searchQuery
                visible: entriesList.count === 0
            }

            // Clipboard History List
            EntriesList {
                id: entriesList
                theme: clipWindow.theme
                clipService: clipWindow.clipService
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
            }
        }
    }
}
