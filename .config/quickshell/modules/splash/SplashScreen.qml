import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import "../../core"
import "../../components/ui" as UI

Scope {
    id: splashScope

    property var theme: null
    property bool isFadingOut: false

    property bool isFinished: (Quickshell.env("QUICKSHELL_NO_SPLASH") === "1" || Quickshell.env("QUICKSHELL_RELOAD") === "1")

    Variants {
        model: splashScope.isFinished ? [] : Quickshell.screens
        delegate: PanelWindow {
            id: splashWindow
            property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"

            Rectangle {
                id: splashRootRect
                anchors.fill: parent
                color: splashScope.theme ? splashScope.theme.getColor("surface") : "#1b1111"
                opacity: 1.0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 32

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 128
                        height: 128

                        IconImage {
                            id: splashLogo
                            anchors.fill: parent
                            source: (typeof shellConfig !== "undefined" && shellConfig) ? shellConfig.getDistroIcon() : ""
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = (typeof shellConfig !== "undefined" && shellConfig) ? shellConfig.defaultAppIcon : "";
                                }
                            }
                        }

                        SequentialAnimation {
                            running: !splashScope.isFinished
                            loops: Animation.Infinite
                            NumberAnimation {
                                target: splashLogo
                                property: "scale"
                                from: 0.97
                                to: 1.03
                                duration: 900
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: splashLogo
                                property: "scale"
                                from: 1.03
                                to: 0.97
                                duration: 900
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 28
                        height: 28

                        Canvas {
                            id: spinnerCanvas
                            anchors.fill: parent
                            antialiasing: true
                            renderTarget: Canvas.FramebufferObject

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.clearRect(0, 0, width, height);
                                ctx.lineWidth = 2.5;
                                ctx.lineCap = "round";
                                ctx.strokeStyle = splashScope.theme ? splashScope.theme.getColor("primary") : "#c5c5d8";
                                ctx.beginPath();
                                ctx.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 1.35);
                                ctx.stroke();
                            }
                        }

                        RotationAnimator {
                            target: spinnerCanvas
                            from: 0
                            to: 360
                            duration: 750
                            loops: Animation.Infinite
                            running: !splashScope.isFinished
                        }
                    }
                }

                Timer {
                    id: hideTimer
                    interval: 1000
                    running: !splashScope.isFinished
                    onTriggered: {
                        splashScope.isFadingOut = true;
                        fadeOutAnim.start();
                    }
                }

                NumberAnimation {
                    id: fadeOutAnim
                    target: splashRootRect
                    property: "opacity"
                    to: 0
                    duration: 480
                    easing.type: Easing.OutCubic
                    onFinished: {

                        splashScope.isFinished = true;
                    }
                }
            }
        }
    }
}
