import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import "../../core"
import "../../components/containers"
import "../../components/ui" as UI
import "./components" as Components

Popup {
    id: launcherWindow

    popupWidth: 580

    readonly property int chromeHeight: 156
    readonly property int itemRowHeight: 52
    readonly property int maxVisibleItems: 6
    popupHeight: dynamicAppsModel.count === 0
        ? 240
        : (chromeHeight + Math.min(maxVisibleItems, dynamicAppsModel.count) * itemRowHeight)

    showCorners: false
    flatBottom: false
    closeOnHoverOutside: false

    contentRectX: Math.round((safeWidth - popupWidth) / 2)
    contentRectY: active ? Math.round((Screen.height - popupHeight) / 2) : Math.round((Screen.height - popupHeight) / 2 - 20)

    property string searchQuery: ""
    property var allApps: []

    ListModelUtils { id: modelUtils }

    ListModel {
        id: dynamicAppsModel
    }

    function getFilteredApps() {
        var baseList = allApps;
        if (!searchQuery || searchQuery.trim() === "") {
            return baseList;
        }

        var scored = [];
        var query = searchQuery.trim().toLowerCase();

        for (var i = 0; i < baseList.length; i++) {
            var app = baseList[i];
            var name = (app.name || "").toLowerCase();
            var comment = (app.comment || "").toLowerCase();
            var exec = (app.exec || "").toLowerCase();
            var execBase = exec.split(/\s/)[0].split("/").pop().split(".").pop().toLowerCase();

            var score = 0;
            if (name === query) {
                score = 10000;
            } else if (name.indexOf(query) === 0) {
                score = 5000;
            } else if (name.indexOf(" " + query) !== -1 || name.indexOf("-" + query) !== -1) {
                score = 2000;
            } else if (name.indexOf(query) !== -1) {
                score = 1000;
            } else if (execBase === query || execBase.indexOf(query) === 0) {
                score = 400;
            } else if (execBase.indexOf(query) !== -1) {
                score = 200;
            } else if (query.length >= 3 && comment.indexOf(query) !== -1) {
                score = 50;
            }

            if (score > 0) {
                var lengthBonus = Math.max(0, 20 - Math.abs(name.length - query.length));
                score += lengthBonus;
                scored.push({ app: app, score: score });
            }
        }

        scored.sort((x, y) => y.score - x.score);
        var res = [];
        for (var j = 0; j < scored.length; j++) {
            res.push(scored[j].app);
        }
        return res;
    }

    function updateAppsModel() {
        var filtered = getFilteredApps();
        modelUtils.syncListModel(dynamicAppsModel, filtered, "name", 0);
        if (appsListView) {
            if (dynamicAppsModel.count > 0) {
                appsListView.currentIndex = 0;
                appsListView.hoverItem(0, 0, 48);
                Qt.callLater(() => {
                    if (appsListView && appsListView.count > 0) {
                        appsListView.currentIndex = 0;
                        appsListView.hoverItem(0, 0, 48);
                    }
                });
            } else {
                appsListView.currentIndex = -1;
                appsListView.unhoverItem(0);
            }
        }
    }

    Timer {
        id: searchDebounceTimer
        interval: 35
        repeat: false
        onTriggered: updateAppsModel()
    }

    onSearchQueryChanged: searchDebounceTimer.restart()
    onAllAppsChanged: updateAppsModel()

    property var appsProc: Process {
        id: appsProc
        command: ["python", ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getScript("list_apps.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var txt = this.text ? this.text.trim() : "";
                    if (!txt) return;
                    var parsed = JSON.parse(txt);
                    if (parsed && parsed.length > 0) {
                        launcherWindow.allApps = parsed;
                    }
                } catch(e) {}
            }
        }
    }

    function refreshApps() {
        appsProc.running = false;
        appsProc.running = true;
    }

    function launchApp(app) {
        if (app && app.exec) {
            launcherWindow.active = false;
            var tokens = app.exec.split(/\s+/).filter(function(t) {
                return t.length > 0 && !t.startsWith("%");
            });
            if (tokens.length > 0) {
                Quickshell.execDetached(tokens);
            }
        }
    }

    function askConfirmation(options) {
        launcherWindow.active = false;
        if (typeof root !== "undefined" && typeof root.confirm === "function") {
            root.confirm(options);
        } else if (typeof popupManager !== "undefined" && popupManager.confirmationModal) {
            popupManager.confirmationModal.ask(options);
        }
    }

    function handlePowerAction(action) {
        if (action === "lock") {
            askConfirmation({
                title: "Lock Screen",
                message: "Are you sure you want to lock the screen?",
                icon: "system/lock-closed.svg",
                confirmText: "Lock",
                isDanger: false,
                onConfirm: () => {
                    var cfg = ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig);
                    var home = cfg ? cfg.homeDir : Quickshell.env("HOME");
                    Quickshell.execDetached(["sh", "-c", "pidof hyprlock || hyprlock -c " + home + "/.config/hypr/config/hyprlock.conf"]);
                }
            });
        } else if (action === "logout") {
            askConfirmation({
                title: "Log Out",
                message: "Are you sure you want to log out of your session?",
                icon: "system/logout.svg",
                confirmText: "Log Out",
                isDanger: false,
                onConfirm: () => {
                    Quickshell.execDetached(["sh", "-c", "hyprctl dispatch exit || loginctl terminate-user $USER || pkill -U $UID -9 -f Hyprland"]);
                }
            });
        } else if (action === "reboot") {
            askConfirmation({
                title: "Restart Computer",
                message: "Are you sure you want to restart your computer?",
                icon: "system/arrow-clockwise-filled.svg",
                confirmText: "Restart",
                isDanger: false,
                onConfirm: () => {
                    Quickshell.execDetached(["systemctl", "reboot"]);
                }
            });
        } else if (action === "shutdown") {
            askConfirmation({
                title: "Power Off",
                message: "Are you sure you want to power off the system?",
                icon: "system/power.svg",
                confirmText: "Power Off",
                isDanger: true,
                onConfirm: () => {
                    Quickshell.execDetached(["systemctl", "poweroff"]);
                }
            });
        }
    }

    onActiveChanged: {
        if (active) {
            refreshApps();
            searchQuery = "";
            searchInput.text = "";
            updateAppsModel();
            Qt.callLater(() => searchInput.forceFocus());
        }
    }

    Component.onCompleted: {
        refreshApps();
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8

        UI.Input {
            id: searchInput
            Layout.fillWidth: true
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            theme: launcherWindow.theme
            placeholder: "Search applications or commands..."
            icon: ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getIcon("actions/search.svg")

            onTextChanged: launcherWindow.searchQuery = text
            onEscapePressed: launcherWindow.active = false
            onReturnPressed: {
                if (dynamicAppsModel.count > 0) {
                    var targetIdx = (appsListView.currentIndex >= 0 && appsListView.currentIndex < dynamicAppsModel.count) ? appsListView.currentIndex : 0;
                    var app = dynamicAppsModel.get(targetIdx);
                    if (app) launcherWindow.launchApp(app);
                }
            }
            onDownPressed: {
                if (appsListView.count > 0) {
                    appsListView.currentIndex = Math.min(appsListView.count - 1, (appsListView.currentIndex < 0 ? 0 : appsListView.currentIndex + 1));
                }
            }
            onUpPressed: {
                if (appsListView.count > 0) {
                    appsListView.currentIndex = Math.max(0, appsListView.currentIndex - 1);
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: -2
            Layout.rightMargin: -2
            height: 1
            color: launcherWindow.theme ? launcherWindow.theme.getColor("outlineVariant") : "#20FFFFFF"
            opacity: 0.35
        }

        UI.EmptyState {
            id: emptyState
            theme: launcherWindow.theme
            searchQuery: launcherWindow.searchQuery
            title: launcherWindow.searchQuery === "" ? "No applications found" : "No matching applications found"
            subtitle: "Try searching with a different keyword"
            visible: dynamicAppsModel.count === 0
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 2
            Layout.bottomMargin: 4
            visible: dynamicAppsModel.count > 0

            UI.AnimatedListView {
                id: appsListView
                anchors.fill: parent
                theme: launcherWindow.theme
                model: dynamicAppsModel
                spacing: 4
                pillMargin: 0
                pillRadius: 12
                pillColor: launcherWindow.theme ? launcherWindow.theme.getColor("surfaceVariant") : "#322f37"

                delegate: Components.AppListItem {
                    width: appsListView.width
                    theme: launcherWindow.theme
                    appItem: model
                    isSelected: appsListView.currentIndex === index
                    onHovered: (yPos, itemH) => {
                        appsListView.currentIndex = index;
                        appsListView.hoverItem(index, yPos, itemH);
                    }
                    onUnhovered: appsListView.unhoverItem(index)
                    onClicked: launcherWindow.launchApp(model)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: -2
            Layout.rightMargin: -2
            height: 1
            color: launcherWindow.theme ? launcherWindow.theme.getColor("outlineVariant") : "#20FFFFFF"
            opacity: 0.35
            visible: dynamicAppsModel.count > 0
        }

        Components.LauncherFooter {
            theme: launcherWindow.theme
            appCount: dynamicAppsModel.count
            onPowerActionRequested: action => launcherWindow.handlePowerAction(action)
        }
    }
}
