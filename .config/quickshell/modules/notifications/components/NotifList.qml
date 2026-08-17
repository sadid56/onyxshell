import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

UI.AnimatedListView {
    id: appNotifsList
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 8
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 1600
    maximumFlickVelocity: 2800

    property var activeNotifsModel: []

    WheelHandler {
        id: wheelHandler
        target: appNotifsList
        orientation: Qt.Vertical
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            var step = (event.angleDelta.y / 120) * 80;
            var newContentY = Math.max(0, Math.min(appNotifsList.contentHeight - appNotifsList.height, appNotifsList.contentY - step));
            smoothScrollAnim.to = newContentY;
            smoothScrollAnim.restart();
        }
    }

    function ensureVisible(itemY, itemHeight) {
        var cardBottom = itemY + itemHeight + 60;
        var viewBottom = appNotifsList.contentY + appNotifsList.height;

        if (cardBottom > viewBottom) {
            var diff = cardBottom - viewBottom;
            var targetY = Math.max(0, appNotifsList.contentY + diff);
            smoothScrollAnim.stop();
            smoothScrollAnim.to = targetY;
            smoothScrollAnim.start();
        } else if (itemY < appNotifsList.contentY) {
            var targetY = Math.max(0, itemY - 12);
            smoothScrollAnim.stop();
            smoothScrollAnim.to = targetY;
            smoothScrollAnim.start();
        }
    }

    NumberAnimation {
        id: smoothScrollAnim
        target: appNotifsList
        property: "contentY"
        duration: 220
        easing.type: Easing.OutCubic
    }

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

    Component.onCompleted: {
        var processed = buildSerializableNotifs(activeNotifsModel);
        syncListModel(dynamicNotifModel, processed, "notifId", 50);
    }

    property string expandedNotifId: ""

    delegate: NotifCard {
        theme: appNotifsList.theme
        notifItem: model
        parentList: appNotifsList
        expanded: appNotifsList.expandedNotifId === model.notifId
        onToggleExpandedRequested: {
            if (appNotifsList.expandedNotifId === model.notifId) {
                appNotifsList.expandedNotifId = "";
            } else {
                appNotifsList.expandedNotifId = model.notifId;
            }
        }
        onDismissRequested: {
            if (appNotifsList.expandedNotifId === model.notifId) {
                appNotifsList.expandedNotifId = "";
            }
            if (model.rawNotif && typeof model.rawNotif.dismiss === "function") {
                model.rawNotif.dismiss();
            }
        }
    }
}
