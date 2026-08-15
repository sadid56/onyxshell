import QtQuick
import QtQuick.Layouts

BasePopup {
    id: calWindow

    popupWidth: 500
    popupHeight: 480
    topOverlap: 14

    // Calendar state
    property date today: new Date()
    property int displayedMonth: today.getMonth()
    property int displayedYear: today.getFullYear()
    property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    property var daysList: []

    function getDaysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function getStartDayOfWeek(year, month) {
        var day = new Date(year, month, 1).getDay();
        return day === 0 ? 6 : day - 1; // Adjust Monday to 0
    }

    function updateCalendar() {
        var list = [];
        var daysInPrevMonth = getDaysInMonth(displayedYear, displayedMonth - 1);
        var daysInCurrentMonth = getDaysInMonth(displayedYear, displayedMonth);
        var startDay = getStartDayOfWeek(displayedYear, displayedMonth);
        
        // Prev month days
        for (var i = startDay - 1; i >= 0; i--) {
            list.push({
                dayNumber: daysInPrevMonth - i,
                isCurrent: false,
                isToday: false
            });
        }
        
        // Current month days
        var now = new Date();
        for (var j = 1; j <= daysInCurrentMonth; j++) {
            var isToday = now.getDate() === j && 
                          now.getMonth() === displayedMonth && 
                          now.getFullYear() === displayedYear;
            list.push({
                dayNumber: j,
                isCurrent: true,
                isToday: isToday
            });
        }
        
        // Next month days
        var remaining = 42 - list.length;
        for (var k = 1; k <= remaining; k++) {
            list.push({
                dayNumber: k,
                isCurrent: false,
                isToday: false
            });
        }
        daysList = list;
    }

    onActiveChanged: {
        if (active) {
            today = new Date();
            displayedMonth = today.getMonth();
            displayedYear = today.getFullYear();
            updateCalendar();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: calWindow.active
        onActivated: calWindow.active = false
    }

    // Inside BasePopup, children are automatically loaded into ColumnLayout inside contentRect.
    
    // Header Section
    RowLayout {
        Layout.fillWidth: true
        
        Text {
            text: calWindow.monthNames[calWindow.displayedMonth] + " " + calWindow.displayedYear
            font.family: "Noto Sans"
            font.pixelSize: 17
            font.bold: true
            color: calWindow.theme.getColor("onSurface")
            Layout.fillWidth: true
        }

        // Prev Button
        Text {
            text: ""
            font.family: "Noto Sans"
            font.pixelSize: 16
            color: calWindow.theme.getColor("primary")
            font.bold: true
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (calWindow.displayedMonth === 0) {
                        calWindow.displayedMonth = 11;
                        calWindow.displayedYear--;
                    } else {
                        calWindow.displayedMonth--;
                    }
                    calWindow.updateCalendar();
                }
            }
        }

        Item { width: 10 }

        // Next Button
        Text {
            text: ""
            font.family: "Noto Sans"
            font.pixelSize: 16
            color: calWindow.theme.getColor("primary")
            font.bold: true
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (calWindow.displayedMonth === 11) {
                        calWindow.displayedMonth = 0;
                        calWindow.displayedYear++;
                    } else {
                        calWindow.displayedMonth++;
                    }
                    calWindow.updateCalendar();
                }
            }
        }
    }

    // Divider
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: calWindow.theme.getColor("surfaceVariant")
    }

    // Week Day Names Row
    RowLayout {
        Layout.fillWidth: true
        spacing: 0
        Repeater {
            model: calWindow.dayNames
            Text {
                text: modelData
                font.family: "Noto Sans"
                font.pixelSize: 12
                font.bold: true
                color: calWindow.theme.getColor("outline")
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }
    }

    // Days Grid
    GridLayout {
        id: daysGrid
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 7
        rowSpacing: 10
        columnSpacing: 0

        Repeater {
            model: calWindow.daysList
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                color: modelData.isToday ? 
                           calWindow.theme.getColor("primary") : 
                           (cellMouseArea.containsMouse ? calWindow.theme.getColor("surfaceVariant") : "transparent")
                radius: 19

                Text {
                    anchors.centerIn: parent
                    text: String(modelData.dayNumber)
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                    font.bold: modelData.isToday || modelData.isCurrent
                    color: modelData.isToday ? 
                               calWindow.theme.getColor("onPrimary") : 
                               (modelData.isCurrent ? 
                                   calWindow.theme.getColor("onSurface") : 
                                   calWindow.theme.getColor("outline"))
                }

                MouseArea {
                    id: cellMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
