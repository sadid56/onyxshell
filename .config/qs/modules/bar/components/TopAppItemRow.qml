import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

Item {
    id: rowRoot

    width: ListView.view ? ListView.view.width : (parent ? parent.width : 280)
    height: 32

    property var theme
    property var appData: ({})
    property int rank: 1

    signal rightClicked(var data, real globalX, real globalY)

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        radius: 10
        color: rowMouse.containsMouse
            ? (rowRoot.theme ? Qt.alpha(rowRoot.theme.getColor("surfaceVariant"), 0.65) : "#20ffffff")
            : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
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
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6

        UI.Typography {
            theme: rowRoot.theme
            text: String(rowRoot.rank)
            variant: "labelSmall"
            font.pixelSize: 11
            colorRole: "outline"
            Layout.preferredWidth: 16
            Layout.alignment: Qt.AlignVCenter
        }

        UI.Typography {
            theme: rowRoot.theme
            text: rowRoot.appData.name || "—"
            variant: "bodySmall"
            font.bold: true
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
            variant: "labelSmall"
            font.pixelSize: 10
            colorRole: "outline"
            Layout.preferredWidth: 20
            Layout.alignment: Qt.AlignVCenter
        }

        // CPU Badge Pill
        Rectangle {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 18
            radius: 9
            color: (rowRoot.appData.cpu || 0) > 15
                ? (rowRoot.theme ? Qt.alpha(rowRoot.theme.getColor("primary"), 0.18) : "#30ffb3b4")
                : "transparent"
            Layout.alignment: Qt.AlignVCenter

            UI.Typography {
                anchors.centerIn: parent
                theme: rowRoot.theme
                text: (rowRoot.appData.cpu || 0).toFixed(1) + "%"
                variant: "labelSmall"
                font.bold: (rowRoot.appData.cpu || 0) > 10
                color: (rowRoot.appData.cpu || 0) > 15
                    ? (rowRoot.theme ? rowRoot.theme.getColor("primary") : "#adc6ff")
                    : (rowRoot.theme ? rowRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
            }
        }

        UI.Typography {
            theme: rowRoot.theme
            text: {
                var mb = rowRoot.appData.rss_mb || 0;
                return mb >= 1024 ? (mb / 1024).toFixed(1) + " GB" : mb.toFixed(0) + " MB";
            }
            variant: "labelSmall"
            font.bold: (rowRoot.appData.rss_mb || 0) > 1000
            color: (rowRoot.appData.rss_mb || 0) > 1000
                ? (rowRoot.theme ? rowRoot.theme.getColor("primary") : "#adc6ff")
                : (rowRoot.theme ? rowRoot.theme.getColor("outline") : "#8c909f")
            Layout.preferredWidth: 54
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
