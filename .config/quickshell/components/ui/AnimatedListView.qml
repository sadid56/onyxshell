import QtQuick
import QtQuick.Layouts

ListView {
    id: listViewRoot
    clip: true
    spacing: 8

    property bool enableGlidingPill: true
    property color pillColor: "#e2e1ec"
    property int pillRadius: 12
    property int pillMargin: 6

    property int hoveredIndex: -1
    property real targetPillY: -100
    property real targetPillHeight: 48
    readonly property bool isPillActive: enableGlidingPill && (hoveredIndex >= 0 || (listViewRoot.activeFocus && currentIndex >= 0))

    function hoverItem(index, itemY, itemHeight) {
        hoveredIndex = index;
        targetPillY = itemY;
        if (itemHeight !== undefined && itemHeight > 0) {
            targetPillHeight = itemHeight;
        }
    }

    function unhoverItem(index) {
        if (hoveredIndex === index) {
            hoveredIndex = -1;
        }
    }

    function isItemHighlighted(index) {
        return hoveredIndex === index || (listViewRoot.activeFocus && currentIndex === index);
    }

    onActiveFocusChanged: {
        if (!activeFocus) {
            currentIndex = -1;
        }
    }

    onCurrentIndexChanged: {
        if (currentIndex >= 0 && currentItem) {
            targetPillY = currentItem.y;
            targetPillHeight = currentItem.height;
        }
    }

    Rectangle {
        id: glidingPill
        parent: listViewRoot.contentItem
        visible: listViewRoot.enableGlidingPill
        x: listViewRoot.pillMargin
        width: Math.max(0, listViewRoot.width - (listViewRoot.pillMargin * 2))
        height: listViewRoot.targetPillHeight
        radius: listViewRoot.pillRadius
        color: listViewRoot.pillColor
        border.width: 0
        z: 0
        opacity: listViewRoot.isPillActive ? 1.0 : 0.0

        y: listViewRoot.targetPillY

        Behavior on y {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutQuad
            }
        }
    }

    Behavior on Layout.preferredHeight {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    add: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 220; easing.type: Easing.OutQuad }
            NumberAnimation { property: "scale"; from: 0.94; to: 1.0; duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { property: "x"; from: -14; to: 0; duration: 240; easing.type: Easing.OutCubic }
        }
    }

    remove: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0.0; duration: 160; easing.type: Easing.OutQuad }
            NumberAnimation { property: "scale"; to: 0.94; duration: 160; easing.type: Easing.OutCubic }
        }
    }

    displaced: Transition {
        NumberAnimation {
            properties: "y"
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    removeDisplaced: Transition {
        NumberAnimation {
            properties: "y"
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    addDisplaced: Transition {
        NumberAnimation {
            properties: "y"
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    function syncListModel(listModel, sourceArray, keyProp, maxLimit) {
        if (!sourceArray || sourceArray.length === 0) {
            listModel.clear();
            return;
        }

        var limit = maxLimit > 0 ? Math.min(sourceArray.length, maxLimit) : sourceArray.length;

        if (listModel.count === 0) {
            for (var a = 0; a < limit; a++) {
                var itm = sourceArray[a];
                if (typeof itm === "object") {
                    listModel.append(itm);
                } else {
                    listModel.append({ "entryData": itm });
                }
            }
            return;
        }

        for (var j = 0; j < limit; j++) {
            var targetItem = sourceArray[j];
            var targetKeyVal = (typeof targetItem === "object" && keyProp) ? targetItem[keyProp] : targetItem;
            var foundIdx = -1;

            for (var k = j; k < listModel.count; k++) {
                var modelItem = listModel.get(k);
                var modelKeyVal = (modelItem && keyProp && modelItem[keyProp] !== undefined) ? modelItem[keyProp] : (modelItem ? modelItem.entryData : modelItem);
                if (modelKeyVal === targetKeyVal) {
                    foundIdx = k;
                    break;
                }
            }

            if (foundIdx !== -1 && foundIdx !== j) {
                listModel.move(foundIdx, j, 1);
            }
        }

        for (var n = 0; n < limit; n++) {
            var insertItem = sourceArray[n];
            var insertKeyVal = (typeof insertItem === "object" && keyProp) ? insertItem[keyProp] : insertItem;
            var present = false;

            for (var m = 0; m < listModel.count; m++) {
                var itmCheck = listModel.get(m);
                var keyCheck = (itmCheck && keyProp && itmCheck[keyProp] !== undefined) ? itmCheck[keyProp] : (itmCheck ? itmCheck.entryData : itmCheck);
                if (keyCheck === insertKeyVal) {
                    present = true;
                    break;
                }
            }

            if (!present) {
                if (typeof insertItem === "object") {
                    listModel.insert(n, insertItem);
                } else {
                    listModel.insert(n, { "entryData": insertItem });
                }
            }
        }

        var targetMap = {};
        for (var t = 0; t < limit; t++) {
            var val = sourceArray[t];
            var key = (typeof val === "object" && keyProp) ? val[keyProp] : val;
            targetMap[key] = true;
        }

        for (var r = listModel.count - 1; r >= 0; r--) {
            var curr = listModel.get(r);
            var currKey = (curr && keyProp && curr[keyProp] !== undefined) ? curr[keyProp] : (curr ? curr.entryData : curr);
            if (!curr || !targetMap[currKey]) {
                listModel.remove(r);
            }
        }
    }
}
