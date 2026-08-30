import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../components/ui" as UI

Rectangle {
    id: tileRoot
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: isHighlighted ? 130 : 115
    implicitHeight: isHighlighted ? 180 : 160
    radius: 32
    clip: true

    property var theme: null
    property var itemData: null
    property bool isSelected: false
    property bool isHovered: tileMouseArea.containsMouse
    readonly property bool isHighlighted: isHovered || isSelected
    signal tileClicked()

    readonly property string role: itemData ? (itemData.role || "primary") : "primary"
    readonly property bool isDanger: role === "error"

    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    function getCardBg() {
        if (!tileRoot.theme) return isHighlighted ? "#ffb3b4" : "#2c2834";
        if (isHighlighted) {
            if (role === "error") return tileRoot.theme.getColor("error") || "#ff5449";
            if (role === "tertiary") return tileRoot.theme.getColor("tertiary") || "#ffb875";
            if (role === "secondary") return tileRoot.theme.getColor("secondary") || "#c8bfff";
            return tileRoot.theme.getColor("primary") || "#ffb3b4";
        }
        return Qt.alpha(tileRoot.theme.getColor("surfaceVariant"), 0.55);
    }

    function getOnCardColor() {
        if (!isHighlighted) {
            return tileRoot.theme ? tileRoot.theme.getColor("onSurface") : "#ffffff";
        }
        if (role === "error") {
            return tileRoot.theme ? (tileRoot.theme.getColor("onError") || "#ffffff") : "#ffffff";
        }
        if (role === "tertiary") {
            return "#000000";
        }
        if (role === "secondary") {
            return tileRoot.theme ? (tileRoot.theme.getColor("onSecondary") || "#000000") : "#000000";
        }
        return tileRoot.theme ? (tileRoot.theme.getColor("onPrimary") || "#000000") : "#000000";
    }

    color: getCardBg()
    border.width: 1
    border.color: isHighlighted
        ? Qt.alpha(getOnCardColor(), 0.3)
        : (tileRoot.theme ? Qt.alpha(tileRoot.theme.getColor("outlineVariant"), 0.20) : "#15ffffff")

    Behavior on color { ColorAnimation { duration: 160 } }
    Behavior on border.color { ColorAnimation { duration: 160 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 24
        anchors.bottomMargin: 24
        spacing: 0

        // Circular Icon Badge
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            radius: 30
            color: isHighlighted
                ? Qt.alpha(getOnCardColor(), 0.16)
                : (tileRoot.theme ? Qt.alpha(tileRoot.theme.getColor("surface"), 0.65) : "#20000000")

            Behavior on color { ColorAnimation { duration: 140 } }

            Item {
                anchors.centerIn: parent
                width: 28
                height: 28

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
            font.pixelSize: 15
            horizontalAlignment: Text.AlignHCenter
            color: getOnCardColor()

            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }

    MouseArea {
        id: tileMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tileRoot.tileClicked()
    }
}
