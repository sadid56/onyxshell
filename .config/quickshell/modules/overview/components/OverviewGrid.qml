import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

Item {
    id: gridRoot

    property var theme
    property var displayedClients: []
    property int selectedIndex: 0
    property string searchQuery: ""
    property bool showAllWorkspaces: false
    property int currentWsId: 1
    property bool overviewActive: true
    property real availableWidth: width

    signal selectWindow(var client)
    signal closeWindow(var client)
    signal draggingAt(real gx, real gy)
    signal droppedAt(var client, real gx, real gy)

    readonly property int gridCols: {
        var c = displayedClients.length;
        if (c <= 1) return 1;
        if (c === 2) return 2;
        if (c === 3) return 3;
        if (c === 4) return 2;
        if (c <= 6) return 3;
        return 4;
    }

    readonly property real cardW: {
        var c = displayedClients.length;
        var maxW = Math.max(300, gridRoot.availableWidth - 80);
        if (c <= 1) return Math.min(880, maxW * 0.60);
        if (c === 2) return Math.min(620, (maxW - 40) / 2);
        if (c === 3) return Math.min(480, (maxW - 60) / 3);
        if (c === 4) return Math.min(560, (maxW - 40) / 2);
        if (c <= 6) return Math.min(480, (maxW - 60) / 3);
        return Math.min(380, (maxW - 80) / 4);
    }

    readonly property real cardH: Math.round((cardW - 16) * 0.5625 + 44)

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        visible: gridRoot.displayedClients.length === 0

        UI.Typography {
            Layout.alignment: Qt.AlignHCenter
            theme: gridRoot.theme
            variant: "headlineSmall"
            font.bold: true
            text: gridRoot.searchQuery.length > 0
                  ? "No matching windows found"
                  : (gridRoot.showAllWorkspaces ? "No open windows" : ("No open windows on Workspace " + gridRoot.currentWsId))
            colorRole: "onSurface"
        }

        UI.Typography {
            Layout.alignment: Qt.AlignHCenter
            theme: gridRoot.theme
            variant: "bodyMedium"
            text: gridRoot.searchQuery.length > 0
                  ? "Try searching with a different window title or class"
                  : (gridRoot.showAllWorkspaces ? "Launch an application to see it here" : "Drag a window here or select another workspace from above")
            colorRole: "onSurfaceVariant"
        }
    }

    Flickable {
        id: gridFlickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, gridContainer.height)
        clip: false
        visible: gridRoot.displayedClients.length > 0

        Item {
            id: gridContainer
            anchors.centerIn: parent
            width: gridFlow.implicitWidth
            height: gridFlow.implicitHeight

            Grid {
                id: gridFlow
                anchors.centerIn: parent
                columns: gridRoot.gridCols
                columnSpacing: 24
                rowSpacing: 24

                Repeater {
                    model: gridRoot.displayedClients
                    delegate: OverviewCard {
                        width: gridRoot.cardW
                        height: gridRoot.cardH
                        theme: gridRoot.theme
                        clientData: modelData
                        overviewActive: gridRoot.overviewActive
                        isSelected: index === gridRoot.selectedIndex
                        onSelectWindow: gridRoot.selectWindow(modelData)
                        onCloseWindow: gridRoot.closeWindow(modelData)
                        onDraggingAt: (gx, gy) => gridRoot.draggingAt(gx, gy)
                        onDroppedAt: (client, gx, gy) => gridRoot.droppedAt(client, gx, gy)
                    }
                }
            }
        }
    }
}
