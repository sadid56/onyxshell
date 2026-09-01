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

    readonly property int chromeHeight: 140
    readonly property int itemRowHeight: 52
    readonly property int maxVisibleItems: 8
    popupHeight: (allApps.length === 0)
        ? (chromeHeight + 5 * itemRowHeight)
        : (dynamicAppsModel.count === 0
            ? 310
            : (chromeHeight + Math.min(maxVisibleItems, dynamicAppsModel.count) * itemRowHeight))

    closeOnHoverOutside: false
    contentRectX: Math.round((safeWidth - popupWidth) / 2)

    property string searchQuery: ""
    property var appService: (typeof root !== "undefined" && root.appService) ? root.appService : null
    property var allApps: (appService && appService.apps && appService.apps.length > 0) ? appService.apps : []

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
                appsListView.currentIndex = -1;
                appsListView.currentIndex = 0;
                appsListView.hoverItem(0, 0, 52);
                Qt.callLater(() => {
                    if (appsListView && appsListView.count > 0) {
                        if (appsListView.currentIndex < 0) appsListView.currentIndex = 0;
                        appsListView.updateSelectionPill();
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

    Connections {
        target: appService
        function onAppsReloaded() {
            launcherWindow.updateAppsModel();
        }
    }

    function launchApp(app) {
        if (!app) return;
        launcherWindow.active = false;
        if (appService && typeof appService.launchApp === "function") {
            appService.launchApp(app);
        } else if (app.exec) {
            var cmd = app.exec.replace(/%[a-zA-Z]/g, "").trim();
            var tokens = cmd.match(/(?:[^\s"]+|"[^"]*")+/g) || [];
            tokens = tokens.map(t => t.replace(/^"|"$/g, ""));
            if (tokens.length > 0) {
                Quickshell.execDetached(tokens);
            }
        }
    }

    onActiveChanged: {
        if (active) {
            searchQuery = "";
            searchInput.text = "";
            if (appService && typeof appService.refresh === "function") {
                appService.refresh();
            }
            updateAppsModel();
            Qt.callLater(() => searchInput.forceFocus());
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: launcherWindow.active
        onActivated: launcherWindow.active = false
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
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            height: 1
            color: launcherWindow.theme ? launcherWindow.theme.getColor("outlineVariant") : "#20FFFFFF"
            opacity: 0.35
        }

        UI.SkeletonLoader {
            id: skeletonContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            theme: launcherWindow.theme
            count: 5
            itemHeight: 48
            itemRadius: 12
            iconSize: 34
            iconRadius: 9
            spacing: 4
            visible: launcherWindow.allApps.length === 0
        }

        UI.EmptyState {
            id: emptyState
            theme: launcherWindow.theme
            searchQuery: launcherWindow.searchQuery
            title: "No matching applications found"
            subtitle: "Try searching with a different keyword"
            visible: launcherWindow.allApps.length > 0 && dynamicAppsModel.count === 0
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: dynamicAppsModel.count > 0

            UI.AnimatedListView {
                id: appsListView
                anchors.fill: parent
                theme: launcherWindow.theme
                model: dynamicAppsModel
                spacing: 4
                pillMargin: 4
                pillRadius: 16
                pillColor: launcherWindow.theme ? launcherWindow.theme.getColor("secondaryContainer") : "#3d3a48"

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
    }
}
