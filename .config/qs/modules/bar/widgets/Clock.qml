import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

Item {
    id: clockRoot
    anchors.fill: parent

    readonly property real contentWidth: clockText.implicitWidth
    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    property var theme
    property var toggleCalendar
    property var toggleNotifications: null
    property int notifCount: 0
    property bool hasNotif: false

    MouseArea {
        id: clockArea
        width: clockText.implicitWidth
        height: 28
        implicitWidth: clockText.implicitWidth
        implicitHeight: 28
        anchors.centerIn: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        enabled: !clockRoot.hasNotif

        onEntered: {
            if (clockRoot.hasNotif) return;
            root.stopLoaderTimerAndActivate(calendarLoader, statusBar.getClockX());
            root.setLoaderInactive(wifiLoader);
            root.setLoaderInactive(notifsLoader);
        }
        onExited: {
            root.restartLoaderTimer(calendarLoader);
        }
        onClicked: {
            if (clockRoot.hasNotif) return;
            root.stopLoaderTimerAndActivate(calendarLoader, statusBar.getClockX());
        }

        UI.Typography {
            id: clockText
            theme: clockRoot.theme
            variant: "bodyMedium"
            font.bold: true
            colorRole: "onSurface"
            anchors.centerIn: parent
        }
    }

    Timer {
        id: timeTimer
        interval: 10000
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
