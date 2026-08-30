import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

ColumnLayout {
    id: notifSectionRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 10

    property var theme
    readonly property var activeNotifs: (typeof notifWindow !== "undefined" && notifWindow.activeNotifs) ? notifWindow.activeNotifs : ((typeof root !== "undefined" && root.activeNotifs) ? root.activeNotifs : [])

    // macOS Style Notifications Header
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        spacing: 8

        UI.Typography {
            theme: notifSectionRoot.theme
            text: "Notifications"
            variant: "titleMedium"
            font.bold: true
            font.pixelSize: 14
            colorRole: "onSurface"
        }

        // Pill Count Badge
        Rectangle {
            visible: notifSectionRoot.activeNotifs.length > 0
            width: Math.max(20, countText.implicitWidth + 10)
            height: 18
            radius: 9
            color: notifSectionRoot.theme ? Qt.alpha(notifSectionRoot.theme.getColor("primary"), 0.22) : "#503838"

            UI.Typography {
                id: countText
                anchors.centerIn: parent
                theme: notifSectionRoot.theme
                text: String(notifSectionRoot.activeNotifs.length)
                variant: "labelSmall"
                font.bold: true
                color: notifSectionRoot.theme ? notifSectionRoot.theme.getColor("primary") : "#ffb3b4"
            }
        }

        Item { Layout.fillWidth: true }

        // macOS Glass "Clear" Button
        Rectangle {
            visible: notifSectionRoot.activeNotifs.length > 0
            implicitWidth: clearLabel.implicitWidth + 16
            height: 24
            radius: 12
            color: clearMouse.containsMouse
                ? (notifSectionRoot.theme ? Qt.alpha(notifSectionRoot.theme.getColor("surfaceVariant"), 0.9) : "#453838")
                : (notifSectionRoot.theme ? Qt.alpha(notifSectionRoot.theme.getColor("surfaceVariant"), 0.5) : "#302626")
            border.width: 1
            border.color: notifSectionRoot.theme ? Qt.alpha(notifSectionRoot.theme.getColor("outlineVariant"), 0.3) : "#453838"

            Behavior on color { ColorAnimation { duration: 120 } }

            UI.Typography {
                id: clearLabel
                anchors.centerIn: parent
                theme: notifSectionRoot.theme
                text: "Clear All"
                variant: "labelSmall"
                font.bold: true
                colorRole: clearMouse.containsMouse ? "primary" : "onSurfaceVariant"
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
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

    // macOS Style Empty State
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: notifSectionRoot.activeNotifs.length === 0
        spacing: 8
        Layout.topMargin: 24
        Layout.bottomMargin: 12

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 44
            height: 44
            radius: 22
            color: notifSectionRoot.theme ? Qt.alpha(notifSectionRoot.theme.getColor("surfaceVariant"), 0.40) : "#2d2424"

            UI.Icon {
                anchors.centerIn: parent
                size: 20
                icon: "notifications/alert.svg"
                color: notifSectionRoot.theme ? notifSectionRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8"
            }
        }

        UI.Typography {
            theme: notifSectionRoot.theme
            text: "No Notifications"
            variant: "labelMedium"
            font.bold: true
            colorRole: "onSurfaceVariant"
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
