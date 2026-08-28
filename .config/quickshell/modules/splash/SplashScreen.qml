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
                    spacing: 24

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 72
                        height: 72

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
                                from: 0.95
                                to: 1.05
                                duration: 900
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: splashLogo
                                property: "scale"
                                from: 1.05
                                to: 0.95
                                duration: 900
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        UI.Typography {
                            theme: splashScope.theme
                            text: "Welcome"
                            variant: "titleLarge"
                            font.pixelSize: 20
                            colorRole: "onSurface"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        UI.Typography {
                            theme: splashScope.theme
                            text: "Starting desktop session..."
                            variant: "labelMedium"
                            colorRole: "outline"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 180
                        height: 4
                        radius: 2
                        color: splashScope.theme ? splashScope.theme.getColor("surfaceVariant") : "#2B2831"
                        clip: true

                        Rectangle {
                            id: progressPill
                            width: 60
                            height: parent.height
                            radius: 2
                            color: splashScope.theme ? splashScope.theme.getColor("primary") : "#D0BCFF"

                            SequentialAnimation {
                                running: !splashScope.isFinished
                                loops: Animation.Infinite
                                NumberAnimation {
                                    target: progressPill
                                    property: "x"
                                    from: -60
                                    to: 180
                                    duration: 1000
                                    easing.type: Easing.InOutCubic
                                }
                            }
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
