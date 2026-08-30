import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: appService

    property var apps: []
    property var appsMap: ({})
    property bool isLoaded: false
    property bool isLoading: false

    signal appsReloaded()

    property var appsProc: Process {
        id: internalAppsProc
        command: ["python", ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig.getScript("list_apps.py") : (Quickshell.env("HOME") + "/.config/quickshell/scripts/list_apps.py"))]
        stdout: StdioCollector {
            onStreamFinished: {
                appService.isLoading = false;
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (Array.isArray(parsed)) {
                            var currentLen = appService.apps ? appService.apps.length : 0;
                            var changed = !appService.isLoaded || (currentLen !== parsed.length);
                            if (!changed && appService.apps) {
                                for (var i = 0; i < parsed.length; i++) {
                                    if (appService.apps[i].desktopId !== parsed[i].desktopId ||
                                        appService.apps[i].name !== parsed[i].name ||
                                        appService.apps[i].icon !== parsed[i].icon ||
                                        appService.apps[i].exec !== parsed[i].exec) {
                                        changed = true;
                                        break;
                                    }
                                }
                            }
                            if (changed) {
                                appService.apps = parsed;
                                appService.buildAppsMap(parsed);
                                appService.isLoaded = true;
                                appService.appsReloaded();
                            }
                        }
                    } catch(e) {}
                }
            }
        }
    }


    function buildAppsMap(list) {
        var map = {};
        for (var i = 0; i < list.length; i++) {
            var a = list[i];
            if (!a) continue;
            var dId = (a.desktopId || "").toLowerCase().trim();
            var name = (a.name || "").toLowerCase().trim();
            var exec = (a.exec || "").toLowerCase().trim();
            var execBase = exec.split(/\s+/)[0].split("/").pop().toLowerCase();

            if (dId) map[dId] = a;
            if (name && !map[name]) map[name] = a;
            if (execBase && !map[execBase]) map[execBase] = a;
        }
        appsMap = map;
    }

    function refresh() {
        if (isLoading) return;
        isLoading = true;
        internalAppsProc.running = false;
        internalAppsProc.running = true;
    }

    function launchApp(app) {
        if (!app) return;
        var execStr = typeof app === "string" ? app : (app.exec || "");
        if (!execStr) return;
        var cmd = execStr.replace(/%[a-zA-Z]/g, "").trim();
        var tokens = cmd.match(/(?:[^\s"]+|"[^"]*")+/g) || [];
        tokens = tokens.map(t => t.replace(/^"|"$/g, ""));
        if (tokens.length > 0) {
            Quickshell.execDetached(tokens);
        }
    }

    function findApp(str) {
        if (!str || !apps || apps.length === 0) return null;
        var key = String(str).toLowerCase().trim();
        if (appsMap && appsMap[key]) return appsMap[key];
        var cleanKey = key.replace(/\.desktop$/i, "").replace(/[\s\-_.]/g, "");
        for (var i = 0; i < apps.length; i++) {
            var a = apps[i];
            if (!a) continue;
            var dId = (a.desktopId || "").toLowerCase().replace(/\.desktop$/i, "").replace(/[\s\-_.]/g, "");
            var name = (a.name || "").toLowerCase().replace(/[\s\-_.]/g, "");
            var exec = (a.exec || "").toLowerCase().split(/\s+/)[0].split("/").pop().replace(/[\s\-_.]/g, "");
            if (dId === cleanKey || name === cleanKey || exec === cleanKey) return a;
        }
        return null;
    }

    Component.onCompleted: {
        refresh();
    }
}
