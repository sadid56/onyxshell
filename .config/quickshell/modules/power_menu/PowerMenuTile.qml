import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../components/ui" as UI

Rectangle {
    id: tileRoot
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: isHighlighted ? 134 : 114
    implicitHeight: isHighlighted ? 184 : 160
    radius: isHighlighted ? 30 : 26
    clip: true

    property var theme: null
    property var itemData: null
    property bool isSelected: false
    property bool isHovered: tileMouseArea.containsMouse
    readonly property bool isHighlighted: isHovered || isSelected
    signal tileClicked()
    signal hoverEntered()

    readonly property string role: itemData ? (itemData.role || "primary") : "primary"
    readonly property bool isDanger: role === "error"

    Behavior on implicitWidth { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
    Behavior on implicitHeight { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
    Behavior on radius { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }

    function getCardBg() {
        if (isHighlighted) {
            return tileRoot.theme ? (tileRoot.theme.getColor("primary") || "#adc6ff") : "#adc6ff";
        }
        return tileRoot.theme ? Qt.alpha(tileRoot.theme.getColor("surfaceVariant"), 0.55) : "#2c2834";
    }

    function getOnCardColor() {
        if (!isHighlighted) {
            return tileRoot.theme ? tileRoot.theme.getColor("onSurface") : "#ffffff";
        }
        return tileRoot.theme ? (tileRoot.theme.getColor("onPrimary") || "#000000") : "#000000";
    }

    color: getCardBg()
    border.width: 1
    border.color: isHighlighted
        ? Qt.alpha(getOnCardColor(), 0.3)
        : (tileRoot.theme ? Qt.alpha(tileRoot.theme.getColor("outlineVariant"), 0.20) : "#15ffffff")

    Behavior on color { ColorAnimation { duration: 260; easing.type: Easing.OutQuad } }
    Behavior on border.color { ColorAnimation { duration: 260; easing.type: Easing.OutQuad } }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: isHighlighted ? 26 : 22
        anchors.bottomMargin: isHighlighted ? 26 : 22
        spacing: 0

        Behavior on anchors.topMargin { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

        // Circular Icon Badge
        Rectangle {
            id: iconBadge
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: isHighlighted ? 64 : 58
            Layout.preferredHeight: isHighlighted ? 64 : 58
            radius: width / 2
            color: isHighlighted
                ? Qt.alpha(getOnCardColor(), 0.18)
                : (tileRoot.theme ? Qt.alpha(tileRoot.theme.getColor("surface"), 0.65) : "#20000000")

            Behavior on Layout.preferredWidth { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
            Behavior on Layout.preferredHeight { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
            Behavior on radius { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
            Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.OutQuad } }

            Item {
                anchors.centerIn: parent
                width: isHighlighted ? 30 : 26
                height: isHighlighted ? 30 : 26

                Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
                Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

                IconImage {
                    anchors.fill: parent
                    source: {
                        if (!tileRoot.itemData || !tileRoot.itemData.icon) return "";
                        var cfg = (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig);
                        return cfg ? cfg.getIcon(tileRoot.itemData.icon) : "";
                    }
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: getOnCardColor()
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Action Label
        UI.Typography {
            Layout.alignment: Qt.AlignHCenter
            theme: tileRoot.theme
            text: tileRoot.itemData ? tileRoot.itemData.label : ""
            variant: "titleMedium"
            font.bold: true
            font.pixelSize: isHighlighted ? 15.5 : 14.5
            horizontalAlignment: Text.AlignHCenter
            color: getOnCardColor()

            Behavior on font.pixelSize { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
            Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.OutQuad } }
        }
    }

    MouseArea {
        id: tileMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tileRoot.hoverEntered()
        onClicked: tileRoot.tileClicked()
    }
}
