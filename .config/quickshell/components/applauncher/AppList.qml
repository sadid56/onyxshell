import QtQuick
import QtQuick.Layouts
import Quickshell

ListView {
    id: appListRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: contentHeight
    clip: true
    spacing: 8

    property var theme
    property alias appsModel: appListRoot.model

    signal appClicked(var app)
    signal upPressedAtStart()
    signal escapePressed()

    function getIconSource(iconName) {
        if (!iconName) return "file:///home/sadid/.icons/Reversal/mimes/scalable/application-x-executable.svg";
        if (iconName.indexOf("/") === 0) {
            return "file://" + iconName;
        }
        return "file:///home/sadid/.icons/Reversal/mimes/scalable/application-x-executable.svg";
    }

    add: Transition {
        NumberAnimation { properties: "opacity,scale"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
    }
    remove: Transition {
        NumberAnimation { properties: "opacity,scale"; to: 0.0; duration: 150 }
    }
    displaced: Transition {
        NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutBack }
    }

    delegate: Rectangle {
        id: delegateBg
        width: appListRoot.width
        height: 46
        radius: 8
        color: mouseArea.containsMouse || ListView.isCurrentItem ? appListRoot.theme.getColor("surfaceVariant") : "transparent"
        
        property var appInfo: modelData

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                appListRoot.appClicked(delegateBg.appInfo);
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Image {
                id: appIcon
                width: 24
                height: 24
                sourceSize.width: 24
                sourceSize.height: 24
                source: appListRoot.getIconSource(delegateBg.appInfo.icon)
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignVCenter

                 onStatusChanged: {
                     if (status === Image.Error) {
                         source = "file:///home/sadid/.icons/Reversal/mimes/scalable/application-x-executable.svg";
                     }
                 }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: delegateBg.appInfo.name
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                    font.bold: true
                    color: appListRoot.theme.getColor("onSurface")
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: delegateBg.appInfo.comment || ""
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 10
                    color: appListRoot.theme.getColor("outline")
                    visible: text !== ""
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            appListRoot.escapePressed();
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            if (appListRoot.currentIndex > 0) {
                appListRoot.currentIndex--;
            } else {
                appListRoot.upPressedAtStart();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            if (appListRoot.currentIndex < appListRoot.count - 1) {
                appListRoot.currentIndex++;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Return) {
            var app = appListRoot.model[appListRoot.currentIndex];
            if (app) {
                appListRoot.appClicked(app);
            }
            event.accepted = true;
        }
    }
}
