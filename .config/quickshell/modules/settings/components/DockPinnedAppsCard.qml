import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../components" as SettingsUI
import "../../../components/ui" as UI

SettingsUI.SettingsCard {
    id: pinnedAppsRoot

    property var theme
    property var settingsService
    property var appService: (typeof root !== "undefined" && root.appService) ? root.appService : null
    property var allApps: []

    title: "Pinned Applications (" + ((settingsService && settingsService.dockPinnedApps) ? settingsService.dockPinnedApps.length : 0) + ")"

    readonly property var appsList: (allApps && allApps.length > 0)
        ? allApps
        : ((appService && appService.apps && appService.apps.length > 0) ? appService.apps : [])

    Item {
        width: parent.width
        implicitWidth: parent.width
        implicitHeight: 340
        height: 340
        clip: true

        UI.SkeletonLoader {
            anchors.fill: parent
            theme: pinnedAppsRoot.theme
            count: 6
            itemHeight: 52
            iconSize: 28
            visible: !pinnedAppsRoot.appsList || pinnedAppsRoot.appsList.length === 0
        }

        Flickable {
            anchors.fill: parent
            contentHeight: appListColumn.implicitHeight
            clip: true
            visible: pinnedAppsRoot.appsList && pinnedAppsRoot.appsList.length > 0
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: appListColumn
                width: parent.width

                Repeater {
                    id: appListRepeater
                    model: pinnedAppsRoot.appsList

                    delegate: Column {
                        id: appItemCol
                        width: appListColumn.width

                        required property var modelData
                        required property int index

                        readonly property bool itemPinned: {
                            if (!pinnedAppsRoot.settingsService || !pinnedAppsRoot.settingsService.dockPinnedApps || !modelData) return false;
                            var _len = pinnedAppsRoot.settingsService.dockPinnedApps.length;
                            return pinnedAppsRoot.settingsService.isAppPinned(modelData);
                        }

                        Rectangle {
                            width: parent.width
                            height: 52
                            radius: 8
                            color: itemMouse.containsMouse ? (pinnedAppsRoot.theme ? (pinnedAppsRoot.theme.getColor("surfaceVariant") + "50") : "#282836") : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 12

                                Item {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    Layout.alignment: Qt.AlignVCenter

                                    IconImage {
                                        anchors.fill: parent
                                        source: {
                                            if (!modelData || !modelData.icon) return "";
                                            var ic = modelData.icon;
                                            if (ic.indexOf("/") === 0) return "file://" + ic;
                                            if (ic.startsWith("file://") || ic.startsWith("image://") || ic.startsWith("qrc:/")) return ic;
                                            return "image://icon/" + ic;
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    UI.Typography {
                                        Layout.fillWidth: true
                                        theme: pinnedAppsRoot.theme
                                        text: modelData ? (modelData.name || "App") : "App"
                                        variant: "bodyMedium"
                                        font.bold: appItemCol.itemPinned
                                        colorRole: appItemCol.itemPinned ? "primary" : "onSurface"
                                        elide: Text.ElideRight
                                    }

                                    UI.Typography {
                                        Layout.fillWidth: true
                                        theme: pinnedAppsRoot.theme
                                        text: modelData ? (modelData.comment || modelData.exec || "") : ""
                                        variant: "labelSmall"
                                        colorRole: "onSurfaceVariant"
                                        elide: Text.ElideRight
                                        visible: text !== ""
                                    }
                                }

                                UI.Switch {
                                    id: appSwitch
                                    theme: pinnedAppsRoot.theme
                                    checked: appItemCol.itemPinned
                                    Layout.alignment: Qt.AlignVCenter
                                    onToggled: isChecked => {
                                        if (pinnedAppsRoot.settingsService && modelData) {
                                            pinnedAppsRoot.settingsService.togglePinnedApp(modelData);
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.rightMargin: 56
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (pinnedAppsRoot.settingsService && modelData) {
                                        pinnedAppsRoot.settingsService.togglePinnedApp(modelData);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: pinnedAppsRoot.theme ? (pinnedAppsRoot.theme.getColor("outlineVariant") + "15") : "#ffffff10"
                            visible: index < (pinnedAppsRoot.appsList.length - 1)
                        }
                    }
                }
            }
        }
    }
}
