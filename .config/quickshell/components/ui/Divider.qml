import QtQuick
import QtQuick.Layouts

Rectangle {
    id: dividerRoot

    property var theme
    property bool horizontal: false
    property real dividerOpacity: 0.45
    property string customColor: ""

    width: horizontal ? implicitWidth : 1
    height: horizontal ? 1 : 16
    radius: 0.5

    implicitWidth: horizontal ? (parent ? parent.width : 100) : 1
    implicitHeight: horizontal ? 1 : 16

    Layout.preferredWidth: horizontal ? -1 : 1
    Layout.preferredHeight: horizontal ? 1 : 16
    Layout.alignment: Qt.AlignVCenter
    Layout.leftMargin: 6
    Layout.rightMargin: 6

    color: (customColor && customColor !== "") ? customColor : (dividerRoot.theme ? dividerRoot.theme.getColor("outline") : "#9f8c8c")
    opacity: dividerOpacity
}
