import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

Item {
    id: cellRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 38

    property bool isTodayDate: modelData.dayNumber === calWindow.today.getDate() &&
                              modelData.month === calWindow.today.getMonth() &&
                              modelData.year === calWindow.today.getFullYear()

    property bool isSelectedDate: modelData.dayNumber === calWindow.selectedDate.getDate() &&
                                  modelData.month === calWindow.selectedDate.getMonth() &&
                                  modelData.year === calWindow.selectedDate.getFullYear()

    Rectangle {
        id: cellRect
        anchors.centerIn: parent
        width: 36
        height: 36
        radius: 18

        color: cellRoot.isTodayDate ?
               (calWindow.theme ? calWindow.theme.getColor("primary") : "#ffb3b4") :
               (cellRoot.isSelectedDate ?
                   (calWindow.theme ? calWindow.theme.getColor("surfaceVariant") : "#34343c") :
                   (cellHover.hovered ?
                       (calWindow.theme ? calWindow.theme.getColor("surfaceVariant") : "#2b2a27") :
                       "transparent"))

        border.width: (cellRoot.isSelectedDate && !cellRoot.isTodayDate) ? 1.5 : 0
        border.color: calWindow.theme ? calWindow.theme.getColor("primary") : "#ffb3b4"

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.width { NumberAnimation { duration: 120 } }

        UI.Typography {
            theme: calWindow.theme
            anchors.centerIn: parent
            text: String(modelData.dayNumber)
            variant: "labelMedium"
            font.bold: cellRoot.isTodayDate || cellRoot.isSelectedDate || modelData.isCurrentMonth
            color: cellRoot.isTodayDate ?
                       (calWindow.theme ? calWindow.theme.getColor("onPrimary") : "#380d15") :
                       (cellRoot.isSelectedDate ?
                           (calWindow.theme ? calWindow.theme.getColor("primary") : "#ffb3b4") :
                           (modelData.isCurrentMonth ?
                               (calWindow.theme ? calWindow.theme.getColor("onSurface") : "#f0dede") :
                               (calWindow.theme ? calWindow.theme.getColor("outline") : "#757680")))
        }
    }

    HoverHandler {
        id: cellHover
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: calWindow.selectDate(modelData)
    }
}
