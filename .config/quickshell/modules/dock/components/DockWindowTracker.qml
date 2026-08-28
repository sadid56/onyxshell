import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: trackerRoot
    visible: false

    property var dockWindow
    property var systemAppsMap: ({})
    property var runningClients: []
    property var displayApps: []
    property bool wsHasWindowsState: false
    readonly property bool currentWorkspaceHasWindows: {
        var curId = (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id : 1;
        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            var tops = Hyprland.toplevels.values;
            for (var i = 0; i < tops.length; i++) {
                var t = tops[i];
                if (t && t.workspace && t.workspace.id === curId) {
                    var cls = (t.appId || t.className || "").toLowerCase();
                    var tit = (t.title || "").toLowerCase();
                    if (cls.indexOf("dropdown") !== -1 || tit.indexOf("dropdown") !== -1) continue;
                    return true;
                }
            }
            return false;
        }
        return wsHasWindowsState;
    }
    property string focusedClass: ""

    property var appService: (typeof root !== "undefined" && root.appService) ? root.appService : null
    onAppServiceChanged: {
        if (appService && appService.apps && appService.apps.length > 0) {
            buildSystemAppsMap(appService.apps);
        }
    }

    Connections {
        target: (dockWindow && dockWindow.settingsService) ? dockWindow.settingsService : (typeof root !== "undefined" ? root.settingsService : null)
        function onDockPinnedAppsChanged() {
            trackerRoot.rebuildDisplayApps();
        }
    }

    function buildSystemAppsMap(appsList) {
        if (!appsList || !Array.isArray(appsList)) return;
        var map = {};
        for (var i = 0; i < appsList.length; i++) {
            var a = appsList[i];
            if (!a || !a.icon) continue;
            var icon = a.icon;
            if (a.name) map[a.name.toLowerCase().trim()] = icon;
            if (a.desktopId) {
                var dId = a.desktopId.toLowerCase().trim();
                map[dId] = icon;
                var dBase = dId.split(".").pop().toLowerCase().trim();
                map[dBase] = icon;
            }
            if (a.rawIcon) {
                map[a.rawIcon.toLowerCase().trim()] = icon;
            }
            if (a.exec) {
                var execBase = a.exec.split(/\s/)[0].split("/").pop().toLowerCase().trim();
                map[execBase] = icon;
                map[a.exec.toLowerCase().trim()] = icon;
            }
        }
        trackerRoot.systemAppsMap = map;
        trackerRoot.refreshClients();
    }

    Connections {
        target: trackerRoot.appService
        function onAppsReloaded() {
            if (trackerRoot.appService && trackerRoot.appService.apps) {
                trackerRoot.buildSystemAppsMap(trackerRoot.appService.apps);
            }
        }
    }

    Component.onCompleted: {
        if (appService && appService.apps && appService.apps.length > 0) {
            buildSystemAppsMap(appService.apps);
        }
        rebuildDisplayApps();
        refreshClients();
    }

    function getDynamicAppIcon(cls, initCls, title) {
        var c = (cls || "").toLowerCase().trim();
        var init = (initCls || "").toLowerCase().trim();
        var t = (title || "").toLowerCase().trim();

        if (c && systemAppsMap[c]) return systemAppsMap[c];
        if (init && systemAppsMap[init]) return systemAppsMap[init];
        if (t && systemAppsMap[t]) return systemAppsMap[t];

        var cBase = c.split(".").pop().replace(/_app$/, "").replace(/-origin$/, "");
        if (cBase && systemAppsMap[cBase]) return systemAppsMap[cBase];
        var initBase = init.split(".").pop().replace(/_app$/, "").replace(/-origin$/, "");
        if (initBase && systemAppsMap[initBase]) return systemAppsMap[initBase];

        var cClean = c.replace(/[-_.]/g, "");
        for (var k in systemAppsMap) {
            if (!k || k.length < 3) continue;
            var kClean = k.replace(/[-_.]/g, "");
            if (cClean === kClean || (cClean.indexOf(kClean) !== -1 && kClean.length >= 4)) {
                return systemAppsMap[k];
            }
        }

        return ((typeof shellConfig !== "undefined" && shellConfig && shellConfig.defaultAppIcon)
            ? shellConfig.defaultAppIcon
            : (Quickshell.env("HOME") + "/.config/quickshell/assets/icons/system/default-app.svg"));
    }

    function areAppsEqual(a, b) {
        if (!a || !b) return false;
        if (a.length !== b.length) return false;
        for (var i = 0; i < a.length; i++) {
            if (a[i].name !== b[i].name || a[i].address !== b[i].address || a[i].windowCount !== b[i].windowCount || a[i].isRunning !== b[i].isRunning || a[i].icon !== b[i].icon) {
                return false;
            }
        }
        return true;
    }

    function cleanAppStr(s) {
        if (!s) return "";
        return String(s).toLowerCase().replace(/\.desktop$/i, "").replace(/[-_.]/g, "").trim();
    }

    function matchPinnedToClient(pin, client) {
        if (!pin || !client) return false;
        var pName = (pin.name || "").toLowerCase().trim();
        var pExec = (pin.exec || "").toLowerCase().trim();
        var pExecBase = pExec.split(/\s/)[0].split("/").pop().toLowerCase().trim();
        var pIcon = (pin.icon || "").toLowerCase().trim();
        var pIconBase = pIcon.split("/").pop().split(".")[0].toLowerCase().trim();
        var cCls = (client.className || "").toLowerCase().trim();
        var cInit = (client.initialClass || "").toLowerCase().trim();

        if (cCls.indexOf("dropdown") !== -1 || cInit.indexOf("dropdown") !== -1) return false;

        if (pName === cCls || pName === cInit) return true;
        if (pExecBase && (pExecBase === cCls || pExecBase === cInit)) return true;
        if (pIconBase && (pIconBase === cCls || pIconBase === cInit)) return true;

        var cpName = cleanAppStr(pName);
        var cpExec = cleanAppStr(pExecBase);
        var cpIcon = cleanAppStr(pIconBase);
        var ccCls = cleanAppStr(cCls);
        var ccInit = cleanAppStr(cInit);

        if (ccCls && (ccCls === cpName || ccCls === cpExec || ccCls === cpIcon)) return true;
        if (ccInit && (ccInit === cpName || ccInit === cpExec || ccInit === cpIcon)) return true;

        return false;
    }

    Process {
        id: clientProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var txt = this.text ? this.text.trim() : "";
                    if (!txt) return;
                    var raw = JSON.parse(txt);
                    if (!Array.isArray(raw)) return;

                    var activeWsId = (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id !== undefined)
                        ? Hyprland.focusedWorkspace.id : 1;

                    var focusedWin = Hyprland.focusedWindow;
                    var focusedAddress = focusedWin ? (focusedWin.address || "") : "";

                    var wsHasWindows = false;
                    var clientsMap = {};
                    var clientsList = [];

                    for (var i = 0; i < raw.length; i++) {
                        var c = raw[i];
                        if (!c || c.hidden || c.mapped === false) continue;
                        var cls = c.class || c.initialClass || "";
                        var initCls = c.initialClass || "";
                        var tit = c.title || "";
                        var wsName = (c.workspace && c.workspace.name) ? c.workspace.name : "";
                        if (!cls || cls.toLowerCase() === "quickshell") continue;
                        if (cls.toLowerCase().indexOf("dropdown") !== -1 || initCls.toLowerCase().indexOf("dropdown") !== -1) continue;
                        if (tit.toLowerCase().indexOf("dropdown") !== -1 || wsName.toLowerCase().indexOf("dropdown") !== -1) continue;

                        if (c.workspace && (c.workspace.id === activeWsId || c.workspace.id === undefined)) {
                            wsHasWindows = true;
                        }

                        var key = cls.toLowerCase();
                        var winObj = {
                            address: c.address || "", title: c.title || cls, className: cls, initialClass: c.initialClass || "",
                            workspace: c.workspace ? c.workspace.id : 1, isFocused: Boolean(c.focusHistoryID === 0 || (focusedAddress && c.address === focusedAddress)),
                            icon: trackerRoot.getDynamicAppIcon(cls, c.initialClass, c.title), pid: c.pid || 0
                        };

                        if (!clientsMap[key]) {
                            clientsMap[key] = {
                                name: cls, className: cls, initialClass: c.initialClass || "", icon: winObj.icon,
                                windows: [winObj], isFocused: winObj.isFocused, address: winObj.address, isRunning: true
                            };
                            clientsList.push(clientsMap[key]);
                        } else {
                            clientsMap[key].windows.push(winObj);
                            if (winObj.isFocused) {
                                clientsMap[key].isFocused = true;
                                clientsMap[key].address = winObj.address;
                            }
                        }
                    }

                    trackerRoot.wsHasWindowsState = wsHasWindows;
                    trackerRoot.runningClients = clientsList;
                    trackerRoot.rebuildDisplayApps();
                } catch(e) {}
            }
        }
    }

    function refreshClients() {
        if (!clientProc.running) {
            clientProc.running = true;
        }
    }

    function rebuildDisplayApps() {
        var svc = (dockWindow && dockWindow.settingsService) ? dockWindow.settingsService : (typeof root !== "undefined" ? root.settingsService : null);
        var pinned = (svc && svc.dockPinnedApps) ? svc.dockPinnedApps : [];

        var result = [];
        var matchedRunning = {};

        for (var p = 0; p < pinned.length; p++) {
            var pin = pinned[p];
            if (!pin || !pin.name) continue;

            var runningApp = null;
            for (var r = 0; r < runningClients.length; r++) {
                var cand = runningClients[r];
                if (matchPinnedToClient(pin, cand)) {
                    runningApp = cand;
                    matchedRunning[cand.className.toLowerCase()] = true;
                    break;
                }
            }

            result.push({
                name: pin.name, exec: pin.exec || pin.name,
                icon: pin.icon ? pin.icon : (runningApp ? runningApp.icon : trackerRoot.getDynamicAppIcon(pin.name, "", "")),
                isPinned: true, isRunning: Boolean(runningApp), isFocused: runningApp ? runningApp.isFocused : false,
                windowCount: runningApp ? runningApp.windows.length : 0, windows: runningApp ? runningApp.windows : [], address: runningApp ? runningApp.address : ""
            });
        }

        for (var c = 0; c < runningClients.length; c++) {
            var rc = runningClients[c];
            if (!matchedRunning[rc.className.toLowerCase()]) {
                result.push({
                    name: rc.name, exec: rc.className, icon: rc.icon, isPinned: false, isRunning: true,
                    isFocused: rc.isFocused, windowCount: rc.windows.length, windows: rc.windows, address: rc.address
                });
            }
        }

        if (!areAppsEqual(trackerRoot.displayApps, result)) {
            trackerRoot.displayApps = result;
        }
    }

    Timer {
        id: pollTimer
        interval: 1500
        repeat: true
        running: dockWindow && dockWindow.visible
        onTriggered: trackerRoot.refreshClients()
    }

    Connections {
        target: Hyprland
        function onRawEvent(name, data) {
            if (name === "openwindow" || name === "closewindow" || name === "movewindow" ||
                name === "activewindow" || name === "activewindowv2" || name === "workspace" ||
                name === "focusedmon" || name === "windowtitle") {
                trackerRoot.refreshClients();
            }
        }
    }
}
