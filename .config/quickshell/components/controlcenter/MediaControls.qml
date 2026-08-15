import QtQuick
import QtQuick.Layouts

Rectangle {
    id: mediaRoot
    Layout.fillWidth: true
    height: 120
    radius: 16
    color: mediaRoot.theme.getColor("surfaceVariant")

    property var theme
    property string mediaStatus: "Stopped"
    property string mediaTitle: "No media playing"
    property string mediaArtist: ""
    property int mediaPosition: 0
    property int mediaLength: 0
    signal controlAction(string action)

    // Format position/length from seconds to MM:SS
    function formatTime(secs) {
        if (isNaN(secs) || secs < 0) return "00:00";
        var m = Math.floor(secs / 60);
        var s = secs % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    // Local ticker to increment position when playing
    Timer {
        id: progressTicker
        interval: 1000
        running: mediaRoot.mediaStatus === "Playing"
        repeat: true
        onTriggered: {
            if (mediaRoot.mediaPosition < mediaRoot.mediaLength) {
                mediaRoot.mediaPosition += 1;
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        // Disc Icon (Left side) with rotating animation when playing
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: mediaRoot.theme.getColor("surface")
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: discIcon
                anchors.centerIn: parent
                text: "󰎆" // Music disc icon
                font.family: "Noto Sans"
                font.pixelSize: 22
                color: mediaRoot.theme.getColor("primary")

                RotationAnimation on rotation {
                    id: discAnim
                    from: 0
                    to: 360
                    duration: 6000
                    loops: Animation.Infinite
                    running: mediaRoot.mediaStatus === "Playing"
                }
            }
        }

        // Title, Progress & Controls (Right side)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            // Title & Artist Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: mediaRoot.mediaTitle
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 13
                    font.bold: true
                    color: mediaRoot.theme.getColor("onSurface")
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: mediaRoot.mediaArtist !== "" ? mediaRoot.mediaArtist : "Unknown Artist"
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 10
                    color: mediaRoot.theme.getColor("outline")
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Progress Bar & Timer
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Wavy Progress Bar Canvas
                Canvas {
                    id: waveCanvas
                    Layout.fillWidth: true
                    height: 12
                    
                    property real phase: 0
                    property real progressWidth: mediaRoot.mediaLength > 0 ? 
                                                     width * (mediaRoot.mediaPosition / mediaRoot.mediaLength) : 0

                    onProgressWidthChanged: requestPaint()

                    // Smooth transition on progress width changes
                    Behavior on progressWidth {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    // Ticking timer for the wave animation
                    Timer {
                        id: waveTimer
                        interval: 33 // ~30 fps
                        running: mediaRoot.mediaStatus === "Playing"
                        repeat: true
                        onTriggered: {
                            waveCanvas.phase += 0.15;
                            waveCanvas.requestPaint();
                        }
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.clearRect(0, 0, width, height);

                        var midY = height / 2;

                        // 1. Draw Active Wave (Played part)
                        ctx.beginPath();
                        ctx.lineWidth = 2.5;
                        ctx.strokeStyle = mediaRoot.theme.getColor("primary");

                        if (progressWidth > 0) {
                            ctx.moveTo(0, midY);
                            for (var x = 0; x <= progressWidth; x++) {
                                // Sine wave calculation: y = midY + Math.sin(x * frequency - phase) * amplitude
                                var y = midY + Math.sin(x * 0.08 - phase) * 2.5;
                                ctx.lineTo(x, y);
                            }
                            ctx.stroke();
                        }

                        // 2. Draw Inactive Flat Line (Unplayed part)
                        ctx.beginPath();
                        ctx.lineWidth = 2;
                        ctx.strokeStyle = mediaRoot.theme.getColor("surface");
                        ctx.moveTo(progressWidth, midY);
                        ctx.lineTo(width, midY);
                        ctx.stroke();
                    }
                }

                // Time Counter (e.g. 01:23 / 03:45)
                Text {
                    text: mediaRoot.mediaLength > 0 ? 
                              mediaRoot.formatTime(mediaRoot.mediaPosition) + " / " + mediaRoot.formatTime(mediaRoot.mediaLength) : 
                              "00:00 / 00:00"
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 9
                    font.bold: true
                    color: mediaRoot.theme.getColor("outline")
                }
            }

            // Media Buttons (Prev, Play, Next)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                // Prev Button
                Text {
                    text: "󰒮"
                    font.family: "Noto Sans"
                    font.pixelSize: 18
                    color: mediaRoot.theme.getColor("primary")
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scale = 1.2
                        onExited: parent.scale = 1.0
                        onClicked: mediaRoot.controlAction("previous")
                    }
                    Behavior on scale { NumberAnimation { duration: 150 } }
                }

                // Play / Pause Circle Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: mediaRoot.theme.getColor("primary")

                    Text {
                        anchors.centerIn: parent
                        text: mediaRoot.mediaStatus === "Playing" ? "󰏤" : "󰐊"
                        font.family: "Noto Sans"
                        font.pixelSize: 16
                        color: mediaRoot.theme.getColor("onPrimary")
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scale = 1.15
                        onExited: parent.scale = 1.0
                        onClicked: mediaRoot.controlAction("play-pause")
                    }
                    Behavior on scale { NumberAnimation { duration: 150 } }
                }

                // Next Button
                Text {
                    text: "󰒭"
                    font.family: "Noto Sans"
                    font.pixelSize: 18
                    color: mediaRoot.theme.getColor("primary")
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scale = 1.2
                        onExited: parent.scale = 1.0
                        onClicked: mediaRoot.controlAction("next")
                    }
                    Behavior on scale { NumberAnimation { duration: 150 } }
                }
            }
        }
    }
}
