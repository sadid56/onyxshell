import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "./controlcenter"

PanelWindow {
    id: controlWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    property var theme
    property bool active: false

    property int volumeValue: 50
    property int brightnessValue: 50
    property string themeMode: "dark"
    property string mediaStatus: "Stopped"
    property string mediaTitle: "No media playing"
    property string mediaArtist: ""

    property bool powerMenuExpanded: false

    visible: active || hideTimer.running

    onActiveChanged: {
        if (!active) {
            hideTimer.start();
        } else {
            hideTimer.stop();
            statsFetcher.running = false;
            statsFetcher.running = true;
        }
    }

    Timer {
        id: hideTimer
        interval: 250
        running: false
        repeat: false
    }

    // Refresh system stats periodically when open
    Timer {
        id: refreshTimer
        interval: 1000
        running: controlWindow.active
        repeat: true
        onTriggered: {
            statsFetcher.running = false;
            statsFetcher.running = true;
        }
    }

    // Process to run commands to fetch volume, brightness, media
    Process {
        id: statsFetcher
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@; brightnessctl -m; playerctl -a metadata --format '{{status}}::{{title}}::{{artist}}' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split('\n');
                if (lines.length > 0) {
                    var volLine = lines[0].trim();
                    var match = volLine.match(/Volume:\s+([0-9.]+)/);
                    if (match) {
                        controlWindow.volumeValue = Math.round(parseFloat(match[1]) * 100);
                    }
                }
                if (lines.length > 1) {
                    var brightLine = lines[1].trim();
                    var parts = brightLine.split(',');
                    if (parts.length >= 4) {
                        var percentStr = parts[3].replace('%', '');
                        var val = parseInt(percentStr);
                        if (!isNaN(val)) {
                            controlWindow.brightnessValue = val;
                        }
                    }
                }
                if (lines.length > 2) {
                    var mediaLine = lines[2].trim();
                    if (mediaLine !== "") {
                        var mParts = mediaLine.split('::');
                        controlWindow.mediaStatus = mParts[0] || "Unknown";
                        controlWindow.mediaTitle = mParts[1] || "No media playing";
                        controlWindow.mediaArtist = mParts[2] || "";
                    } else {
                        controlWindow.mediaStatus = "Stopped";
                        controlWindow.mediaTitle = "No media playing";
                        controlWindow.mediaArtist = "";
                    }
                }
            }
        }
    }

    // Processes to change settings
    Process {
        id: volumeSetter
        function startProc() {
            volumeSetter.running = true;
        }
        function setVolume(val) {
            command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (val / 100).toFixed(2)];
            running = false;
            Qt.callLater(startProc);
        }
    }

    Process {
        id: brightnessSetter
        function startProc() {
            brightnessSetter.running = true;
        }
        function setBrightness(val) {
            command = ["brightnessctl", "set", val + "%"];
            running = false;
            Qt.callLater(startProc);
        }
    }

    Process {
        id: mediaControl
        function runCmd(cmd) {
            command = ["playerctl", cmd];
            running = false;
            running = true;
            // Instantly refresh after command
            refreshTimer.restart();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: controlWindow.active
        onActivated: controlWindow.active = false
    }

    // Capture clicks outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: controlWindow.active = false
    }

    Rectangle {
        id: contentRect
        y: 4
        // Slide in from right to left
        x: controlWindow.active ? parent.width - width - 16 : parent.width + 10
        width: 360
        height: 600
        radius: 20
        color: controlWindow.theme.getColor("surface")
        border.width: 1
        border.color: controlWindow.theme.getColor("surfaceVariant")

        // Prevent click through
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        opacity: controlWindow.active ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // Header Section
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Control Center"
                    font.family: "Noto Sans"
                    font.pixelSize: 18
                    font.bold: true
                    color: controlWindow.theme.getColor("onSurface")
                    Layout.fillWidth: true
                }

                // Close Button
                Text {
                    text: "󰅖"
                    font.family: "Noto Sans"
                    font.pixelSize: 18
                    color: controlWindow.theme.getColor("primary")
                    font.bold: true
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controlWindow.active = false
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: controlWindow.theme.getColor("surfaceVariant")
            }

            // Theme switching


            // Sliders Container
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                // Volume Controls
                VolumeSlider {
                    theme: controlWindow.theme
                    volumeValue: controlWindow.volumeValue
                    onVolumeMoved: val => {
                        controlWindow.volumeValue = val;
                        volumeSetter.setVolume(val);
                    }
                }

                // Brightness Controls
                BrightnessSlider {
                    theme: controlWindow.theme
                    brightnessValue: controlWindow.brightnessValue
                    onBrightnessMoved: val => {
                        controlWindow.brightnessValue = val;
                        brightnessSetter.setBrightness(val);
                    }
                }
            }

            // Media Player Card
            MediaControls {
                theme: controlWindow.theme
                mediaStatus: controlWindow.mediaStatus
                mediaTitle: controlWindow.mediaTitle
                mediaArtist: controlWindow.mediaArtist
                onControlAction: act => {
                    controlWindow.mediaControl.runCmd(act);
                }
            }

            Item { Layout.fillHeight: true }

            // Power Actions Menu
            PowerGrid {
                theme: controlWindow.theme
                expanded: controlWindow.powerMenuExpanded
                onClosed: {
                    controlWindow.active = false;
                }
            }
        }
    }
}
