import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

Item {
    id: appItemRoot
    width: parent ? parent.width : 540
    height: 48
    opacity: 1.0

    property var appItem: model
    property bool isSelected: false
    property var theme

    signal clicked()
    signal hovered(real yPos, real itemHeight)
    signal unhovered()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 3
        onEntered: appItemRoot.hovered(appItemRoot.y, appItemRoot.height)
        onExited: appItemRoot.unhovered()
        onClicked: appItemRoot.clicked()
    }

    function getCategoriesText(cats) {
        if (!cats) return "";
        if (Array.isArray(cats)) return cats.join(" • ");
        if (typeof cats === "object" && cats.count !== undefined) {
            var arr = [];
            for (var i = 0; i < cats.count; i++) {
                var val = cats.get(i);
                if (typeof val === "string") arr.push(val);
                else if (val && val.value) arr.push(val.value);
            }
            return arr.join(" • ");
        }
        return String(cats);
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12
        z: 2

        // App Icon
        Rectangle {
            width: 32
            height: 32
            radius: 8
            color: appItemRoot.theme ? appItemRoot.theme.getColor("surfaceVariant") : "#2b2b35"
            clip: true
            Layout.alignment: Qt.AlignVCenter
            opacity: 1.0

            IconImage {
                anchors.fill: parent
                anchors.margins: 4
                opacity: 1.0
                source: (appItem && appItem.icon && appItem.icon !== "")
                    ? (appItem.icon.indexOf("/") === 0 ? ("file://" + appItem.icon) : appItem.icon)
                    : ("file://" + shellConfig.defaultAppIcon)
                onStatusChanged: {
                    if (status === Image.Error) source = "file://" + shellConfig.defaultAppIcon;
                }
            }
        }

        // App Details (Name + Description/Category)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: (appItem && appItem.name) ? appItem.name : ""
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 13
                font.bold: true
                color: appItemRoot.theme ? appItemRoot.theme.getColor("onSurface") : "#f0dede"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: (appItem && appItem.comment && appItem.comment !== "")
                    ? appItem.comment
                    : appItemRoot.getCategoriesText(appItem ? appItem.categories : null)
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 11
                color: appItemRoot.theme ? appItemRoot.theme.getColor("onSurfaceVariant") : "#8f8f9f"
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }
        }
    }
}
