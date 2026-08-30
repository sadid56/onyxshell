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
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    property bool showAllWorkspaces: false
    visible: active || backdropCard.opacity > 0.0

    property var theme: (typeof root !== "undefined" && root.rootTheme) ? root.rootTheme : null
    property var appService: (typeof root !== "undefined" && root.appService) ? root.appService : null
    property var settingsService: (typeof root !== "undefined" && root.settingsService) ? root.settingsService : null
    property var systemAppsMap: ({})
    property var rawClients: []
    property var currentWorkspaceClients: []
    property var populatedWorkspaces: []
    property int selectedIndex: 0
    property int currentWsId: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id : 1

    readonly property int cornerRadius: (settingsService && settingsService.cornerRadius !== undefined) ? settingsService.cornerRadius : 20
    readonly property int gapsOut: (settingsService && settingsService.gapsOut !== undefined) ? settingsService.gapsOut : 8

    property var clientsProc: Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var txt = this.text ? this.text.trim() : "";
                    if (!txt) return;
                    var parsed = JSON.parse(txt);
                    if (!Array.isArray(parsed)) return;

                    var activeWs = overviewWindow.currentWsId, filtered = [], allWins = [], allWs = [];
                    for (var i = 0; i < parsed.length; i++) {
                        var c = parsed[i];
                        if (!c || c.hidden || c.mapped === false) continue;
                        var cls = (c.class || c.initialClass || "").toLowerCase(), tit = (c.title || "").toLowerCase();
                        if (cls === "quickshell" || cls.indexOf("dropdown") !== -1 || tit.indexOf("dropdown") !== -1) continue;

                        var wsId = c.workspace ? c.workspace.id : 1;
                        if (allWs.indexOf(wsId) === -1) allWs.push(wsId);

                        var winObj = {
                            address: c.address || "",
                            title: c.title || c.class || "Window",
                            class: c.class || "",
                            initialClass: c.initialClass || "",
                            workspace: wsId,
                            icon: overviewWindow.getAppIcon(c.class, c.initialClass, c.title),
                            focusHistoryID: c.focusHistoryID || 0,
                            grouped: c.grouped || [],
                            isGrouped: Boolean(c.grouped && c.grouped.length > 1),
                            at: c.at || [100, 100],
                            size: c.size || [800, 600]
                        };
                        allWins.push(winObj);
                        if (wsId === activeWs) filtered.push(winObj);
                    }
                    filtered.sort((a, b) => (a.focusHistoryID || 0) - (b.focusHistoryID || 0));
                    allWins.sort((a, b) => (a.focusHistoryID || 0) - (b.focusHistoryID || 0));
                    overviewWindow.rawClients = allWins;
                    overviewWindow.currentWorkspaceClients = overviewWindow.showAllWorkspaces ? allWins : filtered;
                    overviewWindow.populatedWorkspaces = allWs;
                    var targetList = overviewWindow.currentWorkspaceClients;
                    if (overviewWindow.selectedIndex >= targetList.length) overviewWindow.selectedIndex = Math.max(0, targetList.length - 1);
                } catch(e) {}
            }
        }
    }

    function refreshClients() {
        clientsProc.running = false;
        clientsProc.running = true;
    }

    function buildAppsMap() {
        if (!appService || !appService.apps) return;
        var map = {}, list = appService.apps;
        for (var i = 0; i < list.length; i++) {
            var a = list[i];
            if (!a || !a.icon) continue;
            var icon = a.icon;
            if (a.name) {
                map[a.name.toLowerCase().trim()] = icon;
                var cleanName = a.name.toLowerCase().replace(/\s*\([^)]*\)/g, "").trim();
                if (cleanName) map[cleanName] = icon;
            }
            if (a.desktopId) {
                var dBase = a.desktopId.split(".").pop().toLowerCase().trim();
                map[dBase] = icon;
                var cleanId = dBase.replace(/-(launcher|bin|desktop|gtk|qt)$/i, "").trim();
                if (cleanId) map[cleanId] = icon;
            }
            if (a.wmClass) map[a.wmClass.toLowerCase().trim()] = icon;
            if (a.rawIcon) map[a.rawIcon.toLowerCase().trim()] = icon;
            if (a.exec) {
                var execBase = a.exec.split(/\s/)[0].split("/").pop().toLowerCase().trim();
                map[execBase] = icon;
                var cleanExec = execBase.replace(/-(launcher|bin|desktop|gtk|qt)$/i, "").trim();
                if (cleanExec) map[cleanExec] = icon;
            }
        }
        systemAppsMap = map;
    }

    function getAppIcon(cls, initCls, title) {
        var c = (cls || "").toLowerCase().trim(), init = (initCls || "").toLowerCase().trim(), t = (title || "").toLowerCase().trim();
        if (c && systemAppsMap[c]) return systemAppsMap[c];
        if (init && systemAppsMap[init]) return systemAppsMap[init];
        if (t && systemAppsMap[t]) return systemAppsMap[t];

        var cBase = c.split(".").pop().replace(/_app$/, "").replace(/-origin$/, "").replace(/-(launcher|bin|desktop)$/i, "");
        if (cBase && systemAppsMap[cBase]) return systemAppsMap[cBase];

        var cClean = c.replace(/[-_.]/g, "");
        for (var k in systemAppsMap) {
            if (!k || k.length < 3) continue;
            var kClean = k.replace(/[-_.]/g, "");
            if (cClean === kClean || (cClean.indexOf(kClean) !== -1 && kClean.length >= 4) || (kClean.indexOf(cClean) !== -1 && cClean.length >= 4)) {
                return systemAppsMap[k];
            }
        }
        var cfg = ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : (typeof root !== "undefined" ? root.shellConfig : null));
        return cfg ? ("file://" + cfg.defaultAppIcon) : "";
    }

    Component.onCompleted: {
        buildAppsMap();
        refreshClients();
    }

    Connections { target: appService; function onAppsReloaded() { overviewWindow.buildAppsMap(); } }
    Connections {
        target: Hyprland
        function onRawEvent(name, data) {
            if (name === "workspace" || name === "focusedmon") {
                if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) {
                    overviewWindow.currentWsId = Hyprland.focusedWorkspace.id;
                }
            }
            overviewWindow.refreshClients();
        }
    }

    onActiveChanged: {
        if (active) {
            selectedIndex = 0;
            searchQuery = "";
            if (searchInput) searchInput.text = "";
            if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) {
                currentWsId = Hyprland.focusedWorkspace.id;
            }
            refreshClients();
            Qt.callLater(() => {
                if (searchInput) searchInput.forceFocus();
            });
        }
    }

    function focusAndCloseWindow(client) {
        if (!client || !client.address) return;
        var addr = client.address;
        var wsId = (client.workspace !== undefined) ? client.workspace : 0;
        var grpIdx = (client.grouped && client.grouped.length > 1) ? (client.grouped.indexOf(addr) + 1) : 0;

        overviewWindow.active = false;

        focusDelayTimer.targetAddr = addr;
        focusDelayTimer.targetWsId = wsId;
        focusDelayTimer.targetGrpIdx = grpIdx;
        focusDelayTimer.restart();
    }

    Timer {
        id: focusDelayTimer
        interval: 40
        repeat: false
        property string targetAddr: ""
        property int targetWsId: 0
        property int targetGrpIdx: 0
        onTriggered: {
            if (!targetAddr) return;
            var script = "";
            if (targetWsId > 0) {
                script += "hl.dispatch(hl.dsp.focus({ workspace = " + targetWsId + " }))\n";
            }
            if (targetGrpIdx > 0) {
                script += "hl.dispatch(hl.dsp.focus({ window = 'address:" + targetAddr + "' }))\n";
                script += "hl.dispatch(hl.dsp.group.active({ index = " + targetGrpIdx + " }))\n";
            }
            script += "hl.dispatch(hl.dsp.focus({ window = 'address:" + targetAddr + "' }))\n";
            script += "hl.dispatch(hl.dsp.window.bring_to_top({ window = 'address:" + targetAddr + "' }))\n";
            script += "hl.dispatch(hl.dsp.window.alter_zorder({ mode = 'top', window = 'address:" + targetAddr + "' }))";

            Quickshell.execDetached(["hyprctl", "eval", script]);
            targetAddr = "";
            targetWsId = 0;
            targetGrpIdx = 0;
        }
    }

    function closeTargetWindow(client) {
        if (!client || !client.address) return;
        var addr = client.address;

        // 1. Optimistically remove from current lists so UI updates instantly
        var newRaw = [];
        for (var i = 0; i < rawClients.length; i++) {
            if (rawClients[i].address !== addr) newRaw.push(rawClients[i]);
        }
        rawClients = newRaw;

        var newCurrent = [];
        for (var j = 0; j < currentWorkspaceClients.length; j++) {
            if (currentWorkspaceClients[j].address !== addr) newCurrent.push(currentWorkspaceClients[j]);
        }
        currentWorkspaceClients = newCurrent;

        // 2. Dispatch Hyprland Lua window.close
        var script = "return hl.dispatch(hl.dsp.window.close({ window = 'address:" + addr + "' }))";
        Quickshell.execDetached(["hyprctl", "eval", script]);

        // 3. Delayed sync
        refreshDelayTimer.restart();
    }

    function switchWorkspaceAndRefresh(wsId) {
        currentWsId = wsId;
        Quickshell.execDetached([
            "hyprctl", "eval",
            "return hl.dispatch(hl.dsp.focus({ workspace = " + wsId + " }))"
        ]);
        refreshClients();
    }

    function moveWindowToWorkspace(client, targetWs) {
        if (!client || !client.address || !targetWs) return;
        var addr = client.address;
        currentWsId = targetWs;
        if (client.isGrouped || (client.grouped && client.grouped.length > 1)) {
            Quickshell.execDetached([
                "hyprctl", "eval",
                "pcall(function()\n" +
                "  hl.dispatch(hl.dsp.focus({ window = 'address:" + addr + "' }))\n" +
                "  hl.dispatch(hl.dsp.group.toggle())\n" +
                "end)\n" +
                "hl.dispatch(hl.dsp.window.move({ workspace = " + targetWs + ", silent = true, window = 'address:" + addr + "' }))\n" +
                "return hl.dispatch(hl.dsp.focus({ workspace = " + targetWs + " }))"
            ]);
        } else {
            Quickshell.execDetached([
                "hyprctl", "eval",
                "hl.dispatch(hl.dsp.window.move({ workspace = " + targetWs + ", silent = true, window = 'address:" + addr + "' }))\n" +
                "return hl.dispatch(hl.dsp.focus({ workspace = " + targetWs + " }))"
            ]);
        }
        refreshDelayTimer.restart();
    }

    Timer {
        id: refreshDelayTimer
        interval: 150
        repeat: false
        onTriggered: overviewWindow.refreshClients()
    }

    function handleCardDrop(client, gx, gy) {
        var targetWs = workspaceStrip.dragOverWs > 0 ? workspaceStrip.dragOverWs : workspaceStrip.findWorkspaceAt(gx, gy);
        workspaceStrip.clearDragHover();
        if (!client || !client.address) return;
        if (targetWs > 0 && targetWs !== overviewWindow.currentWsId) {
            overviewWindow.moveWindowToWorkspace(client, targetWs);
        }
    }

    property string searchQuery: ""

    readonly property var displayedClients: {
        var baseList = overviewWindow.showAllWorkspaces ? overviewWindow.rawClients : overviewWindow.currentWorkspaceClients;
        if (!searchQuery || searchQuery.trim() === "") return baseList;
        var q = searchQuery.trim().toLowerCase();
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

    readonly property var currentBaseList: overviewWindow.showAllWorkspaces ? overviewWindow.rawClients : overviewWindow.currentWorkspaceClients

    readonly property int gridCols: {
        var c = displayedClients.length;
        if (c <= 1) return 1;
        if (c === 2) return 2;
        if (c === 3) return 3;
        if (c === 4) return 2;
        if (c <= 6) return 3;
        return 4;
    }

    readonly property real cardW: {
        var c = displayedClients.length;
        var maxW = (backdropCard.width > 0 ? backdropCard.width : 1900) - 120;
        if (c <= 1) return Math.min(880, maxW * 0.60);
        if (c === 2) return Math.min(620, (maxW - 40) / 2);
        if (c === 3) return Math.min(480, (maxW - 60) / 3);
        if (c === 4) return Math.min(560, (maxW - 40) / 2);
        if (c <= 6) return Math.min(480, (maxW - 60) / 3);
        return Math.min(380, (maxW - 80) / 4);
    }

    readonly property real cardH: Math.round((cardW - 16) * 0.5625 + 44)

    MouseArea {
        anchors.fill: parent
        onClicked: overviewWindow.active = false
    }

    Rectangle {
        id: backdropCard
        anchors {
            top: parent.top; bottom: parent.bottom; left: parent.left; right: parent.right
            topMargin: overviewWindow.gapsOut; bottomMargin: overviewWindow.gapsOut
            leftMargin: overviewWindow.gapsOut; rightMargin: overviewWindow.gapsOut
        }
        radius: overviewWindow.cornerRadius
        color: overviewWindow.theme ? Qt.alpha(overviewWindow.theme.getColor("surface"), 0.72) : "#ba181418"
        border.width: 1
        border.color: overviewWindow.theme ? Qt.alpha(overviewWindow.theme.getColor("outlineVariant"), 0.40) : "#50453636"
        opacity: overviewWindow.active ? 1.0 : 0.0

        layer.enabled: overviewWindow.active
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#70000000"; shadowBlur: 0.8; shadowVerticalOffset: 8 }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

        MouseArea { anchors.fill: parent; onClicked: overviewWindow.active = false }

        Item {
            id: keyHandler
            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: overviewWindow.active = false
            Keys.onReturnPressed: {
                if (overviewWindow.currentWorkspaceClients.length > 0) {
                    var target = overviewWindow.currentWorkspaceClients[overviewWindow.selectedIndex] || overviewWindow.currentWorkspaceClients[0];
                    overviewWindow.focusAndCloseWindow(target);
                }
            }
            Keys.onRightPressed: if (overviewWindow.currentWorkspaceClients.length > 0) overviewWindow.selectedIndex = (overviewWindow.selectedIndex + 1) % overviewWindow.currentWorkspaceClients.length
            Keys.onLeftPressed: if (overviewWindow.currentWorkspaceClients.length > 0) overviewWindow.selectedIndex = (overviewWindow.selectedIndex - 1 + overviewWindow.currentWorkspaceClients.length) % overviewWindow.currentWorkspaceClients.length
            Keys.onDownPressed: if (overviewWindow.currentWorkspaceClients.length > 0) overviewWindow.selectedIndex = Math.min(overviewWindow.currentWorkspaceClients.length - 1, overviewWindow.selectedIndex + overviewWindow.gridCols)
            Keys.onUpPressed: if (overviewWindow.currentWorkspaceClients.length > 0) overviewWindow.selectedIndex = Math.max(0, overviewWindow.selectedIndex - overviewWindow.gridCols)
        }

        ColumnLayout {
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
                currentWsId: overviewWindow.currentWsId
                populatedWorkspaces: overviewWindow.populatedWorkspaces
                allClients: overviewWindow.rawClients
                onSwitchWorkspace: wsId => overviewWindow.switchWorkspaceAndRefresh(wsId)
                onMoveWindowToWorkspace: (address, wsId) => overviewWindow.moveWindowToWorkspace(address, wsId)
                opacity: (overviewWindow.active && !overviewWindow.showAllWorkspaces) ? 1.0 : 0.0

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
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
                opacity: overviewWindow.active ? 1.0 : 0.0

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

                onTextChanged: {
                    overviewWindow.searchQuery = text.trim().toLowerCase();
                    overviewWindow.selectedIndex = 0;
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
                        var target = overviewWindow.displayedClients[overviewWindow.selectedIndex] || overviewWindow.displayedClients[0];
                        overviewWindow.focusAndCloseWindow(target);
                    }
                }

                onRightPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = (overviewWindow.selectedIndex + 1) % overviewWindow.displayedClients.length
                onLeftPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = (overviewWindow.selectedIndex - 1 + overviewWindow.displayedClients.length) % overviewWindow.displayedClients.length
                onDownPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = Math.min(overviewWindow.displayedClients.length - 1, overviewWindow.selectedIndex + overviewWindow.gridCols)
                onUpPressed: if (overviewWindow.displayedClients.length > 0) overviewWindow.selectedIndex = Math.max(0, overviewWindow.selectedIndex - overviewWindow.gridCols)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: overviewWindow.displayedClients.length === 0
                    opacity: overviewWindow.active ? 1.0 : 0.0

                    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

                    UI.Typography {
                        Layout.alignment: Qt.AlignHCenter
                        theme: overviewWindow.theme
                        variant: "headlineSmall"
                        font.bold: true
                        text: overviewWindow.searchQuery.length > 0 ? "No matching windows found" : (overviewWindow.showAllWorkspaces ? "No open windows" : ("No open windows on Workspace " + overviewWindow.currentWsId))
                        colorRole: "onSurface"
                    }
                    UI.Typography {
                        Layout.alignment: Qt.AlignHCenter
                        theme: overviewWindow.theme
                        variant: "bodyMedium"
                        text: overviewWindow.searchQuery.length > 0 ? "Try searching with a different window title or class" : (overviewWindow.showAllWorkspaces ? "Launch an application to see it here" : "Drag a window here or select another workspace from above")
                        colorRole: "onSurfaceVariant"
                    }
                }

                Flickable {
                    id: gridFlickable
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: Math.max(height, gridContainer.height)
                    clip: false
                    visible: overviewWindow.displayedClients.length > 0

                    Item {
                        id: gridContainer
                        anchors.centerIn: parent
                        width: gridFlow.implicitWidth
                        height: gridFlow.implicitHeight

                        Grid {
                            id: gridFlow
                            anchors.centerIn: parent
                            columns: overviewWindow.gridCols
                            columnSpacing: 24
                            rowSpacing: 24

                            Repeater {
                                model: overviewWindow.displayedClients
                                delegate: OverviewCard {
                                    width: overviewWindow.cardW
                                    height: overviewWindow.cardH
                                    theme: overviewWindow.theme
                                    clientData: modelData
                                    isSelected: index === overviewWindow.selectedIndex
                                    onSelectWindow: overviewWindow.focusAndCloseWindow(modelData)
                                    onCloseWindow: overviewWindow.closeTargetWindow(modelData)
                                    onDraggingAt: (gx, gy) => workspaceStrip.updateDragHover(gx, gy)
                                    onDroppedAt: (gx, gy) => overviewWindow.handleCardDrop(modelData, gx, gy)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
