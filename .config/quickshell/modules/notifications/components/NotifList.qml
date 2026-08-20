import QtQuick
import QtQuick.Layouts
import "../../../core"

ListView {
    id: appNotifsList
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 8
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 1600
    maximumFlickVelocity: 2800

    property var theme
    property var activeNotifsModel: []
    property string expandedNotifId: ""

    ListModelUtils { id: modelUtils }

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
            smoothScrollAnim.stop();
            smoothScrollAnim.to = Math.max(0, appNotifsList.contentY + (cardBottom - viewBottom));
            smoothScrollAnim.start();
        } else if (itemY < appNotifsList.contentY) {
            smoothScrollAnim.stop();
            smoothScrollAnim.to = Math.max(0, itemY - 12);
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

    add: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
        }
    }

    remove: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0.0; duration: 160; easing.type: Easing.OutQuad }
            NumberAnimation { property: "scale"; to: 0.95; duration: 160; easing.type: Easing.OutCubic }
        }
    }

    move: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }
    moveDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }
    displaced: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }

    ListModel { id: dynamicNotifModel }
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
        modelUtils.syncListModel(dynamicNotifModel, buildSerializableNotifs(activeNotifsModel), "notifId", 50);
    }

    Component.onCompleted: {
        modelUtils.syncListModel(dynamicNotifModel, buildSerializableNotifs(activeNotifsModel), "notifId", 50);
    }

    delegate: NotifCard {
        theme: appNotifsList.theme
        notifItem: model
        parentList: appNotifsList
        expanded: appNotifsList.expandedNotifId === model.notifId
        onToggleExpandedRequested: {
            appNotifsList.expandedNotifId = (appNotifsList.expandedNotifId === model.notifId) ? "" : model.notifId;
        }
        onDismissRequested: {
            if (appNotifsList.expandedNotifId === model.notifId) appNotifsList.expandedNotifId = "";
            if (model.rawNotif && typeof model.rawNotif.dismiss === "function") model.rawNotif.dismiss();
        }
    }
}
