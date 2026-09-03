import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Rectangle {
    id: buttonRoot
    implicitWidth: buttonRoot.text !== "" ? (btnRow.implicitWidth + 24) : 32
    implicitHeight: 32
    radius: 10
    color: active
        ? (buttonRoot.theme ? buttonRoot.theme.getColor("primary") : "#c5c5d8")
        : (hoverArea.containsMouse
            ? (buttonRoot.theme ? buttonRoot.theme.getColor("surfaceVariant") : "#353642")
            : (buttonRoot.theme ? buttonRoot.theme.getColor("surfaceVariant") + "66" : "#282932"))
    opacity: 1.0
    border.width: 1
    border.color: buttonRoot.theme ? buttonRoot.theme.getColor("outlineVariant") + "33" : "#ffffff15"

    property var theme
    property string icon: ""
    property string text: ""
    property bool active: false
    property int iconSize: 16

    signal clicked()

    Behavior on color { ColorAnimation { duration: 150 } }

    readonly property string resolvedIcon: {
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

    readonly property bool isSvgIcon: resolvedIcon.endsWith(".svg") || resolvedIcon.startsWith("file://") || resolvedIcon.startsWith("/")

    RowLayout {
        id: btnRow
        anchors.fill: parent
        anchors.leftMargin: buttonRoot.text !== "" ? 12 : 0
        anchors.rightMargin: buttonRoot.text !== "" ? 12 : 0
        spacing: 8
        visible: buttonRoot.text !== ""

        IconImage {
            width: buttonRoot.iconSize
            height: buttonRoot.iconSize
            source: buttonRoot.isSvgIcon ? buttonRoot.resolvedIcon : ""
            visible: buttonRoot.isSvgIcon
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: buttonRoot.active
                    ? (buttonRoot.theme ? buttonRoot.theme.getColor("onPrimary") : "#1b1b22")
                    : (buttonRoot.theme ? buttonRoot.theme.getColor("onSurface") : "#ffffff")
            }
        }

        Typography {
            theme: buttonRoot.theme
            text: buttonRoot.icon
            mono: true
            font.pixelSize: 14
            font.bold: true
            color: buttonRoot.active
                ? (buttonRoot.theme ? buttonRoot.theme.getColor("onPrimary") : "#1b1b22")
                : (buttonRoot.theme ? buttonRoot.theme.getColor("onSurface") : "#ffffff")
            visible: buttonRoot.icon !== "" && !buttonRoot.isSvgIcon
            Layout.alignment: Qt.AlignVCenter
        }

        Typography {
            theme: buttonRoot.theme
            text: buttonRoot.text
            variant: "labelMedium"
            color: buttonRoot.active
                ? (buttonRoot.theme ? buttonRoot.theme.getColor("onPrimary") : "#1b1b22")
                : (buttonRoot.theme ? buttonRoot.theme.getColor("onSurface") : "#ffffff")
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignLeft
        }
    }

    Item {
        anchors.centerIn: parent
        width: buttonRoot.iconSize
        height: buttonRoot.iconSize
        visible: buttonRoot.text === ""

        IconImage {
            anchors.fill: parent
            source: buttonRoot.isSvgIcon ? buttonRoot.resolvedIcon : ""
            visible: buttonRoot.isSvgIcon
            asynchronous: true
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: buttonRoot.active
                    ? (buttonRoot.theme ? buttonRoot.theme.getColor("onPrimary") : "#1b1b22")
                    : (buttonRoot.theme ? buttonRoot.theme.getColor("onSurface") : "#ffffff")
            }
        }

        Typography {
            theme: buttonRoot.theme
            anchors.centerIn: parent
            text: buttonRoot.icon
            mono: true
            font.pixelSize: 15
            font.bold: true
            color: buttonRoot.active
                ? (buttonRoot.theme ? buttonRoot.theme.getColor("onPrimary") : "#1b1b22")
                : (buttonRoot.theme ? buttonRoot.theme.getColor("onSurface") : "#ffffff")
            visible: buttonRoot.icon !== "" && !buttonRoot.isSvgIcon
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            buttonRoot.clicked();
        }
    }
}
