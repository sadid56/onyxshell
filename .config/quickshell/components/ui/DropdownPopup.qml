import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Item {
    id: popupLayer

    property var dropdownRoot

    parent: dropdownRoot && dropdownRoot.Window ? dropdownRoot.Window.contentItem : (dropdownRoot ? dropdownRoot.parent : null)
    anchors.fill: parent
    visible: dropdownRoot ? dropdownRoot.expanded : false
    z: 999999

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (dropdownRoot) dropdownRoot.expanded = false;
        }
    }

    Rectangle {
        id: menuList
        readonly property var currentListModel: dropdownRoot ? dropdownRoot.getFilteredModel() : []
        readonly property int searchHeaderHeight: (dropdownRoot && dropdownRoot.searchable) ? 48 : 0
        readonly property int calculatedListHeight: Math.min(
            (currentListModel ? currentListModel.length : 0) * (dropdownRoot ? dropdownRoot.itemHeight : 38),
            (dropdownRoot ? dropdownRoot.maxVisibleItems : 7) * (dropdownRoot ? dropdownRoot.itemHeight : 38)
        )
        readonly property int calculatedHeight: searchHeaderHeight + calculatedListHeight + 14

        height: Math.max(searchHeaderHeight + 40, calculatedHeight)
        radius: 12

        color: (dropdownRoot && dropdownRoot.theme) ? dropdownRoot.theme.getColor("surface") : "#1e1e24"
        border.width: 1
        border.color: (dropdownRoot && dropdownRoot.theme) ? dropdownRoot.theme.getColor("outlineVariant") + "40" : "#444444"
        clip: true

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.6
            shadowBlur: 0.8
            shadowVerticalOffset: 6
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Input {
                id: searchInput
                visible: dropdownRoot ? dropdownRoot.searchable : false
                Layout.fillWidth: true
                height: 36
                radius: 10
                theme: dropdownRoot ? dropdownRoot.theme : null
                placeholder: dropdownRoot ? dropdownRoot.searchPlaceholder : "Search..."
                icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/search.svg")
                clearButtonEnabled: true
                text: dropdownRoot ? dropdownRoot.searchQuery : ""
                onTextChanged: { if (dropdownRoot) dropdownRoot.searchQuery = text; }
                onEscapePressed: { if (dropdownRoot) dropdownRoot.expanded = false; }
            }

            Item {
                visible: menuList.currentListModel.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 36

                Typography {
                    theme: dropdownRoot ? dropdownRoot.theme : null
                    anchors.centerIn: parent
                    text: "No matches found"
                    variant: "labelMedium"
                    colorRole: "outline"
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: menuList.currentListModel
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: itemDelegate
                    width: listView.width
                    height: dropdownRoot ? dropdownRoot.itemHeight : 38
                    radius: 8

                    readonly property var rawItem: modelData
                    readonly property string itemLabel: dropdownRoot ? dropdownRoot.getItemText(rawItem) : ""
                    readonly property var itemVal: dropdownRoot ? dropdownRoot.getItemValue(rawItem) : null
                    readonly property bool isSelected: (dropdownRoot && dropdownRoot.currentValue !== null && itemVal === dropdownRoot.currentValue) || (dropdownRoot && dropdownRoot.currentText === itemLabel)
                    readonly property bool isHovered: itemMouse.containsMouse

                    color: (isSelected || isHovered)
                        ? ((dropdownRoot && dropdownRoot.theme) ? dropdownRoot.theme.getColor("surfaceVariant") + "44" : "#302f38")
                        : "transparent"

                    Behavior on color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Typography {
                            Layout.fillWidth: true
                            theme: dropdownRoot ? dropdownRoot.theme : null
                            text: itemDelegate.itemLabel
                            variant: "bodyMedium"
                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                            font.family: (dropdownRoot && dropdownRoot.showFontPreview) ? itemDelegate.itemLabel : (dropdownRoot && dropdownRoot.theme ? dropdownRoot.theme.fontFamily : "sans-serif")
                            color: isSelected
                                ? ((dropdownRoot && dropdownRoot.theme) ? dropdownRoot.theme.getColor("primary") : "#ffb3b4")
                                : (isHovered
                                    ? ((dropdownRoot && dropdownRoot.theme) ? dropdownRoot.theme.getColor("onSurface") : "#FFFFFF")
                                    : ((dropdownRoot && dropdownRoot.theme) ? dropdownRoot.theme.getColor("onSurfaceVariant") : "#cccccc"))
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Icon {
                            size: 14
                            icon: "actions/check.svg"
                            color: isSelected
                                ? ((dropdownRoot && dropdownRoot.theme) ? dropdownRoot.theme.getColor("primary") : "#ffb3b4")
                                : "transparent"
                            visible: isSelected
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (dropdownRoot) dropdownRoot.chooseItem(itemDelegate.rawItem, index);
                        }
                    }
                }
            }
        }
    }

    function updatePosition() {
        var rootItem = (dropdownRoot && dropdownRoot.Window && dropdownRoot.Window.contentItem)
            ? dropdownRoot.Window.contentItem
            : (dropdownRoot ? dropdownRoot.parent : null);
        if (!rootItem) return;

        var pos = dropdownRoot.mapToItem(rootItem, 0, 0);
        var targetY = pos.y + dropdownRoot.height + 4;
        var totalH = menuList.calculatedHeight;

        if (rootItem.height > 0 && targetY + totalH > rootItem.height - 12) {
            targetY = Math.max(10, pos.y - totalH - 4);
        }

        var menuW = Math.max(dropdownRoot.width, (dropdownRoot && dropdownRoot.searchable) ? 260 : dropdownRoot.width);
        var targetX = pos.x;
        if (targetX + menuW > rootItem.width - 12) {
            targetX = Math.max(8, rootItem.width - menuW - 12);
        }

        menuList.x = targetX;
        menuList.y = targetY;
        menuList.width = menuW;
    }
}
