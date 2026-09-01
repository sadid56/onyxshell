import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: overviewService
    visible: false

    property var appService: null
    property var settingsService: null
    property var shellConfig: null

    property bool showAllWorkspaces: false
    property var systemAppsMap: ({})
    property var rawClients: []
    property var currentWorkspaceClients: []
    property var populatedWorkspaces: []
    property int currentWsId: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id : 1

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

                    var activeWs = overviewService.currentWsId;
                    var filtered = [];
                    var allWins = [];
                    var allWs = [];

                    for (var i = 0; i < parsed.length; i++) {
                        var c = parsed[i];
                        if (!c || c.hidden || c.mapped === false) continue;
                        var cls = (c.class || c.initialClass || "").toLowerCase();
                        var tit = (c.title || "").toLowerCase();
                        if (cls === "quickshell" || cls.indexOf("dropdown") !== -1 || tit.indexOf("dropdown") !== -1) continue;

                        var wsId = c.workspace ? c.workspace.id : 1;
                        if (allWs.indexOf(wsId) === -1) allWs.push(wsId);

                        var winObj = {
                            address: c.address || "",
                            title: c.title || c.class || "Window",
                            class: c.class || "",
                            initialClass: c.initialClass || "",
                            workspace: wsId,
                            icon: overviewService.getAppIcon(c.class, c.initialClass, c.title),
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

                    overviewService.rawClients = allWins;
                    overviewService.currentWorkspaceClients = overviewService.showAllWorkspaces ? allWins : filtered;
                    overviewService.populatedWorkspaces = allWs;
                } catch(e) {}
            }
        }
    }

    Timer {
        id: refreshDelayTimer
        interval: 150
        repeat: false
        onTriggered: overviewService.refreshClients()
    }

    function refreshClients() {
        clientsProc.running = false;
        clientsProc.running = true;
    }

    function buildAppsMap() {
        if (!appService || !appService.apps) return;
        var map = {};
        var list = appService.apps;
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
        var c = (cls || "").toLowerCase().trim();
        var init = (initCls || "").toLowerCase().trim();
        var t = (title || "").toLowerCase().trim();
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
        return shellConfig ? ("file://" + shellConfig.defaultAppIcon) : "";
    }

    function focusAndCloseWindow(client, onClosedCallback) {
        if (!client || !client.address) return;
        var addr = client.address;
        var wsId = (typeof client === "object") ? ((typeof client.workspace === "number") ? client.workspace : (client.workspace ? client.workspace.id : 0)) : 0;
        var isGrouped = client.isGrouped || (client.grouped && client.grouped.length > 1);
        var grpIdx = (isGrouped && Array.isArray(client.grouped)) ? client.grouped.indexOf(addr) : -1;

        if (typeof onClosedCallback === "function") {
            onClosedCallback();
        }

        var script = "local win = 'address:" + addr + "'\n";
        if (wsId > 0 && wsId !== overviewService.currentWsId) {
            script += "hl.dispatch(hl.dsp.focus({ workspace = " + wsId + " }))\n";
        }
        script += "hl.dispatch(hl.dsp.focus({ window = win }))\n";
        if (grpIdx >= 0) {
            script += "pcall(function() hl.dispatch(hl.dsp.group.active({ index = " + grpIdx + " })) end)\n";
        }
        script += "hl.dispatch(hl.dsp.window.bring_to_top({ window = win }))\n" +
                  "hl.dispatch(hl.dsp.window.alter_zorder({ mode = 'top', window = win }))\n" +
                  "return 'ok'";

        Quickshell.execDetached(["hyprctl", "eval", script]);
    }

    function closeTargetWindow(client) {
        if (!client) return;
        var addr = (typeof client === "object") ? client.address : client;
        if (!addr) return;

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

        var script = "return hl.dispatch(hl.dsp.window.close({ window = 'address:" + addr + "' }))";
        Quickshell.execDetached(["hyprctl", "eval", script]);

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

    function moveWindowToWorkspace(clientOrAddr, targetWs) {
        if (!clientOrAddr || !targetWs) return;
        var addr = (typeof clientOrAddr === "object") ? clientOrAddr.address : clientOrAddr;
        if (!addr) return;
        currentWsId = targetWs;
        var isGrp = (typeof clientOrAddr === "object") ? (clientOrAddr.isGrouped || (clientOrAddr.grouped && clientOrAddr.grouped.length > 1)) : false;

        var targetHasGroup = false;
        var targetGroupWin = "";
        for (var i = 0; i < rawClients.length; i++) {
            var c = rawClients[i];
            if (c && (c.workspace === targetWs || (c.workspace && c.workspace.id === targetWs)) && c.address !== addr) {
                if (c.isGrouped || (c.grouped && c.grouped.length > 1)) {
                    targetHasGroup = true;
                    targetGroupWin = c.address;
                    break;
                }
            }
        }

        var script = "local win = 'address:" + addr + "'\n" +
                     "hl.dispatch(hl.dsp.focus({ window = win }))\n";

        if (isGrp) {
            script += "pcall(function() hl.dispatch(hl.dsp.group.toggle({ window = win })) end)\n";
        }

        script += "hl.dispatch(hl.dsp.window.move({ workspace = " + targetWs + ", window = win }))\n";

        if (targetHasGroup && targetGroupWin) {
            script += "pcall(function()\n" +
                      "  local grpTarget = 'address:" + targetGroupWin + "'\n" +
                      "  hl.dispatch(hl.dsp.focus({ window = grpTarget }))\n" +
                      "  hl.dispatch(hl.dsp.focus({ window = win }))\n" +
                      "  hl.dispatch(hl.dsp.group.toggle({ window = win }))\n" +
                      "end)\n";
        }

        script += "return hl.dispatch(hl.dsp.focus({ workspace = " + targetWs + " }))";

        Quickshell.execDetached(["hyprctl", "eval", script]);
        refreshDelayTimer.restart();
    }
}
