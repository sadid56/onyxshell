import QtQuick
import QtQuick.Layouts

Item {
    id: skeletonRoot

    property var theme
    property int count: 4
    property int itemHeight: 44
    property int itemRadius: 10
    property bool showIcon: true
    property bool showRank: false
    property bool showSubtitle: true
    property bool showStats: false
    property int iconSize: 28
    property int iconRadius: 8
    property int spacing: 4
    property bool running: visible

    implicitHeight: columnLayout.implicitHeight
    implicitWidth: parent ? parent.width : 200

    SequentialAnimation on opacity {
        loops: Animation.Infinite
        running: skeletonRoot.running && skeletonRoot.visible
        NumberAnimation { from: 0.35; to: 0.85; duration: 700; easing.type: Easing.InOutQuad }
        NumberAnimation { from: 0.85; to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
    }

    Column {
        id: columnLayout
        anchors.fill: parent
        spacing: skeletonRoot.spacing

        Repeater {
            model: skeletonRoot.count

            Rectangle {
                width: skeletonRoot.width
                height: skeletonRoot.itemHeight
                radius: skeletonRoot.itemRadius
                color: skeletonRoot.theme ? Qt.alpha(skeletonRoot.theme.getColor("surfaceVariant"), 0.3) : "#20ffffff"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Rectangle {
                        visible: skeletonRoot.showRank
                        width: 14
                        height: 10
                        radius: 3
                        color: skeletonRoot.theme ? Qt.alpha(skeletonRoot.theme.getColor("outline"), 0.4) : "#30ffffff"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        visible: skeletonRoot.showIcon
                        width: skeletonRoot.iconSize
                        height: skeletonRoot.iconSize
                        radius: skeletonRoot.iconRadius
                        color: skeletonRoot.theme ? Qt.alpha(skeletonRoot.theme.getColor("surfaceVariant"), 0.85) : "#353545"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Rectangle {
                            height: 10
                            width: (index % 3 === 0) ? 110 : ((index % 2 === 0) ? 80 : 130)
                            radius: 4
                            color: skeletonRoot.theme ? Qt.alpha(skeletonRoot.theme.getColor("surfaceVariant"), 0.9) : "#454558"
                        }

                        Rectangle {
                            visible: skeletonRoot.showSubtitle
                            height: 7
                            width: 60
                            radius: 3
                            color: skeletonRoot.theme ? Qt.alpha(skeletonRoot.theme.getColor("surfaceVariant"), 0.5) : "#303040"
                        }
                    }

                    Rectangle {
                        visible: skeletonRoot.showStats
                        height: 10
                        width: 38
                        radius: 3
                        color: skeletonRoot.theme ? Qt.alpha(skeletonRoot.theme.getColor("surfaceVariant"), 0.7) : "#353545"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        visible: skeletonRoot.showStats
                        height: 10
                        width: 48
                        radius: 3
                        color: skeletonRoot.theme ? Qt.alpha(skeletonRoot.theme.getColor("surfaceVariant"), 0.7) : "#353545"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
