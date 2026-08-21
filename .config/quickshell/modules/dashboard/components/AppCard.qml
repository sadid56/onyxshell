import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell

Item {
    id: cardRoot

    property var app: null
    property var theme: null
    property bool isSelected: false
    signal clicked(var app)
    signal hovered(real x, real y, real w, real h)
    signal unhovered()

    scale: cardMouse.pressed ? 0.96 : 1.0
    Behavior on scale {
        NumberAnimation { duration: 100 }
    }

    function getDefaultIcon() {
        var cfg = (typeof shellConfig !== "undefined" && shellConfig) 
                  ? shellConfig 
                  : ((typeof root !== "undefined" && root.shellConfig) ? root.shellConfig : null);
        return cfg ? ("file://" + cfg.defaultAppIcon) : "";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 5

        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 48
            height: 48

            Image {
                id: iconImg
                anchors.centerIn: parent
                width: 44
                height: 44
                sourceSize.width: 48
                sourceSize.height: 48
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true

                source: {
                    if (app && app.icon && typeof app.icon === "string" && app.icon.indexOf("/") === 0) {
                        return "file://" + app.icon;
                    }
                    return cardRoot.getDefaultIcon();
                }

                onStatusChanged: {
                    if (status === Image.Error) {
                        source = cardRoot.getDefaultIcon();
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: app ? app.name : ""
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 12
            lineHeight: 1.15
            font.weight: (cardMouse.containsMouse || cardRoot.isSelected) ? Font.DemiBold : Font.Medium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: theme ? theme.getColor("onSurface") : "#FFFFFF"
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            cardRoot.hovered(cardRoot.x, cardRoot.y, cardRoot.width, cardRoot.height);
        }
        onExited: {
            cardRoot.unhovered();
        }
        onClicked: {
            if (cardRoot.app) {
                cardRoot.clicked(cardRoot.app);
            }
        }
    }
}
