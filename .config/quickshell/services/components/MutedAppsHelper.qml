import QtQuick

QtObject {
    id: mutedHelper

    function isAppMuted(app, mutedApps) {
        if (!app || !mutedApps || mutedApps.length === 0) return false;
        if (typeof app === "object") {
            if (app.appName && isAppMuted(app.appName, mutedApps)) return true;
            if (app.applicationName && isAppMuted(app.applicationName, mutedApps)) return true;
            if (app.desktopEntry && isAppMuted(app.desktopEntry, mutedApps)) return true;
            if (app.appIcon && isAppMuted(app.appIcon, mutedApps)) return true;
            if (app.icon && isAppMuted(app.icon, mutedApps)) return true;
            if (app.id && isAppMuted(app.id, mutedApps)) return true;
            if (app.name && isAppMuted(app.name, mutedApps)) return true;
            if (Array.isArray(app.aliases)) {
                for (var j = 0; j < app.aliases.length; j++) {
                    if (isAppMuted(app.aliases[j], mutedApps)) return true;
                }
            }
            return false;
        }

        var lower = String(app).toLowerCase().trim();
        if (!lower) return false;
        var clean = lower.replace(/\.desktop$/i, "").replace(/[_\-\s]+/g, "");

        for (var i = 0; i < mutedApps.length; i++) {
            var m = String(mutedApps[i]).toLowerCase().trim();
            if (!m) continue;
            var cleanM = m.replace(/\.desktop$/i, "").replace(/[_\-\s]+/g, "");
            if (m === lower || clean === cleanM) return true;
            if (cleanM.length >= 3 && clean.indexOf(cleanM) !== -1) return true;
            if (clean.length >= 3 && cleanM.indexOf(clean) !== -1) return true;
            if (lower.indexOf(m) !== -1 || m.indexOf(lower) !== -1) return true;
        }
        return false;
    }

    function computeMutedApps(app, isMuted, currentMuted) {
        if (!app) return currentMuted || [];
        var keys = [];
        if (typeof app === "object") {
            if (app.id) keys.push(app.id.toLowerCase().trim());
            if (app.name) keys.push(app.name.toLowerCase().trim());
            if (Array.isArray(app.aliases)) {
                for (var a = 0; a < app.aliases.length; a++) {
                    if (app.aliases[a]) keys.push(app.aliases[a].toLowerCase().trim());
                }
            }
        } else {
            keys.push(String(app).toLowerCase().trim());
        }

        var arr = currentMuted ? currentMuted.slice() : [];
        for (var k = 0; k < keys.length; k++) {
            var targetKey = keys[k];
            var idx = -1;
            for (var i = 0; i < arr.length; i++) {
                if (String(arr[i]).toLowerCase().trim() === targetKey) {
                    idx = i;
                    break;
                }
            }
            if (isMuted && idx === -1) arr.push(targetKey);
            else if (!isMuted && idx !== -1) arr.splice(idx, 1);
        }
        return arr;
    }
}
