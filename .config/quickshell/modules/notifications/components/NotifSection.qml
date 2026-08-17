import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: notifSectionRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 12

    property var theme
    property var activeNotifs: []

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
                    var temp = notifSectionRoot.activeNotifs;
                    for (var i = temp.length - 1; i >= 0; i--) {
                        var n = temp[i];
                        if (n && typeof n.dismiss === "function") {
                            n.dismiss();
                        }
                    }
                    notifSectionRoot.activeNotifs = [];
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: notifSectionRoot.activeNotifs.length === 0
        spacing: 6
        Layout.topMargin: 40

        Text {
            text: "󰂚"
            font.family: "Noto Sans"
            font.pixelSize: 32
            color: notifSectionRoot.theme.getColor("outline")
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
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
