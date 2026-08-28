import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Rectangle {
    id: btnRoot

    property var theme
    property string icon: ""
    property int iconSize: 16
    property int buttonSize: 28
    property int customRadius: -1
    property alias size: btnRoot.buttonSize
    property alias radius: btnRoot.customRadius
    radius: (customRadius >= 0) ? customRadius : (buttonSize / 2)
    property color iconColor: theme ? theme.getColor("onSurface") : "#ffffff"
    property color hoverIconColor: theme ? theme.getColor("primary") : iconColor
    property color normalBgColor: "transparent"
    property color hoverBgColor: "transparent"
    property bool active: false

    signal clicked()

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    width: buttonSize
    height: buttonSize

    color: (mouseArea.containsMouse || active) ? hoverBgColor : normalBgColor

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btnRoot.clicked()
    }

    readonly property string resolvedSource: {
        if (!icon || icon === "") return "";
        if (icon.indexOf("/") === 0) return "file://" + icon;
        if (icon.indexOf("file://") === 0 || icon.indexOf("http://") === 0 || icon.indexOf("https://") === 0 || icon.indexOf("qrc:/") === 0) {
            return icon;
        }
        var cfg = (typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : ((typeof root !== "undefined" && root.shellConfig) ? root.shellConfig : null);
        if (cfg && typeof cfg.getIcon === "function") {
            return cfg.getIcon(icon);
        }
        return icon;
    }

    readonly property color currentIconColor: (mouseArea.containsMouse || active) ? hoverIconColor : iconColor

    IconImage {
        anchors.centerIn: parent
        width: btnRoot.iconSize
        height: btnRoot.iconSize
        source: btnRoot.resolvedSource
        asynchronous: true
        scale: mouseArea.containsMouse ? 1.25 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: btnRoot.currentIconColor
        }
    }
}
