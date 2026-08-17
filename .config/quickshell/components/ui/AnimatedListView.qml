import QtQuick
import QtQuick.Layouts

ListView {
    id: listViewRoot

    property var theme
    property color pillColor: (listViewRoot.theme && typeof listViewRoot.theme.getColor === "function") 
        ? listViewRoot.theme.getColor("surfaceVariant") 
        : ((typeof root !== "undefined" && root.theme) ? root.theme.getColor("surfaceVariant") : "#2b2a27")
    property real pillRadius: 12
    property real pillMargin: 6
    property int hoveredIndex: -1
    property int activeTargetIndex: currentIndex >= 0 ? currentIndex : hoveredIndex

    clip: true
    spacing: 4
    boundsBehavior: Flickable.StopAtBounds

    function hoverItem(idx, targetY, targetHeight) {
        hoveredIndex = idx;
        if (targetY !== undefined && targetHeight !== undefined) {
            selectionPill.targetY = targetY;
            selectionPill.targetHeight = targetHeight;
        }
    }

    function unhoverItem(idx) {
        if (hoveredIndex === idx) {
            hoveredIndex = -1;
            if (currentIndex >= 0 && currentItem) {
                selectionPill.targetY = currentItem.y;
                selectionPill.targetHeight = currentItem.height;
            }
        }
    }

    function isItemHighlighted(idx) {
        if (hoveredIndex !== -1) {
            return hoveredIndex === idx;
        }
        return currentIndex === idx;
    }

    onCurrentIndexChanged: {
        if (currentIndex >= 0 && currentItem) {
            selectionPill.targetY = currentItem.y;
            selectionPill.targetHeight = currentItem.height;
        }
    }

    Rectangle {
        id: selectionPill
        parent: listViewRoot.contentItem
        z: 0
        x: listViewRoot.pillMargin
        width: Math.max(0, listViewRoot.width - (listViewRoot.pillMargin * 2))
        radius: listViewRoot.pillRadius
        color: listViewRoot.pillColor

        property real targetY: 0
        property real targetHeight: 0

        y: targetY
        height: targetHeight
        opacity: (listViewRoot.activeTargetIndex >= 0 && listViewRoot.count > 0) ? 1.0 : 0.0

        Behavior on y {
            NumberAnimation {
                duration: 160
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
                duration: 140
                easing.type: Easing.OutQuad
            }
        }
    }

    Behavior on Layout.preferredHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    add: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
        }
    }

    remove: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0.0; duration: 160; easing.type: Easing.OutQuad }
            NumberAnimation { property: "scale"; to: 0.95; duration: 160; easing.type: Easing.OutCubic }
        }
    }

    move: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    moveDisplaced: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    displaced: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    removeDisplaced: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    addDisplaced: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    populate: Transition {
        NumberAnimation {
            properties: "opacity,y"
            from: 0.0
            duration: 180
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

    Rectangle {
        id: bottomScrollFadeRect
        anchors.left: listViewRoot.left
        anchors.right: listViewRoot.right
        anchors.bottom: listViewRoot.bottom
        height: 48
        z: 10
        enabled: false
        visible: listViewRoot.count > 3

        readonly property color surfaceColor: (listViewRoot.theme && typeof listViewRoot.theme.getColor === "function") 
            ? listViewRoot.theme.getColor("surface") 
            : ((typeof root !== "undefined" && root.theme) ? root.theme.getColor("surface") : "#1b1b1b")

        gradient: Gradient {
            GradientStop { 
                position: 0.0
                color: Qt.rgba(bottomScrollFadeRect.surfaceColor.r, bottomScrollFadeRect.surfaceColor.g, bottomScrollFadeRect.surfaceColor.b, 0.0) 
            }
            GradientStop { 
                position: 1.0
                color: bottomScrollFadeRect.surfaceColor 
            }
        }
    }
}
