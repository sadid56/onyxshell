import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

UI.AnimatedListView {
    id: appNotifsList
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 8
    clip: true

    property var theme
    property var activeNotifsModel: []

    ListModel {
        id: dynamicNotifModel
    }

    model: dynamicNotifModel

    function buildSerializableNotifs(source) {
        if (!source) return [];
        var res = [];
        for (var i = 0; i < source.length; i++) {
            var n = source[i];
            if (!n) continue;
            var notifObj = n.trackedNotification || n;
            var uid = notifObj._uid || (notifObj.id ? String(notifObj.id) : (notifObj.summary + "_" + notifObj.body + "_" + i));
            res.push({
                "notifId": uid,
                "summary": notifObj.summary || "Notification",
                "body": notifObj.body || "",
                "appName": notifObj.appName || notifObj.applicationName || "",
                "appIcon": notifObj.appIcon || notifObj.icon || "",
                "rawNotif": notifObj
            });
        }
        return res;
    }

    onActiveNotifsModelChanged: {
        var processed = buildSerializableNotifs(activeNotifsModel);
        syncListModel(dynamicNotifModel, processed, "notifId", 50);
    }

    delegate: NotifCard {
        theme: appNotifsList.theme
        notifItem: model
        parentList: appNotifsList
        onDismissRequested: {
            if (model.rawNotif && typeof model.rawNotif.dismiss === "function") {
                model.rawNotif.dismiss();
            }
        }
    }
}
