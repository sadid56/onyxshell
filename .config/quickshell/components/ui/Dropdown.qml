import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Item {
    id: dropdownRoot

    property var theme
    property var model: []
    property int currentIndex: 0
    property var currentValue: null
    property string currentText: ""
    property int itemHeight: 38
    property int maxVisibleItems: 7
    property bool expanded: false
    property string placeholder: "Select option"
    property bool searchable: false
    property string searchPlaceholder: "Search..."
    property string searchQuery: ""
    property bool showFontPreview: false

    implicitWidth: 200
    implicitHeight: 36

    signal activated(int index, var value, string text)

    function getItemText(item) {
        if (item === null || item === undefined) return "";
        if (typeof item === "object") {
            return item.text !== undefined ? item.text : (item.name !== undefined ? item.name : (item.family !== undefined ? item.family : JSON.stringify(item)));
        }
        return item.toString();
    }

    function getItemValue(item) {
        if (item === null || item === undefined) return null;
        if (typeof item === "object" && item.value !== undefined) return item.value;
        if (typeof item === "object" && item.family !== undefined) return item.family;
        return item;
    }

    function getFilteredModel() {
        if (!model || model.length === 0) return [];
        if (!searchable || searchQuery.trim() === "") return model;
        var q = searchQuery.toLowerCase().trim();
        return model.filter(function(item) {
            var txt = getItemText(item).toLowerCase();
            return txt.indexOf(q) !== -1;
        });
    }

    function syncFromValue() {
        if (currentValue === null || currentValue === undefined || currentValue === "") return false;
        if (!model || model.length === 0) {
            currentText = currentValue.toString();
            return true;
        }
        for (var i = 0; i < model.length; i++) {
            if (getItemValue(model[i]) === currentValue || getItemText(model[i]) === currentValue) {
                currentIndex = i;
                currentText = getItemText(model[i]);
                return true;
            }
        }
        currentText = currentValue.toString();
        return false;
    }

    function updateCurrent() {
        if (!model || model.length === 0) {
            if (currentValue !== null && currentValue !== undefined && currentValue !== "") currentText = currentValue.toString();
            else currentText = placeholder;
            return;
        }
        if (syncFromValue()) return;
        if (currentIndex < 0 || currentIndex >= model.length) currentIndex = 0;
        var item = model[currentIndex];
        currentText = getItemText(item);
        currentValue = getItemValue(item);
    }

    onCurrentValueChanged: syncFromValue()
    onModelChanged: updateCurrent()
    onCurrentIndexChanged: {
        if (model && currentIndex >= 0 && currentIndex < model.length) {
            var item = model[currentIndex];
            currentText = getItemText(item);
            currentValue = getItemValue(item);
        }
    }
    Component.onCompleted: updateCurrent()

    function chooseItem(item, filterIdx) {
        var val = getItemValue(item);
        var txt = getItemText(item);
        var realIdx = -1;
        if (model && model.length > 0) {
            for (var i = 0; i < model.length; i++) {
                if (getItemValue(model[i]) === val && getItemText(model[i]) === txt) {
                    realIdx = i;
                    break;
                }
            }
        }
        if (realIdx === -1) realIdx = (filterIdx !== undefined && filterIdx >= 0) ? filterIdx : 0;
        currentIndex = realIdx;
        currentValue = val;
        currentText = txt;
        expanded = false;
        searchQuery = "";
        activated(currentIndex, currentValue, currentText);
    }

    function selectIndex(idx) {
        if (model && idx >= 0 && idx < model.length) chooseItem(model[idx], idx);
    }

    function selectValue(val) {
        currentValue = val;
        syncFromValue();
    }

    onExpandedChanged: {
        if (expanded) {
            searchQuery = "";
            dropdownPopup.updatePosition();
        } else {
            searchQuery = "";
        }
    }

    Rectangle {
        id: headerButton
        anchors.fill: parent
        radius: 10
        color: dropdownRoot.theme ? dropdownRoot.theme.getColor("surfaceVariant") + "44" : "#242328"
        border.width: 1
        border.color: dropdownRoot.theme ? dropdownRoot.theme.getColor("outlineVariant") + "25" : "#444444"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Typography {
                id: labelText
                Layout.fillWidth: true
                theme: dropdownRoot.theme
                text: dropdownRoot.currentText !== "" ? dropdownRoot.currentText : dropdownRoot.placeholder
                variant: "labelMedium"
                font.family: dropdownRoot.showFontPreview && dropdownRoot.currentText ? dropdownRoot.currentText : (dropdownRoot.theme ? dropdownRoot.theme.fontFamily : "sans-serif")
                color: dropdownRoot.theme ? dropdownRoot.theme.getColor("onSurface") : "#FFFFFF"
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Icon {
                size: 14
                icon: "actions/chevron-down.svg"
                rotation: dropdownRoot.expanded ? 180 : 0
                color: dropdownRoot.theme ? dropdownRoot.theme.getColor("onSurfaceVariant") : "#999999"
                Layout.alignment: Qt.AlignVCenter

                Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dropdownRoot.expanded = !dropdownRoot.expanded
        }
    }

    DropdownPopup {
        id: dropdownPopup
        dropdownRoot: dropdownRoot
    }
}
