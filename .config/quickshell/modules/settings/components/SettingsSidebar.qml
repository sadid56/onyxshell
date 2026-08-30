import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../../components/ui" as UI

Item {
    id: sidebarRoot

    property var theme
    property int selectedIndex: 0
    property string selectedId: "appearance"

    property var categories: [
        { id: "appearance", title: "Appearance", icon: "system/palette.svg" },
        { id: "dock", title: "Dock", icon: "system/layout.svg" },
        { id: "fonts", title: "Typography & Fonts", icon: "system/keyboard.svg" },
        { id: "hyprland", title: "Window & WM", icon: "system/layout.svg" },
        { id: "keybinds", title: "Keybindings", icon: "system/keyboard.svg" },
        { id: "notifications", title: "Notifications", icon: "notifications/bell.svg" },
        { id: "display", title: "Display", icon: "system/monitor.svg" },
        { id: "system", title: "System Info", icon: "system/info.svg" }
    ]

    signal categorySelected(string categoryId, int index)

    width: 200

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.topMargin: 2
            spacing: 10

            Rectangle {
                width: 30
                height: 30
                radius: 8
                color: sidebarRoot.theme.getColor("surfaceVariant")

                UI.Icon {
                    anchors.centerIn: parent
                    size: 16
                    icon: "categories/category-settings.svg"
                    color: sidebarRoot.theme.getColor("primary")
                }
            }

            UI.Typography {
                theme: sidebarRoot.theme
                text: "Settings"
                variant: "titleMedium"
                font.pixelSize: 16
                colorRole: "onSurface"
                verticalAlignment: Text.AlignVCenter
            }
        }

        ListView {
            id: catList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: sidebarRoot.categories
            spacing: 3
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: itemRect
                width: catList.width
                height: 42
                radius: 21

                readonly property bool isSelected: sidebarRoot.selectedIndex === index
                readonly property bool isHovered: itemMouse.containsMouse

                color: isSelected
                    ? (sidebarRoot.theme ? sidebarRoot.theme.getColor("secondaryContainer") : "#3d3a48")
                    : (isHovered ? (sidebarRoot.theme ? Qt.alpha(sidebarRoot.theme.getColor("surfaceVariant"), 0.50) : "#20ffffff") : "transparent")

                Behavior on color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    UI.Icon {
                        size: 18
                        icon: modelData.icon
                        color: isSelected
                            ? (sidebarRoot.theme ? sidebarRoot.theme.getColor("onSecondaryContainer") : "#ffffff")
                            : (isHovered ? (sidebarRoot.theme ? sidebarRoot.theme.getColor("onSurface") : "#ffffff") : (sidebarRoot.theme ? sidebarRoot.theme.getColor("onSurfaceVariant") : "#aaaaaa"))
                        Layout.alignment: Qt.AlignVCenter
                    }

                    UI.Typography {
                        Layout.fillWidth: true
                        theme: sidebarRoot.theme
                        text: modelData.title
                        variant: "labelLarge"
                        font.bold: isSelected
                        colorRole: isSelected ? "onSecondaryContainer" : (isHovered ? "onSurface" : "onSurfaceVariant")
                        Layout.alignment: Qt.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        sidebarRoot.selectedIndex = index;
                        sidebarRoot.selectedId = modelData.id;
                        sidebarRoot.categorySelected(modelData.id, index);
                    }
                }
            }
        }
    }
}
