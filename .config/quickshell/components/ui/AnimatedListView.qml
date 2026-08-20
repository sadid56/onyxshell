import QtQuick
import QtQuick.Layouts
import "../../core"

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

    currentIndex: -1
    clip: true
    spacing: 4
    boundsBehavior: Flickable.StopAtBounds

    ListModelUtils { id: modelUtils }

    function syncListModel(listModel, sourceArray, keyProp, maxLimit) {
        modelUtils.syncListModel(listModel, sourceArray, keyProp, maxLimit);
    }

    Timer {
        id: unhoverTimer
        interval: 60
        repeat: false
        onTriggered: {
            hoveredIndex = -1;
            if (currentIndex >= 0 && currentItem) {
                selectionPill.targetY = currentItem.y;
                selectionPill.targetHeight = currentItem.height;
            }
        }
    }

    function hoverItem(idx, targetY, targetHeight) {
        unhoverTimer.stop();
        hoveredIndex = idx;
        if (targetY !== undefined && targetHeight !== undefined) {
            selectionPill.targetY = targetY;
            selectionPill.targetHeight = targetHeight;
        }
    }

    function unhoverItem(idx) {
        if (hoveredIndex === idx) {
            unhoverTimer.restart();
        }
    }

    function isItemHighlighted(idx) {
        return (hoveredIndex !== -1) ? (hoveredIndex === idx) : (currentIndex === idx);
    }

    onCountChanged: {
        if (hoveredIndex >= count) {
            hoveredIndex = -1;
        }
        if (currentIndex >= count) {
            currentIndex = -1;
        }
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
        opacity: ((listViewRoot.hoveredIndex >= 0 && listViewRoot.hoveredIndex < listViewRoot.count) || (listViewRoot.currentIndex >= 0 && listViewRoot.currentIndex < listViewRoot.count && listViewRoot.currentItem)) ? 1.0 : 0.0

        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
    }

    Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

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

    move: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }
    moveDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }
    displaced: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }
    removeDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }
    addDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic } }

    WheelHandler {
        id: wheelHandler
        target: listViewRoot
        orientation: Qt.Vertical
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            var step = (event.angleDelta.y / 120) * 80;
            var maxScroll = Math.max(0, listViewRoot.contentHeight - listViewRoot.height);
            var newContentY = Math.max(0, Math.min(maxScroll, listViewRoot.contentY - step));
            smoothScrollAnim.to = newContentY;
            smoothScrollAnim.restart();
        }
    }

    NumberAnimation {
        id: smoothScrollAnim
        target: listViewRoot
        property: "contentY"
        duration: 180
        easing.type: Easing.OutCubic
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
            GradientStop { position: 0.0; color: Qt.rgba(bottomScrollFadeRect.surfaceColor.r, bottomScrollFadeRect.surfaceColor.g, bottomScrollFadeRect.surfaceColor.b, 0.0) }
            GradientStop { position: 1.0; color: bottomScrollFadeRect.surfaceColor }
        }
    }
}
