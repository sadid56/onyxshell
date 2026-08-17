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
        root.stopLoaderTimerAndActivate(calendarLoader, statusBar.getClockX());
        root.setLoaderInactive(wifiLoader);
        root.setLoaderInactive(notifsLoader);
    }

    onExited: {
        root.restartLoaderTimer(calendarLoader);
    }

    onClicked: {
        root.toggleLoaderActive(calendarLoader, statusBar.getClockX());
    }

    Row {
        id: clockRow
        spacing: 8

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
        id: timeTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date();
            var timeStr = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true });

            var day = date.getDate();
            var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            var monthStr = months[date.getMonth()];

            clockText.text = timeStr + " • " + day + " " + monthStr;
        }
    }
}
