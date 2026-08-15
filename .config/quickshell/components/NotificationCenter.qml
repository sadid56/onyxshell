import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import "./controlcenter"


BasePopup {
    id: notifWindow

    popupWidth: 460
    popupHeight: notifWindow.height + 14
    topOverlap: 14
    flatBottom: true

    property var activeNotifs: []
    property int notifCount: activeNotifs.length

    // Control Center settings state
    property int volumeValue: 50
    property int brightnessValue: 50
    property string mediaStatus: "Stopped"
    property string mediaTitle: "No media playing"
    property string mediaArtist: ""
    property int mediaPosition: 0
    property int mediaLength: 0
    property bool powerMenuExpanded: false

    // Quick Action toggle states
    property bool wifiEnabled: true
    property bool isMuted: false

    // Quick Action Processes
    Process { id: wifiToggleProc }
    Process { id: muteToggleProc }
    Process {
        id: hyprpickerProc
        command: ["hyprpicker", "-a"]
    }
    Process {
        id: screenshotProc
        command: ["hyprshot", "-m", "region", "-o", "/home/sadid/Pictures/Screenshots"]
    }

    onActiveChanged: {
        if (active) {
            statsFetcher.running = false;
            statsFetcher.running = true;
        }
    }

    // Refresh control center stats periodically when active
    Timer {
        id: refreshTimer
        interval: 1000
        running: notifWindow.active
        repeat: true
        onTriggered: {
            statsFetcher.running = false;
            statsFetcher.running = true;
        }
    }

    // Process to fetch volume, brightness, media, wifi status
    Process {
        id: statsFetcher
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@; brightnessctl -m; playerctl metadata --format '{{status}}::{{title}}::{{artist}}::{{position}}::{{mpris:length}}' 2>/dev/null; nmcli radio wifi 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split('\n');
                if (lines.length > 0) {
                    var volLine = lines[0].trim();
                    var match = volLine.match(/Volume:\s+([0-9.]+)/);
                    if (match) {
                        notifWindow.volumeValue = Math.round(parseFloat(match[1]) * 100);
                    }
                    // Detect [MUTED] in the volume line
                    notifWindow.isMuted = volLine.indexOf("[MUTED]") !== -1;
                }
                if (lines.length > 1) {
                    var brightLine = lines[1].trim();
                    var parts = brightLine.split(',');
                    if (parts.length >= 4) {
                        var percentStr = parts[3].replace('%', '');
                        var val = parseInt(percentStr);
                        if (!isNaN(val)) {
                            notifWindow.brightnessValue = val;
                        }
                    }
                }
                if (lines.length > 2) {
                    var mediaLine = lines[2].trim();
                    if (mediaLine !== "") {
                        var mParts = mediaLine.split('::');
                        notifWindow.mediaStatus = mParts[0] || "Unknown";
                        notifWindow.mediaTitle = mParts[1] || "No media playing";
                        notifWindow.mediaArtist = mParts[2] || "";
                        var posUs = parseInt(mParts[3]) || 0;
                        var lenUs = parseInt(mParts[4]) || 0;
                        notifWindow.mediaPosition = Math.round(posUs / 1000000);
                        notifWindow.mediaLength = Math.round(lenUs / 1000000);
                    } else {
                        notifWindow.mediaStatus = "Stopped";
                        notifWindow.mediaTitle = "No media playing";
                        notifWindow.mediaArtist = "";
                        notifWindow.mediaPosition = 0;
                        notifWindow.mediaLength = 0;
                    }
                }
                if (lines.length > 3) {
                    var wifiLine = lines[3].trim();
                    notifWindow.wifiEnabled = (wifiLine === "enabled");
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

            // Instantly toggle local state for immediate visual feedback (optimistic update)
            if (cmd === "play-pause") {
                if (notifWindow.mediaStatus === "Playing") {
                    notifWindow.mediaStatus = "Paused";
                } else {
                    notifWindow.mediaStatus = "Playing";
                }
            } else if (cmd === "next" || cmd === "previous") {
                // Immediately query player metadata instead of waiting for the 1s timer tick
                statsFetcher.running = false;
                statsFetcher.running = true;
            }

            refreshTimer.restart();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: notifWindow.active
        onActivated: notifWindow.active = false
    }

    // 1. Media Controls (Very Top)
    MediaControls {
        theme: notifWindow.theme
        mediaStatus: notifWindow.mediaStatus
        mediaTitle: notifWindow.mediaTitle
        mediaArtist: notifWindow.mediaArtist
        mediaPosition: notifWindow.mediaPosition
        mediaLength: notifWindow.mediaLength
        onControlAction: act => {
            mediaControl.runCmd(act);
        }
    }

    // 2. Sliders (Volume & Brightness)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        VolumeSlider {
            theme: notifWindow.theme
            volumeValue: notifWindow.volumeValue
            onVolumeMoved: val => {
                notifWindow.volumeValue = val;
                volumeSetter.setVolume(val);
            }
        }

        BrightnessSlider {
            theme: notifWindow.theme
            brightnessValue: notifWindow.brightnessValue
            onBrightnessMoved: val => {
                notifWindow.brightnessValue = val;
                brightnessSetter.setBrightness(val);
            }
        }
    }

    // 3. Divider
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: notifWindow.theme.getColor("surfaceVariant")
    }

    // 4. Notifications Section (Center, taking remaining height)
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "Notifications"
                font.family: "Noto Sans"
                font.pixelSize: 15
                font.bold: true
                color: notifWindow.theme.getColor("onSurface")
                Layout.fillWidth: true
            }

            // Clear All Button
            Text {
                text: "Clear All"
                font.family: "Noto Sans"
                font.pixelSize: 11
                font.bold: true
                color: notifWindow.theme.getColor("primary")
                visible: notifWindow.activeNotifs.length > 0
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var temp = notifWindow.activeNotifs;
                        for (var i = temp.length - 1; i >= 0; i--) {
                            temp[i].dismiss();
                        }
                        notifWindow.activeNotifs = [];
                    }
                }
            }
        }

        // Fallback empty view when no notifications
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: notifWindow.activeNotifs.length === 0
            spacing: 6
            Layout.topMargin: 40

            Text {
                text: "󰂚"
                font.family: "Noto Sans"
                font.pixelSize: 32
                color: notifWindow.theme.getColor("outline")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: "No new notifications"
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 12
                font.bold: true
                color: notifWindow.theme.getColor("outline")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            
            Item { Layout.fillHeight: true }
        }

        // Scrollable Notifications Stack
        ListView {
            id: appNotifsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            clip: true
            visible: notifWindow.activeNotifs.length > 0
            model: notifWindow.activeNotifs

            add: Transition {
                NumberAnimation { properties: "y"; from: -20; duration: 250; easing.type: Easing.OutCubic }
                NumberAnimation { properties: "opacity"; from: 0; duration: 200 }
            }
            displaced: Transition {
                SpringAnimation { properties: "y"; spring: 2.0; damping: 0.6; duration: 300 }
            }
            removeDisplaced: Transition {
                SpringAnimation { properties: "y"; spring: 2.0; damping: 0.6; duration: 300 }
            }
            addDisplaced: Transition {
                SpringAnimation { properties: "y"; spring: 2.0; damping: 0.6; duration: 300 }
            }

            delegate: Item {
                id: cardItem
                width: appNotifsList.width
                height: 72

                Rectangle {
                    id: card
                    anchors.fill: parent
                    radius: 12
                    color: notifWindow.theme.getColor("surfaceVariant")
                    border.width: 0
                    opacity: Math.max(0.2, 1.0 - Math.abs(cardTranslate.x) / (cardItem.width * 0.7))

                    transform: Translate {
                        id: cardTranslate
                        x: 0
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        // Icon container
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: notifWindow.theme.getColor("primary")
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                text: "󰂚"
                                font.family: "Noto Sans"
                                font.pixelSize: 14
                                color: notifWindow.theme.getColor("onPrimary")
                            }
                        }

                        // Text details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Layout.alignment: Qt.AlignVCenter
                            


                            Text {
                                text: modelData.summary || "Notification"
                                font.family: "Google Sans Flex, sans-serif"
                                font.pixelSize: 12
                                font.bold: true
                                color: notifWindow.theme.getColor("onSurface")
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.body || ""
                                font.family: "Google Sans Flex, sans-serif"
                                font.pixelSize: 10
                                color: notifWindow.theme.getColor("outline")
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        }
                    }

                    // Swipe-to-Dismiss (Swipe right only)
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        
                        property real startX: 0
                        property bool isDragging: false
                        
                        onPressed: mouse => {
                            startX = dragArea.mapToItem(cardItem, mouse.x, mouse.y).x;
                            isDragging = true;
                            appNotifsList.interactive = false; // Prevent list scrolling from stealing mouse focus
                        }
                        
                        onPositionChanged: mouse => {
                            if (isDragging) {
                                var currentX = dragArea.mapToItem(cardItem, mouse.x, mouse.y).x;
                                var deltaX = currentX - startX;
                                // Only allow swiping to the right (positive delta)
                                if (deltaX > 5) {
                                    cardTranslate.x = deltaX;
                                } else {
                                    cardTranslate.x = 0;
                                }
                            }
                        }
                        
                        onReleased: mouse => {
                            if (isDragging) {
                                isDragging = false;
                                appNotifsList.interactive = true; // Restore list scrolling
                                var threshold = cardItem.width * 0.30; // 30% width threshold
                                if (cardTranslate.x > threshold) {
                                    // Smoothly slide off-screen to the right
                                    dismissAnim.to = cardItem.width + 50;
                                    dismissAnim.start();
                                } else {
                                    snapBackAnim.start();
                                }
                            }
                        }

                        onCanceled: {
                            if (isDragging) {
                                isDragging = false;
                                appNotifsList.interactive = true;
                                snapBackAnim.start();
                            }
                        }
                    }

                    NumberAnimation {
                        id: snapBackAnim
                        target: cardTranslate
                        property: "x"
                        to: 0
                        duration: 200
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        id: dismissAnim
                        target: cardTranslate
                        property: "x"
                        duration: 200
                        easing.type: Easing.OutCubic
                        onStopped: {
                            modelData.dismiss();
                        }
                    }
            }
        }
    }

    // 5. Quick Actions Row (Icon only, slim modern design)
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // --- WiFi Toggle ---
        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 12
            color: notifWindow.wifiEnabled ? notifWindow.theme.getColor("primary") : notifWindow.theme.getColor("surfaceVariant")

            Behavior on color { ColorAnimation { duration: 200 } }

            Text {
                anchors.centerIn: parent
                text: notifWindow.wifiEnabled ? "󰤨" : "󰤮"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                font.bold: true
                color: notifWindow.wifiEnabled ? notifWindow.theme.getColor("onPrimary") : notifWindow.theme.getColor("onSurface")
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    notifWindow.wifiEnabled = !notifWindow.wifiEnabled;
                    wifiToggleProc.command = ["nmcli", "radio", "wifi", notifWindow.wifiEnabled ? "on" : "off"];
                    wifiToggleProc.running = false;
                    wifiToggleProc.running = true;
                }
                onEntered: parent.opacity = 0.85
                onExited: parent.opacity = 1.0
            }
        }

        // --- Screenshot ---
        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 12
            color: notifWindow.theme.getColor("surfaceVariant")

            Text {
                anchors.centerIn: parent
                text: "󰹑"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                font.bold: true
                color: notifWindow.theme.getColor("onSurface")
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    notifWindow.active = false;
                    screenshotProc.running = false;
                    screenshotProc.running = true;
                }
                onEntered: parent.opacity = 0.85
                onExited: parent.opacity = 1.0
            }
        }

        // --- Hyprpicker (Color Picker) ---
        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 12
            color: notifWindow.theme.getColor("surfaceVariant")

            Text {
                anchors.centerIn: parent
                text: "󰈋" // Palette/Color picker icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                font.bold: true
                color: notifWindow.theme.getColor("onSurface")
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    notifWindow.active = false;
                    hyprpickerProc.running = false;
                    hyprpickerProc.running = true;
                }
                onEntered: parent.opacity = 0.85
                onExited: parent.opacity = 1.0
            }
        }

        // --- Mute/Unmute ---
        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 12
            color: notifWindow.isMuted ? notifWindow.theme.getColor("error") : notifWindow.theme.getColor("surfaceVariant")

            Behavior on color { ColorAnimation { duration: 200 } }

            Text {
                anchors.centerIn: parent
                text: notifWindow.isMuted ? "󰖁" : "󰕾"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                font.bold: true
                color: notifWindow.isMuted ? notifWindow.theme.getColor("onError") : notifWindow.theme.getColor("onSurface")
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    notifWindow.isMuted = !notifWindow.isMuted;
                    muteToggleProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
                    muteToggleProc.running = false;
                    muteToggleProc.running = true;
                }
                onEntered: parent.opacity = 0.85
                onExited: parent.opacity = 1.0
            }
        }
    }

    // 6. Divider
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: notifWindow.theme.getColor("surfaceVariant")
    }

    // 6. Power Grid (Very Bottom)
    PowerGrid {
        theme: notifWindow.theme
        expanded: notifWindow.powerMenuExpanded
        onClosed: {
            notifWindow.active = false;
        }
    }
}
