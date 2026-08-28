import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../../../components/ui" as UI

Item {
    id: swatchRoot

    property var theme
    property string selectedColor: "auto"
    property var colorPresets: [
        { name: "Catppuccin Mauve", color: "#cba6f7" },
        { name: "Catppuccin Lavender", color: "#b4befe" },
        { name: "Catppuccin Sapphire", color: "#74c7ec" },
        { name: "Catppuccin Sky", color: "#89dceb" },
        { name: "Catppuccin Teal", color: "#94e2d5" },
        { name: "Catppuccin Green", color: "#a6e3a1" },
        { name: "Catppuccin Yellow", color: "#f9e2af" },
        { name: "Catppuccin Peach", color: "#fab387" },
        { name: "Catppuccin Maroon", color: "#eba0ac" },
        { name: "Catppuccin Pink", color: "#f5c2e7" },
        { name: "Catppuccin Red", color: "#f38ba8" },
        { name: "Catppuccin Flamingo", color: "#f2cdcd" }
    ]

    implicitHeight: 34
    implicitWidth: swatchRow.implicitWidth

    signal colorSelected(string hex)

    RowLayout {
        id: swatchRow
        anchors.fill: parent
        spacing: 8

        Repeater {
            model: swatchRoot.colorPresets

            Rectangle {
                id: circle
                width: 26
                height: 26
                radius: 13
                color: modelData.color

                readonly property bool isSelected: (swatchRoot.selectedColor && swatchRoot.selectedColor !== "auto") && (swatchRoot.selectedColor.toLowerCase() === modelData.color.toLowerCase())
                readonly property bool isHovered: circleMouse.containsMouse

                scale: isSelected ? 1.15 : (isHovered ? 1.08 : 1.0)
                border.width: isSelected ? 2 : (isHovered ? 1 : 0)
                border.color: isSelected ? "#ffffff" : "#ffffff88"

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                UI.Typography {
                    theme: swatchRoot.theme
                    anchors.centerIn: parent
                    text: "✓"
                    font.pixelSize: 11
                    font.bold: true
                    color: "#222222"
                    visible: circle.isSelected
                }

                MouseArea {
                    id: circleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        swatchRoot.colorSelected(modelData.color);
                    }
                }
            }
        }
    }
}
