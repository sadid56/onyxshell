import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../../../components/ui" as UI

Item {
    id: cellRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 44
    implicitHeight: 44

    property bool isTodayDate: modelData.dayNumber === calWindow.today.getDate() &&
                              modelData.month === calWindow.today.getMonth() &&
                              modelData.year === calWindow.today.getFullYear()

    property bool isSelectedDate: modelData.dayNumber === calWindow.selectedDate.getDate() &&
                                  modelData.month === calWindow.selectedDate.getMonth() &&
                                  modelData.year === calWindow.selectedDate.getFullYear()

    Rectangle {
        id: cellRect
        anchors.centerIn: parent
        width: 42
        height: 42
        radius: 21

        scale: cellMouse.pressed ? 0.92 : (cellHover.hovered ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

        color: cellRoot.isTodayDate
            ? (calWindow.theme ? calWindow.theme.getColor("primary") : "#ffb3b4")
            : (cellRoot.isSelectedDate
                ? (calWindow.theme ? Qt.alpha(calWindow.theme.getColor("primaryContainer") || calWindow.theme.getColor("surfaceVariant"), 0.85) : "#3d3a48")
                : (cellHover.hovered
                    ? (calWindow.theme ? Qt.alpha(calWindow.theme.getColor("primary"), 0.16) : "#332a2a")
                    : "transparent"))

        border.width: (cellRoot.isSelectedDate && !cellRoot.isTodayDate) ? 2 : 0
        border.color: calWindow.theme ? calWindow.theme.getColor("primary") : "#ffb3b4"

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.width { NumberAnimation { duration: 120 } }

        UI.Typography {
            theme: calWindow.theme
            anchors.centerIn: parent
            text: String(modelData.dayNumber)
            variant: "labelLarge"
            font.bold: cellRoot.isTodayDate || cellRoot.isSelectedDate || modelData.isCurrentMonth
            font.pixelSize: 15
            color: cellRoot.isTodayDate
                ? (calWindow.theme ? calWindow.theme.getColor("onPrimary") : "#000000")
                : (cellRoot.isSelectedDate
                    ? (calWindow.theme ? calWindow.theme.getColor("primary") : "#ffb3b4")
                    : (modelData.isCurrentMonth
                        ? (cellHover.hovered
                            ? (calWindow.theme ? calWindow.theme.getColor("primary") : "#ffb3b4")
                            : (calWindow.theme ? calWindow.theme.getColor("onSurface") : "#ffffff"))
                        : (calWindow.theme ? Qt.alpha(calWindow.theme.getColor("outline"), 0.5) : "#757680")))

            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    HoverHandler {
        id: cellHover
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        id: cellMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: calWindow.selectDate(modelData)
    }
}
