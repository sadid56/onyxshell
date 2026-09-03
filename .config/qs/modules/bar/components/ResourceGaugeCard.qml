import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

Item {
    id: gaugeRoot
    Layout.fillWidth: true
    implicitHeight: 38

    property var theme
    property string title: ""
    property string valueText: ""
    property string subText: ""
    property string iconSource: ""
    property real progress: 0.0
    property color barColor: gaugeRoot.theme ? gaugeRoot.theme.getColor("primary") : "#adc6ff"

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            width: 32; height: 32; radius: 16
            color: Qt.rgba(gaugeRoot.barColor.r, gaugeRoot.barColor.g, gaugeRoot.barColor.b, 0.16)
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                anchors.centerIn: parent
                width: 16; height: 16
                source: gaugeRoot.iconSource
                layer.enabled: true
                layer.effect: MultiEffect { colorization: 1.0; colorizationColor: gaugeRoot.barColor }
            }
        }

        UI.Typography {
            theme: gaugeRoot.theme
            text: gaugeRoot.title
            variant: "labelLarge"
            font.bold: true
            colorRole: "onSurface"
            Layout.preferredWidth: 46
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height: 7
            radius: 3.5
            color: gaugeRoot.theme ? Qt.alpha(gaugeRoot.theme.getColor("surfaceVariant"), 0.85) : "#30ffffff"
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                width: Math.max(0, Math.min(parent.width, (gaugeRoot.progress / 100) * parent.width))
                radius: 3.5
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
            Layout.preferredWidth: 36
            Layout.alignment: Qt.AlignVCenter
        }

        UI.Typography {
            theme: gaugeRoot.theme
            visible: gaugeRoot.subText !== ""
            text: gaugeRoot.subText
            variant: "bodySmall"
            font.pixelSize: 11
            colorRole: "outline"
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 78
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
