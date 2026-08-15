import QtQuick
import QtQuick.Layouts

MouseArea {
    id: clockRoot
    implicitWidth: clockRow.implicitWidth
    implicitHeight: clockRow.implicitHeight
    cursorShape: Qt.PointingHandCursor
    
    property var theme
    property var toggleCalendar

    hoverEnabled: true

    onEntered: {
        calendarPopup.targetX = statusBar.getClockX();
        calendarPopup.closeTimer.stop();
        calendarPopup.active = true;
        wifiPopup.active = false;
        notifs.active = false;
    }

    onExited: {
        calendarPopup.closeTimer.restart();
    }

    onClicked: {
        calendarPopup.active = !calendarPopup.active;
    }
    
    Row {
        id: clockRow
        spacing: 8
        
        Text {
            text: "󱑂"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.bold: true
            color: clockRoot.theme.getColor("onSurface")
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: clockText
            font.family: "Noto Sans"
            font.pixelSize: 13
            font.bold: true
            color: clockRoot.theme.getColor("onSurface")
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date();
            clockText.text = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true }) + " • " + date.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' });
        }
    }
}
