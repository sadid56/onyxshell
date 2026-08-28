import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../components/containers"
import "../../components/ui" as UI
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
            list.push({ dayNumber: dayNumPrev, month: prevMonth, year: prevYear, isCurrentMonth: false });
        }

        for (var j = 1; j <= daysInCurrentMonth; j++) {
            list.push({ dayNumber: j, month: month, year: year, isCurrentMonth: true });
        }

        var remaining = 42 - list.length;
        for (var k = 1; k <= remaining; k++) {
            list.push({ dayNumber: k, month: nextMonth, year: nextYear, isCurrentMonth: false });
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

    Shortcut { sequence: "Escape"; enabled: calWindow.active; onActivated: calWindow.active = false }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            UI.Typography {
                id: selectedFullDateText
                theme: calWindow.theme
                text: calWindow.dayFullNames[calWindow.selectedDate.getDay()] + ", " + calWindow.selectedDate.getDate() + " " + calWindow.monthNames[calWindow.selectedDate.getMonth()] + " " + calWindow.selectedDate.getFullYear()
                variant: "titleMedium"
                font.pixelSize: 17
                colorRole: "onSurface"
            }

            UI.Typography {
                theme: calWindow.theme
                text: calWindow.monthNames[calWindow.displayedMonth] + " " + calWindow.displayedYear
                variant: "bodySmall"
                colorRole: "outline"
            }
        }

        Item { Layout.fillWidth: true }

        UI.Button {
            theme: calWindow.theme
            text: "Today"
            onClicked: {
                calWindow.today = new Date();
                calWindow.selectedDate = new Date();
                calWindow.displayedMonth = calWindow.today.getMonth();
                calWindow.displayedYear = calWindow.today.getFullYear();
                calWindow.daysList = calWindow.generateDaysFor(calWindow.displayedYear, calWindow.displayedMonth);
            }
        }

        RowLayout {
            spacing: 4

            UI.IconButton {
                theme: calWindow.theme
                icon: "actions/chevron-left.svg"
                size: 28
                iconSize: 14
                radius: 8
                onClicked: calWindow.navigateMonth(-1)
            }

            UI.IconButton {
                theme: calWindow.theme
                icon: "actions/chevron-right.svg"
                size: 28
                iconSize: 14
                radius: 8
                onClicked: calWindow.navigateMonth(1)
            }
        }
    }

    Item {
        id: gridViewport
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ParallelAnimation {
            id: monthSlideAnim
            NumberAnimation {
                target: gridContainer
                property: "x"
                from: calWindow.slideDir * 60
                to: 0
                duration: 220
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: gridContainer
                property: "opacity"
                from: 0.2
                to: 1.0
                duration: 180
                easing.type: Easing.OutQuad
            }
        }

        CalendarMonthGrid {
            id: gridContainer
            anchors.fill: parent
            theme: calWindow.theme
            calWindow: calWindow
            daysList: calWindow.daysList
            dayNames: calWindow.dayNames
        }
    }
}
