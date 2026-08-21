import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Rectangle {
    id: sidebarRoot

    property var theme: null
    property string selectedCategory: "All"
    property var allApps: []
    signal categorySelected(string category)

    width: 175
    color: "transparent"

    readonly property var categories: [
        { id: "All", name: "All Apps", icon: "categories/category-all.svg" },
        { id: "Development", name: "Development", icon: "categories/category-dev.svg" },
        { id: "Internet", name: "Internet", icon: "categories/category-web.svg" },
        { id: "Multimedia", name: "Multimedia", icon: "categories/category-media.svg" },
        { id: "Graphics", name: "Graphics", icon: "categories/category-graphics.svg" },
        { id: "Utilities", name: "Utilities", icon: "categories/category-utils.svg" },
        { id: "System", name: "System", icon: "categories/category-system.svg" },
        { id: "Office", name: "Office", icon: "categories/category-office.svg" },
        { id: "Settings", name: "Settings", icon: "categories/category-settings.svg" },
        { id: "Games", name: "Games", icon: "categories/category-games.svg" }
    ]

    property int hoveredIndex: -1

    function getCountForCategory(catId) {
        if (catId === "All") return allApps.length;
        var count = 0;
        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i];
            if (app && app.categories && app.categories.indexOf(catId) !== -1) {
                count++;
            }
        }
        return count;
    }

    Timer {
        id: unhoverTimer
        interval: 80
        repeat: false
        onTriggered: {
            sidebarRoot.hoveredIndex = -1;
            updateSelectionPillPosition();
        }
    }

    function updateSelectionPillPosition() {
        for (var i = 0; i < catRepeater.count; i++) {
            var item = catRepeater.itemAt(i);
            if (item && item.catId === sidebarRoot.selectedCategory) {
                selectionPill.targetY = item.y;
                selectionPill.targetHeight = item.height;
                selectionPill.visiblePill = true;
                return;
            }
        }
    }

    onSelectedCategoryChanged: {
        Qt.callLater(updateSelectionPillPosition);
    }

    Component.onCompleted: {
        Qt.callLater(updateSelectionPillPosition);
    }

    Column {
        id: mainColumn
        anchors.fill: parent
        spacing: 6

        Text {
            text: "CATEGORIES"
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2
            color: theme ? theme.getColor("outline") : "#999999"
            leftPadding: 14
            bottomPadding: 4
            width: parent.width
        }

        Item {
            id: listContainer
            width: parent.width
            height: sidebarRoot.height - 30

            // Floating Animated Selection/Hover Pill with Bounce
            Rectangle {
                id: selectionPill
                z: 0
                width: parent.width
                height: targetHeight
                radius: 12
                color: theme ? theme.getColor("surfaceVariant") : "#2b2a27"

                property real targetY: 0
                property real targetHeight: 36
                property bool visiblePill: true

                y: targetY
                opacity: visiblePill ? 1.0 : 0.0

                Behavior on y {
                    NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.25 }
                }
                Behavior on height {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 140 }
                }
            }

            Column {
                id: itemsColumn
                width: parent.width
                spacing: 3

                Repeater {
                    id: catRepeater
                    model: sidebarRoot.categories

                    Item {
                        id: catItem
                        width: listContainer.width
                        height: 36

                        readonly property string catId: modelData.id
                        readonly property bool isSelected: sidebarRoot.selectedCategory === modelData.id
                        readonly property bool isHovered: sidebarRoot.hoveredIndex === index
                        readonly property int appCount: sidebarRoot.getCountForCategory(modelData.id)

                        // Hide empty categories except "All"
                        visible: modelData.id === "All" || appCount > 0

                        scale: catMouse.pressed ? 0.94 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            IconImage {
                                width: 16
                                height: 16
                                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(modelData.icon)
                                Layout.alignment: Qt.AlignVCenter
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: (catItem.isSelected || catItem.isHovered)
                                           ? (theme ? theme.getColor("onSurface") : "#FFFFFF")
                                           : (theme ? theme.getColor("outline") : "#AAAAAA")
                                }
                            }

                            Text {
                                text: modelData.name
                                font.family: "Google Sans Flex, sans-serif"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: (catItem.isSelected || catItem.isHovered)
                                       ? (theme ? theme.getColor("onSurface") : "#FFFFFF")
                                       : (theme ? theme.getColor("onSurface") : "#E6E1E5")
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Rectangle {
                                width: Math.max(20, countTxt.implicitWidth + 10)
                                height: 18
                                radius: 9
                                color: catItem.isSelected
                                       ? (theme ? Qt.rgba(theme.getColor("onSurface").r, theme.getColor("onSurface").g, theme.getColor("onSurface").b, 0.12) : "#20FFFFFF")
                                       : (theme ? Qt.rgba(theme.getColor("surfaceVariant").r, theme.getColor("surfaceVariant").g, theme.getColor("surfaceVariant").b, 0.6) : "#15FFFFFF")
                                visible: catItem.appCount > 0

                                Text {
                                    id: countTxt
                                    anchors.centerIn: parent
                                    text: String(catItem.appCount)
                                    font.family: "Google Sans Flex, sans-serif"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: (catItem.isSelected || catItem.isHovered)
                                           ? (theme ? theme.getColor("onSurface") : "#FFFFFF")
                                           : (theme ? theme.getColor("outline") : "#AAAAAA")
                                }
                            }
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                unhoverTimer.stop();
                                sidebarRoot.hoveredIndex = index;
                                selectionPill.targetY = catItem.y;
                                selectionPill.targetHeight = catItem.height;
                                selectionPill.visiblePill = true;
                                sidebarRoot.categorySelected(modelData.id);
                            }
                            onExited: {
                                unhoverTimer.restart();
                            }
                            onClicked: {
                                sidebarRoot.categorySelected(modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }
}
