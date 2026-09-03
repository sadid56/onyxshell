import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

ColumnLayout {
    id: gridRoot

    property var theme
    property var calWindow
    property var daysList: []
    property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 8

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: 6

        Repeater {
            model: gridRoot.dayNames
            UI.Typography {
                Layout.fillWidth: true
                theme: gridRoot.theme
                text: modelData
                variant: "labelSmall"
                font.bold: true
                colorRole: "outline"
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    GridLayout {
        id: daysGrid
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 7
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: gridRoot.daysList

            CalendarDayCell {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
