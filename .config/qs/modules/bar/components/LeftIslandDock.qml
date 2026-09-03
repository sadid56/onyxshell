import QtQuick
import QtQuick.Layouts
import "../widgets"
import "../../../core"

Item {
    id: leftIslandRoot

    property var barWindow

    anchors.top: parent.top
    anchors.left: parent.left
    height: barWindow ? barWindow.barHeight : 40
    width: leftContentRow.implicitWidth + 32

    Rectangle {
        anchors.fill: parent
        color: barWindow ? barWindow.barSurfaceColor : "#1e1e2e"
        radius: barWindow ? barWindow.barCornerRadius : 16

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.radius
            color: parent.color
        }
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.radius
            color: parent.color
        }
    }

    RowLayout {
        id: leftContentRow
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16

        DistroLogo {
            id: distroLogoItem
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof root !== "undefined") root.toggleLoaderActive(dashboardLoader);
                }
            }
        }

        Workspaces {
            theme: barWindow ? barWindow.theme : null
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Corner {
        anchors.top: parent.top
        anchors.left: parent.right
        alignRight: false
        alignBottom: false
        color: barWindow ? barWindow.barSurfaceColor : "#1e1e2e"
        cornerRadius: barWindow ? barWindow.barCornerRadius : 16
    }
}
