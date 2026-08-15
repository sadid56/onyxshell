import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "./applauncher"

PanelWindow {
    id: launcherWindow
    
    // Spans the entire screen to capture clicks outside
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Ignore exclusive zone so we can overlay on top of everything
    exclusiveZone: 0

    // Theme passed from root
    property var theme
    property bool active: false
    property string searchQuery: ""
    property var allApps: []

    visible: active || contentRect.opacity > 0.0

    // Filtered application list based on search query
    function getFilteredApps() {
        if (searchQuery === "") return allApps;
        var arr = [];
        var query = searchQuery.toLowerCase();
        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i];
            if (app.name.toLowerCase().indexOf(query) !== -1 || 
                (app.comment && app.comment.toLowerCase().indexOf(query) !== -1)) {
                arr.push(app);
            }
        }
        return arr;
    }

    // Force focus to input and refresh application list when opened
    onActiveChanged: {
        if (active) {
            searchInput.forceFocus();
            refreshApps();
        } else {
            searchInput.text = "";
            searchQuery = "";
        }
    }

    // Run python script to list all desktop apps
    function refreshApps() {
        appsProc.running = false;
        appsProc.running = true;
    }

    property var appsProc: Process {
        id: appsProc
        command: ["python", "/home/sadid/.config/quickshell/scripts/list_apps.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text);
                    if (parsed && parsed.length > 0) {
                        launcherWindow.allApps = parsed;
                    }
                } catch(e) {
                    console.error("Failed to parse applications JSON:", e);
                }
            }
        }
    }

    // Fullscreen MouseArea: clicking outside the centered launcher rectangle closes it
    MouseArea {
        anchors.fill: parent
        onClicked: launcherWindow.active = false
    }

    // Centered UI container
    Rectangle {
        id: contentRect
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 480
        height: Math.min(520, mainLayout.implicitHeight + 32)
        radius: 16
        
        Behavior on height {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        color: launcherWindow.theme.getColor("surface")
        border.width: 0

        // Prevent clicks inside the container from closing the launcher
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        opacity: launcherWindow.active ? 1.0 : 0.0
        scale: launcherWindow.active ? 1.0 : 0.97
        
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        
        transform: Translate {
            y: launcherWindow.active ? 0 : -10
            Behavior on y {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
        }

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Search Bar Component
            SearchBar {
                id: searchInput
                theme: launcherWindow.theme
                
                onTextChanged: launcherWindow.searchQuery = text
                
                onEscapePressed: launcherWindow.active = false
                
                onDownPressed: {
                    appList.focus = true;
                    if (appList.count > 0) appList.currentIndex = 0;
                }
                
                onReturnPressed: {
                    var filtered = launcherWindow.getFilteredApps();
                    if (filtered.length > 0) {
                        var app = filtered[0];
                        if (app && app.exec) {
                            Quickshell.execDetached(app.exec.split(/\s+/));
                            launcherWindow.active = false;
                        }
                    }
                }
            }

            // Empty State Placeholder
            EmptyState {
                theme: launcherWindow.theme
                searchQuery: launcherWindow.searchQuery
                visible: appList.count === 0
            }

            // App List Component
            AppList {
                id: appList
                theme: launcherWindow.theme
                appsModel: launcherWindow.getFilteredApps()
                visible: appList.count > 0
                
                onAppClicked: app => {
                    if (app && app.exec) {
                        Quickshell.execDetached(app.exec.split(/\s+/));
                        launcherWindow.active = false;
                    }
                }
                
                onUpPressedAtStart: searchInput.forceFocus()
                onEscapePressed: launcherWindow.active = false
            }
        }
    }

    Component.onCompleted: refreshApps()
}
