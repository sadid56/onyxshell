import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../components/ui" as UI

PanelWindow {
    id: confirmModalRoot

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    visible: active

    property var theme
    property string title: "Confirm Action"
    property string message: "Are you sure you want to proceed?"
    property string icon: "system/power.svg"
    property string confirmText: "Confirm"
    property string cancelText: "Cancel"
    property bool isDanger: false
    property var onConfirmCallback: null
    property var onCancelCallback: null

    function ask(options) {
        if (!options) return;
        confirmModalRoot.title = options.title || "Confirm Action";
        confirmModalRoot.message = options.message || "Are you sure you want to proceed?";
        confirmModalRoot.icon = options.icon || "system/power.svg";
        confirmModalRoot.confirmText = options.confirmText || "Confirm";
        confirmModalRoot.cancelText = options.cancelText || "Cancel";
        confirmModalRoot.isDanger = (options.isDanger === true);
        confirmModalRoot.onConfirmCallback = options.onConfirm || null;
        confirmModalRoot.onCancelCallback = options.onCancel || null;
        confirmModalRoot.active = true;
        Qt.callLater(() => modalFocusScope.forceActiveFocus());
    }

    function confirm() {
        var cb = confirmModalRoot.onConfirmCallback;
        confirmModalRoot.active = false;
        if (typeof cb === "function") {
            cb();
        }
    }

    function cancel() {
        var cb = confirmModalRoot.onCancelCallback;
        confirmModalRoot.active = false;
        if (typeof cb === "function") {
            cb();
        }
    }

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: confirmModalRoot.cancel()
        }
    }

    FocusScope {
        id: modalFocusScope
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                confirmModalRoot.cancel();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                confirmModalRoot.confirm();
                event.accepted = true;
            }
        }

        Rectangle {
            id: modalDialog
            anchors.centerIn: parent
            width: 360
            height: modalContentCol.implicitHeight + 48
            radius: 24
            color: confirmModalRoot.theme ? confirmModalRoot.theme.getColor("surface") : "#232323"
            border.width: 0

            scale: confirmModalRoot.active ? 1.0 : 0.92
            opacity: confirmModalRoot.active ? 1.0 : 0.0

            Behavior on scale {
                NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }
            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            layer.enabled: confirmModalRoot.active
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#40000000"
                shadowBlur: 1.0
                shadowVerticalOffset: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: modalContentCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 24
                spacing: 16

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 58
                    height: 58
                    radius: 29
                    border.width: 0
                    color: confirmModalRoot.isDanger
                           ? (confirmModalRoot.theme ? Qt.rgba(confirmModalRoot.theme.getColor("error").r, confirmModalRoot.theme.getColor("error").g, confirmModalRoot.theme.getColor("error").b, 0.16) : "#33ff0000")
                           : (confirmModalRoot.theme ? Qt.rgba(confirmModalRoot.theme.getColor("primary").r, confirmModalRoot.theme.getColor("primary").g, confirmModalRoot.theme.getColor("primary").b, 0.16) : "#330088ff")

                    IconImage {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(confirmModalRoot.icon)
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: confirmModalRoot.isDanger
                                               ? (confirmModalRoot.theme ? confirmModalRoot.theme.getColor("error") : "#FF5555")
                                               : (confirmModalRoot.theme ? confirmModalRoot.theme.getColor("primary") : "#ADC6FF")
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    UI.Typography {
                        Layout.fillWidth: true
                        theme: confirmModalRoot.theme
                        text: confirmModalRoot.title
                        variant: "titleMedium"
                        font.pixelSize: 18
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        colorRole: "onSurface"
                    }

                    UI.Typography {
                        Layout.fillWidth: true
                        theme: confirmModalRoot.theme
                        text: confirmModalRoot.message
                        variant: "bodyMedium"
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        colorRole: "outline"
                    }
                }

                Item { Layout.preferredHeight: 4 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        id: cancelBtn
                        Layout.fillWidth: true
                        height: 42
                        radius: 12
                        border.width: 0
                        color: cancelMouse.containsMouse
                               ? (confirmModalRoot.theme ? Qt.lighter(confirmModalRoot.theme.getColor("surfaceVariant"), 1.08) : "#383838")
                               : (confirmModalRoot.theme ? confirmModalRoot.theme.getColor("surfaceVariant") : "#2b2a27")

                        Behavior on color { ColorAnimation { duration: 140 } }

                        UI.Typography {
                            anchors.centerIn: parent
                            theme: confirmModalRoot.theme
                            text: confirmModalRoot.cancelText
                            variant: "labelMedium"
                            font.pixelSize: 13
                            font.bold: true
                            colorRole: "onSurface"
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: confirmModalRoot.cancel()
                        }
                    }

                    Rectangle {
                        id: confirmActionBtn
                        Layout.fillWidth: true
                        height: 42
                        radius: 12
                        border.width: 0
                        color: confirmModalRoot.isDanger
                               ? (confirmActionMouse.containsMouse
                                  ? (confirmModalRoot.theme ? Qt.darker(confirmModalRoot.theme.getColor("error"), 1.12) : "#cc3333")
                                  : (confirmModalRoot.theme ? confirmModalRoot.theme.getColor("error") : "#e04444"))
                               : (confirmActionMouse.containsMouse
                                  ? (confirmModalRoot.theme ? Qt.darker(confirmModalRoot.theme.getColor("primary"), 1.1) : "#9ab8ff")
                                  : (confirmModalRoot.theme ? confirmModalRoot.theme.getColor("primary") : "#adc6ff"))

                        Behavior on color { ColorAnimation { duration: 140 } }

                        UI.Typography {
                            anchors.centerIn: parent
                            theme: confirmModalRoot.theme
                            text: confirmModalRoot.confirmText
                            variant: "labelMedium"
                            font.pixelSize: 13
                            font.bold: true
                            color: confirmModalRoot.isDanger
                                   ? (confirmModalRoot.theme ? confirmModalRoot.theme.getColor("onError") : "#FFFFFF")
                                   : (confirmModalRoot.theme ? confirmModalRoot.theme.getColor("onPrimary") : "#000000")
                        }

                        MouseArea {
                            id: confirmActionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: confirmModalRoot.confirm()
                        }
                    }
                }
            }
        }
    }
}
