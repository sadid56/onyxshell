import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

Item {
    id: rowRoot

    width: ListView.view ? ListView.view.width : (parent ? parent.width : 280)
    height: 28

    property var theme
    property var appData: ({})
    property int rank: 1

    signal rightClicked(var data, real globalX, real globalY)

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                var targetContainer = (typeof morphContainer !== "undefined") ? morphContainer : (ListView.view ? ListView.view.parent : null);
                var pos = targetContainer ? rowRoot.mapToItem(targetContainer, mouse.x, mouse.y) : ({ x: mouse.x, y: mouse.y });
                rowRoot.rightClicked(rowRoot.appData, pos.x, pos.y);
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 0

        UI.Typography {
            theme: rowRoot.theme
            text: String(rowRoot.rank)
            variant: "caption"
            font.pixelSize: 10
            colorRole: "outline"
            Layout.preferredWidth: 16
            Layout.alignment: Qt.AlignVCenter
        }

        UI.Typography {
            theme: rowRoot.theme
            text: rowRoot.appData.name || "—"
            variant: "bodySmall"
            colorRole: "onSurface"
            Layout.fillWidth: true
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.alignment: Qt.AlignVCenter
        }

        UI.Typography {
            theme: rowRoot.theme
            visible: (rowRoot.appData.count || 1) > 1
            text: "×" + (rowRoot.appData.count || 1)
            variant: "caption"
            font.pixelSize: 9
            colorRole: "outline"
            Layout.preferredWidth: 22
            Layout.alignment: Qt.AlignVCenter
        }

        UI.Typography {
            theme: rowRoot.theme
            text: (rowRoot.appData.cpu || 0).toFixed(1) + "%"
            variant: "caption"
            font.pixelSize: 10
            font.bold: (rowRoot.appData.cpu || 0) > 10
            color: (rowRoot.appData.cpu || 0) > 15
                ? (rowRoot.theme ? rowRoot.theme.getColor("primary") : "#adc6ff")
                : (rowRoot.theme ? rowRoot.theme.getColor("outline") : "#8c909f")
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignVCenter
        }

        UI.Typography {
            theme: rowRoot.theme
            text: {
                var mb = rowRoot.appData.rss_mb || 0;
                return mb >= 1024 ? (mb / 1024).toFixed(1) + " GB" : mb.toFixed(0) + " MB";
            }
            variant: "caption"
            font.pixelSize: 10
            font.bold: (rowRoot.appData.rss_mb || 0) > 1000
            color: (rowRoot.appData.rss_mb || 0) > 1000
                ? (rowRoot.theme ? rowRoot.theme.getColor("primary") : "#adc6ff")
                : (rowRoot.theme ? rowRoot.theme.getColor("outline") : "#8c909f")
            Layout.preferredWidth: 52
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
