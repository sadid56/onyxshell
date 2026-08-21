import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

ColumnLayout {
    id: notifSectionRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 12

    property var theme
    readonly property var activeNotifs: (typeof notifWindow !== "undefined" && notifWindow.activeNotifs) ? notifWindow.activeNotifs : ((typeof root !== "undefined" && root.activeNotifs) ? root.activeNotifs : [])

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "Notifications"
            font.family: "Noto Sans"
            font.pixelSize: 15
            font.bold: true
            color: notifSectionRoot.theme.getColor("onSurface")
            Layout.fillWidth: true
        }

        Text {
            text: "Clear All"
            font.family: "Noto Sans"
            font.pixelSize: 11
            font.bold: true
            color: notifSectionRoot.theme.getColor("primary")
            visible: notifSectionRoot.activeNotifs.length > 0

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof root !== "undefined" && typeof root.clearAllNotifications === "function") {
                        root.clearAllNotifications();
                    } else {
                        var temp = notifSectionRoot.activeNotifs;
                        for (var i = temp.length - 1; i >= 0; i--) {
                            var n = temp[i];
                            if (n && typeof n.dismiss === "function") {
                                n.dismiss();
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: notifSectionRoot.activeNotifs.length === 0
        spacing: 10
        Layout.topMargin: 40

        IconImage {
            width: 32
            height: 32
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("notifications/alert.svg")
            Layout.alignment: Qt.AlignHCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: notifSectionRoot.theme.getColor("outline")
            }
        }

        Text {
            text: "No new notifications"
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 12
            font.bold: true
            color: notifSectionRoot.theme.getColor("outline")
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Item { Layout.fillHeight: true }
    }

    NotifList {
        id: appNotifsList
        theme: notifSectionRoot.theme
        activeNotifsModel: notifSectionRoot.activeNotifs
        visible: notifSectionRoot.activeNotifs.length > 0
    }
}
