import QtQuick
import Quickshell.Widgets

Item {
    id: delegateRoot
    width: 280
    height: 200

    property var wallpaperWindow
    property var wallpapersListInst
    property bool isCurrent: ListView.isCurrentItem

    ClippingRectangle {
        id: cardContainer
        width: 280
        height: 158
        radius: 18
        color: (wallpaperWindow && wallpaperWindow.theme) ? wallpaperWindow.theme.getColor("surfaceVariant") : "#2b2a27"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        scale: delegateRoot.isCurrent ? 1.10 : (hoverArea.containsMouse ? 1.03 : 0.96)
        opacity: delegateRoot.isCurrent ? 1.0 : (hoverArea.containsMouse ? 0.90 : 0.65)

        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }

        Image {
            id: imgSource
            anchors.fill: parent
            source: (modelData && modelData.path) ? ("file://" + modelData.path) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: 320
            sourceSize.height: 180
        }

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "transparent"
            border.color: delegateRoot.isCurrent
                          ? ((wallpaperWindow && wallpaperWindow.theme) ? wallpaperWindow.theme.getColor("primary") : "#ffb3b4")
                          : "transparent"
            border.width: delegateRoot.isCurrent ? 2.5 : 0
            Behavior on border.color { ColorAnimation { duration: 160 } }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (wallpapersListInst) {
                    wallpapersListInst.currentIndex = index;
                    if (wallpaperWindow && typeof wallpaperWindow.getScrollTarget === "function") {
                        wallpapersListInst.contentX = wallpaperWindow.getScrollTarget(index);
                    }
                }
                if (wallpaperWindow && wallpaperWindow.wallpaperSetter && modelData && modelData.path) {
                    wallpaperWindow.wallpaperSetter.applyWallpaper(modelData.path, true);
                }
            }
        }
    }
}
