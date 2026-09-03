import QtQuick
import Quickshell
import "../core"

Item {
    id: appService

    property Paths paths: Paths {}
    property var apps: []
    property var appsMap: ({})
    property bool isLoaded: false
    property bool isLoading: false

    signal appsReloaded()

    function reloadApps() {
        if (!DesktopEntries.applications || !DesktopEntries.applications.values) return;
        var list = DesktopEntries.applications.values;
        var result = [];

        for (var i = 0; i < list.length; i++) {
            var entry = list[i];
            if (!entry) continue;
            // Exclude hidden entries
            if (entry.noDisplay) continue;

            var name = entry.name ? entry.name.trim() : "";
            if (!name) continue;

            var dId = entry.id ? entry.id.trim() : "";
            var exec = entry.execString ? entry.execString.trim() : "";
            var rawIcon = entry.icon ? entry.icon.trim() : "";
            var resolvedIcon = "";
            if (rawIcon) {
                if (rawIcon.indexOf("/") === 0) {
                    resolvedIcon = "file://" + rawIcon;
                } else if (rawIcon.startsWith("file://") || rawIcon.startsWith("image://")) {
                    resolvedIcon = rawIcon;
                } else {
                    resolvedIcon = "image://icon/" + rawIcon;
                }
            }

            var comment = entry.comment ? entry.comment.trim() : (entry.genericName ? entry.genericName.trim() : "");
            var wmClass = entry.startupClass ? entry.startupClass.trim() : "";
            var cats = entry.categories ? Array.from(entry.categories) : ["Utilities"];

            result.push({
                desktopId: dId,
                name: name,
                exec: exec,
                icon: resolvedIcon,
                rawIcon: rawIcon,
                comment: comment,
                description: comment,
                wmClass: wmClass,
                categories: cats,
                entry: entry
            });
        }

        // Sort alphabetically by name
        result.sort(function(a, b) {
            return a.name.localeCompare(b.name, undefined, { sensitivity: "base" });
        });

        appService.apps = result;
        appService.buildAppsMap(result);
        appService.isLoaded = true;
        appService.isLoading = false;
        appService.appsReloaded();
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
        reloadApps();
    }

    function launchApp(app) {
        if (!app) return;
        if (app.entry && typeof app.entry.execute === "function") {
            app.entry.execute();
            return;
        }
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

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            appService.reloadApps();
        }
    }

    Component.onCompleted: {
        reloadApps();
    }
}
