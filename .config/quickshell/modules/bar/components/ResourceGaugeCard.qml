import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

Item {
    id: gaugeRoot
    Layout.fillWidth: true
    implicitHeight: 36

    property var theme
    property string title: ""
    property string valueText: ""
    property string subText: ""
    property string iconSource: ""
    property real progress: 0.0
    property color barColor: gaugeRoot.theme ? gaugeRoot.theme.getColor("primary") : "#adc6ff"

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            width: 28; height: 28; radius: 6
            color: Qt.rgba(gaugeRoot.barColor.r, gaugeRoot.barColor.g, gaugeRoot.barColor.b, 0.1)
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                anchors.centerIn: parent
                width: 14; height: 14
                source: gaugeRoot.iconSource
                layer.enabled: true
                layer.effect: MultiEffect { colorization: 1.0; colorizationColor: gaugeRoot.barColor }
            }
        }

        UI.Typography {
            theme: gaugeRoot.theme
            text: gaugeRoot.title
            variant: "labelMedium"
            font.weight: Font.Medium
            colorRole: "onSurface"
            Layout.preferredWidth: 52
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height: 3
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.05)
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                width: Math.max(0, (gaugeRoot.progress / 100) * parent.width)
                radius: 2
                color: gaugeRoot.barColor
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }

        UI.Typography {
            theme: gaugeRoot.theme
            text: gaugeRoot.valueText
            variant: "labelMedium"
            font.bold: true
            color: gaugeRoot.barColor
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 34
            Layout.alignment: Qt.AlignVCenter
        }

        UI.Typography {
            theme: gaugeRoot.theme
            visible: gaugeRoot.subText !== ""
            text: gaugeRoot.subText
            variant: "caption"
            font.pixelSize: 9
            colorRole: "outline"
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 72
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
