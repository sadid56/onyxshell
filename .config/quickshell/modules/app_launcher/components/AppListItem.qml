import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../../../components/ui" as UI

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

    Rectangle {
        id: highlightBg
        anchors.fill: parent
        radius: 12
        color: appItemRoot.theme ? appItemRoot.theme.getColor("secondaryContainer") : "#3d3a48"
        opacity: (appItemRoot.isSelected || mouseArea.containsMouse) ? 1.0 : 0.0
        z: 0

        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }
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

        Rectangle {
            width: 34
            height: 34
            radius: 9
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

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Layout.alignment: Qt.AlignVCenter

            UI.Typography {
                theme: appItemRoot.theme
                text: (appItem && appItem.name) ? appItem.name : ""
                variant: "bodyMedium"
                font.bold: true
                colorRole: "onSurface"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            UI.Typography {
                theme: appItemRoot.theme
                text: (appItem && appItem.comment && appItem.comment !== "")
                    ? appItem.comment
                    : appItemRoot.getCategoriesText(appItem ? appItem.categories : null)
                variant: "bodySmall"
                colorRole: "onSurfaceVariant"
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }
        }
    }
}
