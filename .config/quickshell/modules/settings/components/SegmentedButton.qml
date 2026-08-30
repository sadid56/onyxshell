import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

Rectangle {
    id: segRoot

    property var theme
    property var model: []
    property int currentIndex: 0
    property var currentValue: null

    implicitHeight: 38
    implicitWidth: segRow.implicitWidth + 8
    radius: 19
    color: segRoot.theme ? Qt.alpha(segRoot.theme.getColor("surfaceVariant"), 0.35) : "#1a1b20"
    border.width: 1
    border.color: segRoot.theme ? Qt.alpha(segRoot.theme.getColor("outlineVariant"), 0.35) : "#ffffff15"

    signal selected(int index, var value, string text)

    function getItemText(item) {
        if (typeof item === "object" && item !== null) {
            return item.text !== undefined ? item.text : (item.label !== undefined ? item.label : "");
        }
        return item.toString();
    }

    function getItemValue(item) {
        if (typeof item === "object" && item !== null && item.value !== undefined) {
            return item.value;
        }
        return item;
    }

    function updateSelection() {
        if (!model || model.length === 0) return;
        if (currentIndex < 0 || currentIndex >= model.length) currentIndex = 0;
        currentValue = getItemValue(model[currentIndex]);
    }

    onModelChanged: updateSelection()
    onCurrentIndexChanged: updateSelection()
    Component.onCompleted: updateSelection()

    function selectValue(val) {
        if (!model) return;
        for (var i = 0; i < model.length; i++) {
            if (getItemValue(model[i]) === val) {
                currentIndex = i;
                updateSelection();
                return;
            }
        }
    }

    RowLayout {
        id: segRow
        anchors.fill: parent
        anchors.margins: 3
        spacing: 2

        Repeater {
            model: segRoot.model

            Rectangle {
                id: segItem
                Layout.fillHeight: true
                Layout.preferredWidth: Math.max(54, label.implicitWidth + 18)
                radius: 15

                readonly property bool isSelected: index === segRoot.currentIndex
                readonly property bool isHovered: itemMouse.containsMouse

                color: isSelected
                    ? segRoot.theme.getColor("primaryContainer")
                    : (isHovered ? segRoot.theme.getColor("surfaceVariant") + "55" : "transparent")

                Behavior on color { ColorAnimation { duration: 140 } }

                UI.Typography {
                    id: label
                    theme: segRoot.theme
                    anchors.centerIn: parent
                    text: segRoot.getItemText(modelData)
                    variant: "labelMedium"
                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                    color: isSelected
                        ? segRoot.theme.getColor("onPrimaryContainer")
                        : segRoot.theme.getColor("onSurfaceVariant")
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        segRoot.currentIndex = index;
                        segRoot.updateSelection();
                        segRoot.selected(index, segRoot.currentValue, segRoot.getItemText(modelData));
                    }
                }
            }
        }
    }
}
