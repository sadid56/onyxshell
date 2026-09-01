import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "./components"
import "../../components/ui" as UI

PanelWindow {
    id: overviewWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    property bool showAllWorkspaces: false
    visible: active

    property var theme: (typeof root !== "undefined" && root.rootTheme) ? root.rootTheme : null
    property var appService: (typeof root !== "undefined" && root.appService) ? root.appService : null
    property var settingsService: (typeof root !== "undefined" && root.settingsService) ? root.settingsService : null
    property var shellConfig: (typeof root !== "undefined" && root.shellConfig) ? root.shellConfig : null
    property int selectedIndex: -1
    property string searchQuery: ""

    readonly property int cornerRadius: (settingsService && settingsService.cornerRadius !== undefined) ? settingsService.cornerRadius : 20
    readonly property int gapsOut: (settingsService && settingsService.gapsOut !== undefined) ? settingsService.gapsOut : 8

    OverviewService {
        id: service
        appService: overviewWindow.appService
        settingsService: overviewWindow.settingsService
        shellConfig: overviewWindow.shellConfig
        showAllWorkspaces: overviewWindow.showAllWorkspaces
    }

    readonly property var displayedClients: {
        var baseList = [];
        var activeWs = service.currentWsId;
        if (overviewWindow.showAllWorkspaces) {
            baseList = service.rawClients;
        } else {
            for (var j = 0; j < service.rawClients.length; j++) {
                var item = service.rawClients[j];
                if (item && (item.workspace === activeWs || (item.workspace && item.workspace.id === activeWs))) {
                    baseList.push(item);
                }
            }
        }

        if (!overviewWindow.searchQuery || overviewWindow.searchQuery.trim() === "") return baseList;
        var q = overviewWindow.searchQuery.trim().toLowerCase();
        var res = [];
        for (var i = 0; i < baseList.length; i++) {
            var c = baseList[i];
            if (!c) continue;
            var tit = (c.title || "").toLowerCase();
            var cls = (c.class || "").toLowerCase();
            var initCls = (c.initialClass || "").toLowerCase();
            if (tit.indexOf(q) !== -1 || cls.indexOf(q) !== -1 || initCls.indexOf(q) !== -1) {
                res.push(c);
            }
        }
        return res;
    }

    function handleCardDrop(client, gx, gy) {
        var hoverWs = workspaceStrip.dragOverWs;
        var foundWs = workspaceStrip.findWorkspaceAt(gx, gy);
        var targetWs = hoverWs > 0 ? hoverWs : foundWs;
        workspaceStrip.clearDragHover();

        if (!client || !client.address) return;
        var clientWs = (typeof client.workspace === "number") ? client.workspace : (client.workspace ? client.workspace.id : 0);
        if (targetWs > 0 && targetWs !== clientWs) {
            service.moveWindowToWorkspace(client, targetWs);
        }
    }

    property string wallpaperPath: ""

    FileView {
        id: currentWallpaperFile
        path: (overviewWindow.shellConfig) ? (overviewWindow.shellConfig.quickshellDir + "/current_wallpaper") : ""
        watchChanges: true
        onTextChanged: {
            var txt = (typeof currentWallpaperFile.text === "function") ? currentWallpaperFile.text() : currentWallpaperFile.text;
            if (txt && txt.trim().length > 0) overviewWindow.wallpaperPath = txt.trim();
        }
    }

    Component.onCompleted: {
        var txt = (typeof currentWallpaperFile.text === "function") ? currentWallpaperFile.text() : currentWallpaperFile.text;
        if (txt && txt.trim().length > 0) overviewWindow.wallpaperPath = txt.trim();
        service.buildAppsMap();
        service.refreshClients();
    }

    Connections {
        target: overviewWindow.appService
        function onAppsReloaded() { service.buildAppsMap(); }
    }

    Connections {
        target: Hyprland
        function onRawEvent(name, data) {
            if (name === "workspace" || name === "workspacev2" || name === "focusedmon") {
                if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) {
                    service.currentWsId = Hyprland.focusedWorkspace.id;
                }
            }
            service.refreshClients();
        }
    }

    onActiveChanged: {
        if (active) {
            selectedIndex = -1;
            searchQuery = "";
            if (searchInput) searchInput.text = "";
            if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) {
                service.currentWsId = Hyprland.focusedWorkspace.id;
            }
            service.refreshClients();
            Qt.callLater(() => {
                if (searchInput) searchInput.forceFocus();
            });
        } else {
            showAllWorkspaces = false;
            searchQuery = "";
            selectedIndex = -1;
            if (searchInput) searchInput.text = "";
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: overviewWindow.active = false
    }

    Rectangle {
        id: backdropCard
        anchors.fill: parent
        color: "transparent"

        Image {
            anchors.fill: parent
            source: overviewWindow.wallpaperPath ? ("file://" + overviewWindow.wallpaperPath) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: true
            visible: overviewWindow.wallpaperPath !== ""
        }

        MouseArea { anchors.fill: parent; onClicked: overviewWindow.active = false }

        Item {
            id: keyHandler
            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: overviewWindow.active = false
            Keys.onReturnPressed: {
                if (overviewWindow.displayedClients.length > 0) {
                    var target = overviewWindow.displayedClients[Math.max(0, overviewWindow.selectedIndex)] || overviewWindow.displayedClients[0];
                    service.focusAndCloseWindow(target, () => { overviewWindow.active = false; });
                }
            }
            Keys.onRightPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = overviewWindow.selectedIndex < 0 ? 0 : ((overviewWindow.selectedIndex + 1) % overviewWindow.displayedClients.length)
            Keys.onLeftPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = overviewWindow.selectedIndex < 0 ? (overviewWindow.displayedClients.length - 1) : ((overviewWindow.selectedIndex - 1 + overviewWindow.displayedClients.length) % overviewWindow.displayedClients.length)
            Keys.onDownPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = overviewWindow.selectedIndex < 0 ? 0 : Math.min(overviewWindow.displayedClients.length - 1, overviewWindow.selectedIndex + overviewGrid.gridCols)
            Keys.onUpPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = overviewWindow.selectedIndex < 0 ? 0 : Math.max(0, overviewWindow.selectedIndex - overviewGrid.gridCols)
        }

        ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.topMargin: 56
            anchors.bottomMargin: 40
            anchors.leftMargin: 40
            anchors.rightMargin: 40
            spacing: 20

            WorkspaceStrip {
                id: workspaceStrip
                Layout.alignment: Qt.AlignHCenter
                visible: !overviewWindow.showAllWorkspaces
                Layout.preferredHeight: overviewWindow.showAllWorkspaces ? 0 : implicitHeight
                theme: overviewWindow.theme
                currentWsId: service.currentWsId
                populatedWorkspaces: service.populatedWorkspaces
                allClients: service.rawClients
                onSwitchWorkspace: wsId => service.switchWorkspaceAndRefresh(wsId)
                onMoveWindowToWorkspace: (address, wsId) => service.moveWindowToWorkspace(address, wsId)
            }

            UI.Input {
                id: searchInput
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: false
                Layout.preferredWidth: 360
                Layout.bottomMargin: 18
                width: 360
                height: 38
                implicitHeight: 38
                theme: overviewWindow.theme
                placeholder: overviewWindow.showAllWorkspaces ? "Search all windows..." : "Search windows..."
                icon: "actions/search.svg"

                onTextChanged: {
                    overviewWindow.searchQuery = text.trim().toLowerCase();
                    overviewWindow.selectedIndex = -1;
                }

                onEscapePressed: {
                    if (text.length > 0) {
                        text = "";
                    } else {
                        overviewWindow.active = false;
                    }
                }

                onReturnPressed: {
                    if (overviewWindow.displayedClients.length > 0) {
                        var target = overviewWindow.displayedClients[Math.max(0, overviewWindow.selectedIndex)] || overviewWindow.displayedClients[0];
                        service.focusAndCloseWindow(target, () => { overviewWindow.active = false; });
                    }
                }

                onRightPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = overviewWindow.selectedIndex < 0 ? 0 : ((overviewWindow.selectedIndex + 1) % overviewWindow.displayedClients.length)
                onLeftPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = overviewWindow.selectedIndex < 0 ? (overviewWindow.displayedClients.length - 1) : ((overviewWindow.selectedIndex - 1 + overviewWindow.displayedClients.length) % overviewWindow.displayedClients.length)
                onDownPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = overviewWindow.selectedIndex < 0 ? 0 : Math.min(overviewWindow.displayedClients.length - 1, overviewWindow.selectedIndex + overviewGrid.gridCols)
                onUpPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = overviewWindow.selectedIndex < 0 ? 0 : Math.max(0, overviewWindow.selectedIndex - overviewGrid.gridCols)
            }

            OverviewGrid {
                id: overviewGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                theme: overviewWindow.theme
                overviewActive: overviewWindow.active
                displayedClients: overviewWindow.displayedClients
                selectedIndex: overviewWindow.selectedIndex
                searchQuery: overviewWindow.searchQuery
                showAllWorkspaces: overviewWindow.showAllWorkspaces
                currentWsId: service.currentWsId
                availableWidth: backdropCard.width - 80

                onSelectWindow: client => service.focusAndCloseWindow(client, () => { overviewWindow.active = false; })
                onCloseWindow: client => service.closeTargetWindow(client)
                onDraggingAt: (gx, gy) => workspaceStrip.updateDragHover(gx, gy)
                onDroppedAt: (client, gx, gy) => overviewWindow.handleCardDrop(client, gx, gy)
            }
        }
    }
}
