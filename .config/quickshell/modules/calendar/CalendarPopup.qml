import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../components/containers"
import "./components"

Popup {
    id: calWindow

    popupWidth: 500
    popupHeight: 480

    property date today: new Date()
    property date selectedDate: new Date()
    property int displayedMonth: today.getMonth()
    property int displayedYear: today.getFullYear()

    property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    property var dayFullNames: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    property var daysList: []
    property int slideDir: 1

    function getDaysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function getStartDayOfWeek(year, month) {
        var day = new Date(year, month, 1).getDay();
        return day === 0 ? 6 : day - 1;
    }

    function generateDaysFor(year, month) {
        var list = [];
        var daysInPrevMonth = getDaysInMonth(year, month - 1);
        var daysInCurrentMonth = getDaysInMonth(year, month);
        var startDay = getStartDayOfWeek(year, month);

        var prevMonth = month === 0 ? 11 : month - 1;
        var prevYear = month === 0 ? year - 1 : year;
        var nextMonth = month === 11 ? 0 : month + 1;
        var nextYear = month === 11 ? year + 1 : year;

        for (var i = startDay - 1; i >= 0; i--) {
            var dayNumPrev = daysInPrevMonth - i;
            list.push({
                dayNumber: dayNumPrev,
                month: prevMonth,
                year: prevYear,
                isCurrentMonth: false
            });
        }

        for (var j = 1; j <= daysInCurrentMonth; j++) {
            list.push({
                dayNumber: j,
                month: month,
                year: year,
                isCurrentMonth: true
            });
        }

        var remaining = 42 - list.length;
        for (var k = 1; k <= remaining; k++) {
            list.push({
                dayNumber: k,
                month: nextMonth,
                year: nextYear,
                isCurrentMonth: false
            });
        }
        return list;
    }

    function navigateMonth(direction) {
        slideDir = direction;
        var nextMonth = displayedMonth + direction;
        var nextYear = displayedYear;

        if (nextMonth > 11) {
            nextMonth = 0;
            nextYear++;
        } else if (nextMonth < 0) {
            nextMonth = 11;
            nextYear--;
        }

        displayedMonth = nextMonth;
        displayedYear = nextYear;
        daysList = generateDaysFor(displayedYear, displayedMonth);

        monthSlideAnim.restart();
    }

    function selectDate(item) {
        selectedDate = new Date(item.year, item.month, item.dayNumber);
        if (item.month !== displayedMonth || item.year !== displayedYear) {
            var dir = (item.year > displayedYear || (item.year === displayedYear && item.month > displayedMonth)) ? 1 : -1;
            displayedMonth = item.month;
            displayedYear = item.year;
            daysList = generateDaysFor(displayedYear, displayedMonth);
            slideDir = dir;
            monthSlideAnim.restart();
        }
    }

    onActiveChanged: {
        if (active) {
            today = new Date();
            selectedDate = new Date();
            displayedMonth = today.getMonth();
            displayedYear = today.getFullYear();
            daysList = generateDaysFor(displayedYear, displayedMonth);
            gridContainer.x = 0;
            gridContainer.opacity = 1.0;
            gridContainer.scale = 1.0;
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: calWindow.active
        onActivated: calWindow.active = false
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                id: selectedFullDateText
                text: calWindow.dayFullNames[calWindow.selectedDate.getDay()] + ", " + 
                      calWindow.selectedDate.getDate() + " " + 
                      calWindow.monthNames[calWindow.selectedDate.getMonth()] + " " + 
                      calWindow.selectedDate.getFullYear()
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 17
                font.bold: true
                color: calWindow.theme ? calWindow.theme.getColor("onSurface") : "#f0dede"
            }

            Text {
                text: calWindow.monthNames[calWindow.displayedMonth] + " " + calWindow.displayedYear
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 12
                color: calWindow.theme ? calWindow.theme.getColor("outline") : "#8f8f9f"
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            width: 34
            height: 34
            radius: 17
            color: prevMouse.containsMouse ? 
                   (calWindow.theme ? calWindow.theme.getColor("surfaceVariant") : "#34343c") : 
                   "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            IconImage {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("chevron-left.svg")
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: calWindow.theme ? calWindow.theme.getColor("primary") : "#ffb3b4"
                }
            }

            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: calWindow.navigateMonth(-1)
            }
        }

        Item { width: 4 }

        Rectangle {
            width: 34
            height: 34
            radius: 17
            color: nextMouse.containsMouse ? 
                   (calWindow.theme ? calWindow.theme.getColor("surfaceVariant") : "#34343c") : 
                   "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            IconImage {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("chevron-right.svg")
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: calWindow.theme ? calWindow.theme.getColor("primary") : "#ffb3b4"
                }
            }

            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: calWindow.navigateMonth(1)
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: calWindow.theme ? calWindow.theme.getColor("surfaceVariant") : "#34343c"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0
        Repeater {
            model: calWindow.dayNames
            Text {
                text: modelData
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 12
                font.bold: true
                color: calWindow.theme ? calWindow.theme.getColor("outline") : "#8f8f9f"
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }
    }

    Item {
        id: stageContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        Item {
            id: gridContainer
            anchors.fill: parent

            GridLayout {
                anchors.fill: parent
                columns: 7
                rowSpacing: 8
                columnSpacing: 0

                Repeater {
                    model: calWindow.daysList
                    CalendarDayCell {}
                }
            }
        }
    }

    ParallelAnimation {
        id: monthSlideAnim

        NumberAnimation {
            target: gridContainer
            property: "x"
            from: calWindow.slideDir * 50
            to: 0
            duration: 250
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: gridContainer
            property: "opacity"
            from: 0.15
            to: 1.0
            duration: 220
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: gridContainer
            property: "scale"
            from: 0.96
            to: 1.0
            duration: 240
            easing.type: Easing.OutCubic
        }
    }
}
