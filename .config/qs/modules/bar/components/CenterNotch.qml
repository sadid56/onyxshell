import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../widgets"
import "../../../components/ui" as UI

Item {
    id: notchRoot

    property var barWindow
    property var clockItem: clockItem

    readonly property bool hasNotif: barWindow && barWindow.activeNotifData !== null
    readonly property bool hasCenterPopup: barWindow ? (barWindow.centerPopupTargetWidth > 0) : false

    readonly property real currentWidth: {
        if (!barWindow) return 200;
        if (hasCenterPopup) return barWindow.centerPopupTargetWidth;
        if (hasNotif) return notifRow.implicitWidth + 36;
        return (typeof clockItem !== "undefined" && clockItem) ? (clockItem.implicitWidth + 32) : 200;
    }

    width: currentWidth
    height: barWindow ? barWindow.barHeight : 40

    Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

    Rectangle {
        id: notchBackground
        anchors.fill: parent
        color: barWindow ? barWindow.barSurfaceColor : "#1e1e2e"
        radius: barWindow ? barWindow.barCornerRadius : 16

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.radius
            color: parent.color
        }
    }

    Clock {
        id: clockItem
        theme: barWindow ? barWindow.theme : null
        toggleCalendar: barWindow ? barWindow.toggleCalendar : null
        toggleNotifications: barWindow ? barWindow.toggleNotifications : null
        notifCount: barWindow ? barWindow.notifCount : 0
        hasNotif: notchRoot.hasNotif || Boolean(barWindow && barWindow.notifDismissCooldown && barWindow.notifDismissCooldown.running)
        anchors.fill: parent
        opacity: (notchRoot.hasNotif || notchRoot.hasCenterPopup) ? 0.0 : 1.0
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutQuad
            }
        }
    }

    MouseArea {
        id: notifInlineArea
        anchors.fill: parent
        z: 10
        opacity: notchRoot.hasNotif ? 1.0 : 0.0
        scale: notchRoot.hasNotif ? 1.0 : 0.85
        visible: notchRoot.hasNotif
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }

        onClicked: {
            if (barWindow) barWindow.triggerNotificationAction();
        }

        RowLayout {
            id: notifRow
            spacing: 8
            anchors.centerIn: parent

            Item {
                width: 20
                height: 20
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: (barWindow && barWindow.theme) ? barWindow.theme.getColor("primaryContainer") : "#34343c"
                    clip: true

                    UI.Typography {
                        anchors.centerIn: parent
                        text: (barWindow && barWindow.activeNotifData && barWindow.activeNotifData.isEmoji) ? barWindow.activeNotifData.emojiChar : ""
                        font.pixelSize: 13
                        visible: Boolean(barWindow && barWindow.activeNotifData && barWindow.activeNotifData.isEmoji)
                    }

                    IconImage {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        visible: !(barWindow && barWindow.activeNotifData && barWindow.activeNotifData.isEmoji)
                        source: {
                            if (!barWindow || !barWindow.activeNotifData || barWindow.activeNotifData.isEmoji) return "";
                            var cfg = ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : (typeof root !== "undefined" ? root.shellConfig : null));
                            var ic = barWindow.activeNotifData.appIcon || "";
                            var app = (barWindow.activeNotifData.appName || "").toLowerCase();
                            var sum = (barWindow.activeNotifData.summary || "").toLowerCase();

                            if (app.indexOf("hyprshot") !== -1 || app.indexOf("screenshot") !== -1 || sum.indexOf("screenshot") !== -1 || sum.indexOf("hyprshot") !== -1) {
                                if (cfg && cfg.getIcon) return cfg.getIcon("actions/crop.svg");
                                return "file://" + (Quickshell.env("HOME") + "/.config/qs/assets/icons/actions/crop.svg");
                            }

                            if (ic) {
                                if (ic.indexOf("/") === 0) return "file://" + ic;
                                if (ic.startsWith("file://") || ic.startsWith("image://") || ic.startsWith("qrc:/")) return ic;
                                if (cfg && cfg.getIcon && (ic.indexOf("/") !== -1 || ic.endsWith(".svg"))) {
                                    return cfg.getIcon(ic);
                                }
                                return "image://icon/" + ic;
                            }

                            if (cfg && cfg.defaultAppIcon) return "file://" + cfg.defaultAppIcon;
                            return "file://" + (Quickshell.env("HOME") + "/.config/qs/assets/icons/system/default-app.svg");
                        }

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: (barWindow && barWindow.theme) ? barWindow.theme.getColor("onPrimaryContainer") : "#ffffff"
                        }
                    }
                }
            }

            UI.Typography {
                theme: barWindow ? barWindow.theme : null
                variant: "bodyMedium"
                font.bold: true
                colorRole: "primary"
                text: (barWindow && barWindow.activeNotifData && barWindow.activeNotifData.appName) ? (barWindow.activeNotifData.appName + ":") : ""
                visible: text !== ""
                Layout.alignment: Qt.AlignVCenter
            }

            UI.Typography {
                theme: barWindow ? barWindow.theme : null
                variant: "bodyMedium"
                colorRole: "onSurface"
                text: {
                    if (!barWindow || !barWindow.activeNotifData) return "";
                    var s = barWindow.activeNotifData.summary || "";
                    var b = barWindow.activeNotifData.body || "";
                    if (s && b) return s + " — " + b;
                    return s || b;
                }
                Layout.maximumWidth: 340
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
