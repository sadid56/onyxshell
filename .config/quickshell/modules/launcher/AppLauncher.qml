import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "./components"
import "../../components/containers"
import "../../components/ui" as UIInputs

Popup {
    id: launcherWindow

    popupWidth: 480
    popupHeight: Math.min(520, mainLayout.implicitHeight + 44)
    closeOnHoverOutside: false

    property string searchQuery: ""
    property var allApps: []

    function getFilteredApps() {
        if (searchQuery === "") return allApps;
        var scored = [];
        var query = searchQuery.trim().toLowerCase();

        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i];
            var name = app.name.toLowerCase();
            var comment = (app.comment || "").toLowerCase();
            var exec = (app.exec || "").toLowerCase();

            var score = 0;

            if (name === query) {
                score += 1000;
            } else if (name.indexOf(query) === 0) {
                score += 500;
            } else if (name.indexOf(" " + query) !== -1 || name.indexOf("-" + query) !== -1) {
                score += 300;
            } else if (name.indexOf(query) !== -1) {
                score += 150;
            } else if (exec.indexOf(query) !== -1) {
                score += 80;
            } else if (comment.indexOf(query) !== -1) {
                score += 40;
            }

            if (score > 0) {
                score += Math.max(0, 50 - Math.abs(name.length - query.length));
                scored.push({ app: app, score: score });
            }
        }

        scored.sort((a, b) => b.score - a.score);

        var res = [];
        for (var j = 0; j < scored.length; j++) {
            res.push(scored[j].app);
        }
        return res;
    }

    FileView {
        id: appsCacheFile
        path: "/tmp/quickshell_apps_cache.json"
        onLoaded: {
            if (launcherWindow.allApps.length === 0 && text) {
                try {
                    var parsed = JSON.parse(text.trim());
                    if (parsed && parsed.length > 0) {
                        launcherWindow.allApps = parsed;
                    }
                } catch(e) {}
            }
        }
    }

    onActiveChanged: {
        if (active) {
            searchInput.forceFocus();
            refreshApps();
        } else {
            searchInput.text = "";
            searchQuery = "";
        }
    }

    function refreshApps() {
        appsProc.running = false;
        appsProc.running = true;
    }

    property var appsProc: Process {
        id: appsProc
        command: ["python", shellConfig.getScript("list_apps.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var txt = this.text ? this.text.trim() : "";
                    if (txt === "") return;
                    var parsed = JSON.parse(txt);
                    if (parsed && parsed.length > 0) {
                        launcherWindow.allApps = parsed;
                    }
                } catch(e) {
                    console.error("Failed to parse applications JSON:", e);
                }
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        spacing: 12

        UIInputs.Input {
            id: searchInput
            theme: launcherWindow.theme
            placeholder: "Search applications..."
            icon: shellConfig.getIcon("search.svg")

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

        EmptyState {
            theme: launcherWindow.theme
            searchQuery: launcherWindow.searchQuery
            isLoading: appsProc.running && launcherWindow.allApps.length === 0
            visible: appList.count === 0
        }

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

    Component.onCompleted: refreshApps()
}
