import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../components/ui" as UI

Item {
    id: cardRoot

    property var wallpaperWindow
    property var wallpapersListInst

    width: 280
    height: 180
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    readonly property bool isSelected: Boolean((wallpapersListInst && wallpapersListInst.currentIndex === index) || ListView.isCurrentItem)
    readonly property bool isHovered: mouseArea ? mouseArea.containsMouse : false

    scale: isSelected ? 1.05 : (isHovered ? 1.02 : 1.0)
    opacity: isSelected ? 1.0 : (isHovered ? 0.9 : 0.75)
    z: isSelected ? 5 : (isHovered ? 2 : 1)

    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

    ClippingRectangle {
        id: cardBg
        anchors.fill: parent
        radius: 16
        color: (wallpaperWindow && wallpaperWindow.theme) ? wallpaperWindow.theme.getColor("surfaceVariant") : "#24232a"

        Image {
            anchors.fill: parent
            source: modelData ? ("file://" + modelData.path) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            mipmap: true
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 42
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "#d0000000" }
            }

            UI.Typography {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 10
                theme: wallpaperWindow ? wallpaperWindow.theme : null
                text: modelData ? modelData.name : ""
                variant: "labelMedium"
                font.bold: cardRoot.isSelected
                color: "#ffffff"
                elide: Text.ElideRight
            }
        }
    }

    Rectangle {
        id: selectionRing
        anchors.fill: parent
        radius: 16
        color: "transparent"
        border.width: cardRoot.isSelected ? 3 : (cardRoot.isHovered ? 2 : 0)
        border.color: cardRoot.isSelected
            ? ((wallpaperWindow && wallpaperWindow.theme) ? wallpaperWindow.theme.getColor("primary") : "#ffb3b4")
            : ((wallpaperWindow && wallpaperWindow.theme) ? wallpaperWindow.theme.getColor("outlineVariant") : "#ffffff50")
        z: 10

        Behavior on border.width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutQuad } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 11
        onClicked: {
            if (wallpapersListInst) {
                wallpapersListInst.currentIndex = index;
                wallpapersListInst.contentX = wallpaperWindow ? wallpaperWindow.getScrollTarget(index) : 0;
            }
            if (wallpaperWindow && wallpaperWindow.wallpaperSetter && modelData) {
                wallpaperWindow.wallpaperSetter.applyWallpaper(modelData.path, true);
            }
        }
    }
}
