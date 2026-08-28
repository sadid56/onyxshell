import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../components/ui" as UI

Rectangle {
    id: tileRoot

    property var theme: null
    property var itemData: null
    property bool isSelected: false
    property bool isHovered: tileMouseArea.containsMouse
    readonly property bool isHighlighted: isHovered || isSelected
    signal tileClicked()

    readonly property bool isDanger: itemData ? Boolean(itemData.isDanger) : false

    radius: 20
    border.width: 0

    color: isHighlighted
        ? (isDanger
            ? (tileRoot.theme ? tileRoot.theme.getColor("error") : "#ff5449")
            : (tileRoot.theme ? tileRoot.theme.getColor("primaryContainer") : "#3d4258"))
        : (tileRoot.theme ? Qt.alpha(tileRoot.theme.getColor("surfaceVariant"), 0.45) : "#222129")

    Behavior on color { ColorAnimation { duration: 160 } }

    MouseArea {
        id: tileMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            if (typeof root !== "undefined" && typeof powerMenuLoader !== "undefined") {
                root.stopLoaderTimerAndActivate(powerMenuLoader);
            }
        }
        onPositionChanged: {
            if (typeof root !== "undefined" && typeof powerMenuLoader !== "undefined") {
                root.stopLoaderTimerAndActivate(powerMenuLoader);
            }
        }
        onClicked: tileRoot.tileClicked()
    }

    Item {
        anchors.centerIn: parent
        width: 36
        height: 36

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
                colorizationColor: tileRoot.isHighlighted
                    ? (tileRoot.isDanger
                        ? (tileRoot.theme ? tileRoot.theme.getColor("onError") : "#ffffff")
                        : (tileRoot.theme ? tileRoot.theme.getColor("onPrimaryContainer") : "#ffffff"))
                    : (tileRoot.isDanger
                        ? (tileRoot.theme ? tileRoot.theme.getColor("error") : "#ff5449")
                        : (tileRoot.theme ? tileRoot.theme.getColor("onSurface") : "#e6e1e5"))
            }
        }
    }
}
