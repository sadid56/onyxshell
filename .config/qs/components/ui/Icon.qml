import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Item {
    id: iconRoot

    property string icon: ""
    property string source: ""
    property int size: 16
    property color color: "transparent"
    property var theme

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    readonly property string resolvedSource: {
        var src = icon !== "" ? icon : source;
        if (!src || src === "") return "";
        if (src.indexOf("/") === 0) return "file://" + src;
        if (src.indexOf("file://") === 0 || src.indexOf("http://") === 0 || src.indexOf("https://") === 0 || src.indexOf("qrc:/") === 0) {
            return src;
        }
        var cfg = (typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : ((typeof root !== "undefined" && root.shellConfig) ? root.shellConfig : null);
        if (cfg && typeof cfg.getIcon === "function") {
            return cfg.getIcon(src);
        }
        return src;
    }

    readonly property bool hasColorization: color !== "transparent" && color.a > 0

    IconImage {
        id: img
        anchors.fill: parent
        source: iconRoot.resolvedSource
        asynchronous: true
        layer.enabled: iconRoot.hasColorization
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: iconRoot.color
        }
    }
}
