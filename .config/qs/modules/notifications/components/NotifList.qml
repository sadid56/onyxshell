import QtQuick
import QtQuick.Layouts
import "../../../core"

ListView {
    id: appNotifsList
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 10
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 1600
    maximumFlickVelocity: 2800

    property var theme
    property var activeNotifsModel: []
    property var expandedGroupsMap: ({})

    function isGroupExpanded(gName) {
        if (expandedGroupsMap && expandedGroupsMap[gName] !== undefined) {
            return expandedGroupsMap[gName];
        }
        return false;
    }

    function setGroupExpanded(gName, exp) {
        var m = Object.assign({}, expandedGroupsMap);
        m[gName] = exp;
        expandedGroupsMap = m;
    }

    readonly property var groupedNotifs: {
        var source = activeNotifsModel || [];
        var groupsMap = {};
        var groupOrder = [];

        for (var i = 0; i < source.length; i++) {
            var n = source[i];
            if (!n) continue;
            var notifObj = n.trackedNotification || n;
            var app = notifObj.appName || notifObj.applicationName || "Other";
            var icon = notifObj.appIcon || notifObj.icon || "";
            var uid = notifObj._uid || (notifObj.id ? String(notifObj.id) : (notifObj.summary + "_" + notifObj.body + "_" + i));

            if (!groupsMap[app]) {
                groupsMap[app] = {
                    "appName": app,
                    "appIcon": icon,
                    "items": []
                };
                groupOrder.push(app);
            }
            if (icon && !groupsMap[app].appIcon) {
                groupsMap[app].appIcon = icon;
            }

            groupsMap[app].items.push({
                "notifId": uid,
                "summary": notifObj.summary || "Notification",
                "body": notifObj.body || "",
                "appName": app,
                "appIcon": icon,
                "rawNotif": notifObj
            });
        }

        var res = [];
        for (var j = 0; j < groupOrder.length; j++) {
            var gName = groupOrder[j];
            var grp = groupsMap[gName];
            res.push({
                "groupId": gName,
                "appName": grp.appName,
                "appIcon": grp.appIcon,
                "count": grp.items.length,
                "items": grp.items
            });
        }
        return res;
    }

    model: groupedNotifs

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

    NumberAnimation {
        id: smoothScrollAnim
        target: appNotifsList
        property: "contentY"
        duration: 220
        easing.type: Easing.OutCubic
    }

    delegate: NotifGroupCard {
        theme: appNotifsList.theme
        groupData: modelData
        parentList: appNotifsList
    }
}
