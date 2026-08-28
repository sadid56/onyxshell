import QtQuick
import QtQuick.Layouts

Item {
    id: skeletonRoot

    property var theme
    property int count: 4
    property int itemHeight: 44
    property int itemRadius: 10
    property bool showIcon: true
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
                    spacing: 10

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
                        spacing: 6

                        Rectangle {
                            height: 10
                            width: (index % 3 === 0) ? 130 : ((index % 2 === 0) ? 100 : 150)
                            radius: 4
                            color: skeletonRoot.theme ? Qt.alpha(skeletonRoot.theme.getColor("surfaceVariant"), 0.9) : "#454558"
                        }

                        Rectangle {
                            height: 7
                            width: 60
                            radius: 3
                            color: skeletonRoot.theme ? Qt.alpha(skeletonRoot.theme.getColor("surfaceVariant"), 0.5) : "#303040"
                        }
                    }
                }
            }
        }
    }
}
