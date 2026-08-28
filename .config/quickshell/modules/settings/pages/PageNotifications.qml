import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../components" as SettingsUI
import "../../../components/ui" as UI

Item {
    id: pageRoot

    property var theme
    property var settingsService

    property var installedApps: []
    property string searchQuery: ""

    Process {
        id: notifAppsProc
        command: ["python", (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getScript("list_notification_apps.py")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (Array.isArray(parsed)) {
                            pageRoot.installedApps = parsed;
                        }
                    } catch (e) {}
                }
            }
        }
    }

    function getFilteredApps() {
        if (!installedApps || installedApps.length === 0) return [];
        var q = searchQuery.toLowerCase().trim();
        if (q === "") return installedApps;
        return installedApps.filter(function(a) {
            if (!a) return false;
            if (a.name && a.name.toLowerCase().indexOf(q) !== -1) return true;
            if (a.comment && a.comment.toLowerCase().indexOf(q) !== -1) return true;
            if (a.id && a.id.toLowerCase().indexOf(q) !== -1) return true;
            return false;
        });
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 42
            spacing: 12

            Rectangle {
                width: 36
                height: 36
                radius: 10
                color: pageRoot.theme.getColor("surfaceVariant")

                UI.Icon {
                    anchors.centerIn: parent
                    size: 20
                    icon: "notifications/bell.svg"
                    color: pageRoot.theme.getColor("primary")
                }
            }

            UI.Typography {
                Layout.fillWidth: true
                theme: pageRoot.theme
                text: "Notifications & DND"
                variant: "titleMedium"
                Layout.alignment: Qt.AlignVCenter
            }

        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentLayout.implicitHeight + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 14

                SettingsUI.SettingsCard {
                    theme: pageRoot.theme
                    title: "Do Not Disturb (DND)"

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Global DND Mode"
                        icon: "notifications/bell-off.svg"

                        UI.Switch {
                            theme: pageRoot.theme
                            checked: pageRoot.settingsService ? pageRoot.settingsService.dndEnabled : false
                            onToggled: isChecked => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.dndEnabled = isChecked;
                                    pageRoot.settingsService.saveSettings();
                                }
                            }
                        }
                    }
                }

                SettingsUI.SettingsCard {
                    theme: pageRoot.theme
                    title: "Application Permissions (" + pageRoot.installedApps.length + " Installed)"

                    UI.SkeletonLoader {
                        width: parent.width
                        theme: pageRoot.theme
                        count: 4
                        itemHeight: 42
                        iconSize: 28
                        visible: pageRoot.installedApps.length === 0
                    }

                    Column {
                        id: appsCol
                        width: parent.width
                        spacing: 2
                        visible: pageRoot.installedApps.length > 0

                        Repeater {
                            model: pageRoot.installedApps
                            delegate: Rectangle {
                                id: appRowRect
                                width: appsCol.width
                                height: 42
                                radius: 10
                                color: rowMouse.containsMouse
                                    ? (pageRoot.theme ? pageRoot.theme.getColor("surfaceVariant") + "44" : "#302f38")
                                    : "transparent"

                                Behavior on color { ColorAnimation { duration: 140 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 12

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 8
                                        color: pageRoot.theme.getColor("surfaceVariant") + "50"
                                        clip: true
                                        Layout.alignment: Qt.AlignVCenter

                                        IconImage {
                                            anchors.fill: parent
                                            anchors.margins: 3
                                            source: (modelData.icon && modelData.icon.indexOf("/") === 0)
                                                ? ("file://" + modelData.icon)
                                                : ""
                                            visible: modelData.icon && modelData.icon.indexOf("/") === 0
                                        }

                                        UI.Icon {
                                            anchors.centerIn: parent
                                            size: 15
                                            icon: (modelData.icon && modelData.icon.indexOf("/") !== 0) ? modelData.icon : "system/app-window.svg"
                                            color: pageRoot.theme.getColor("primary")
                                            visible: !modelData.icon || modelData.icon.indexOf("/") !== 0
                                        }
                                    }

                                    UI.Typography {
                                        theme: pageRoot.theme
                                        text: modelData.name || "Unknown Application"
                                        variant: "bodyMedium"
                                        colorRole: "onSurface"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Item {
                                        implicitWidth: appSwitch.implicitWidth
                                        implicitHeight: appSwitch.implicitHeight
                                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                        UI.Switch {
                                            id: appSwitch
                                            theme: pageRoot.theme
                                            checked: pageRoot.settingsService ? !pageRoot.settingsService.isAppMuted(modelData) : true
                                            onToggled: isAllowed => {
                                                if (pageRoot.settingsService) {
                                                    pageRoot.settingsService.setMuteApp(modelData, !isAllowed);
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        appSwitch.checked = !appSwitch.checked;
                                        if (pageRoot.settingsService) {
                                            pageRoot.settingsService.setMuteApp(modelData, !appSwitch.checked);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                SettingsUI.SettingsCard {
                    theme: pageRoot.theme
                    title: "Banner Timeout & History"

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Popup Duration (" + (pageRoot.settingsService ? pageRoot.settingsService.notifTimeout : 5) + "s)"
                        icon: "system/clock.svg"

                        UI.Slider {
                            theme: pageRoot.theme
                            implicitWidth: 160
                            min: 2
                            max: 12
                            value: pageRoot.settingsService ? pageRoot.settingsService.notifTimeout : 5
                            onMoved: val => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.notifTimeout = val;
                                    pageRoot.settingsService.saveSettings();
                                }
                            }
                        }
                    }

                    UI.Divider {
                        theme: pageRoot.theme
                        width: parent.width
                        horizontal: true
                    }

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Clear All Notifications"
                        icon: "system/trash.svg"

                        UI.Button {
                            theme: pageRoot.theme
                            text: "Clear History"
                            icon: "system/trash.svg"
                            onClicked: {
                                if (typeof root !== "undefined" && typeof root.clearAllNotifications === "function") {
                                    root.clearAllNotifications();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
