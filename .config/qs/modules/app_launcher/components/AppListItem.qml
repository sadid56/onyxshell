import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../../../components/ui" as UI

Item {
    id: appItemRoot
    width: parent ? parent.width : 540
    height: 52
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
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 14
        z: 2

        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: appItemRoot.isSelected
                ? (appItemRoot.theme ? Qt.alpha(appItemRoot.theme.getColor("onSecondaryContainer") || "#ffffff", 0.15) : "#35ffffff")
                : (appItemRoot.theme ? Qt.alpha(appItemRoot.theme.getColor("surfaceVariant"), 0.70) : "#2b2b35")
            clip: true
            Layout.alignment: Qt.AlignVCenter
            opacity: 1.0

            Behavior on color { ColorAnimation { duration: 140 } }

            IconImage {
                anchors.centerIn: parent
                width: 24
                height: 24
                opacity: 1.0
                source: {
                    var ic = (appItem && appItem.icon) ? String(appItem.icon) : "";
                    if (!ic) return "file://" + shellConfig.defaultAppIcon;
                    if (ic.indexOf("/") === 0) return "file://" + ic;
                    if (ic.startsWith("file://") || ic.startsWith("image://") || ic.startsWith("qrc:/")) return ic;
                    return "image://icon/" + ic;
                }
                onStatusChanged: {
                    if (status === Image.Error && source !== "file://" + shellConfig.defaultAppIcon) {
                        source = "file://" + shellConfig.defaultAppIcon;
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            UI.Typography {
                theme: appItemRoot.theme
                text: (appItem && appItem.name) ? appItem.name : ""
                variant: "bodyMedium"
                font.bold: true
                colorRole: appItemRoot.isSelected ? "onSecondaryContainer" : "onSurface"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            UI.Typography {
                theme: appItemRoot.theme
                text: (appItem && appItem.description) ? appItem.description : getCategoriesText(appItem ? appItem.categories : null)
                variant: "labelSmall"
                colorRole: appItemRoot.isSelected ? "onSecondaryContainer" : "onSurfaceVariant"
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
                opacity: appItemRoot.isSelected ? 0.85 : 0.65
            }
        }
    }
}
