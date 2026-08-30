import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

Item {
    id: delegateWrapper
    width: parentListView ? parentListView.width : 280
    height: 46
    z: 1

    property var parentListView
    property var theme
    readonly property var netInfo: modelData
    readonly property bool isHighlighted: parentListView ? parentListView.isItemHighlighted(index) : false

    signal itemClicked(var info)

    Rectangle {
        id: highlightBg
        anchors.fill: parent
        radius: 14
        color: delegateWrapper.theme ? delegateWrapper.theme.getColor("surfaceVariant") : "#2b2a27"
        opacity: (delegateWrapper.isHighlighted || mouseArea.containsMouse) ? 1.0 : 0.0
        z: 0

        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: delegateWrapper.netInfo.active ? Qt.ArrowCursor : Qt.PointingHandCursor
        z: 3
        onEntered: {
            if (parentListView) {
                parentListView.currentIndex = index;
                parentListView.hoverItem(index, delegateWrapper.y, delegateWrapper.height);
            }
        }
        onExited: {
            if (parentListView) {
                parentListView.unhoverItem(index);
            }
        }
        onClicked: delegateWrapper.itemClicked(delegateWrapper.netInfo)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 10
        z: 2

        Rectangle {
            width: 28
            height: 28
            radius: 14
            color: delegateWrapper.netInfo.active
                ? (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("primary"), 0.20) : "#40adc6ff")
                : (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("surfaceVariant"), 0.60) : "#20ffffff")
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getWifiIcon(delegateWrapper.netInfo.signal, true, true)
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: delegateWrapper.netInfo.active
                        ? (delegateWrapper.theme ? delegateWrapper.theme.getColor("primary") : "#adc6ff")
                        : (delegateWrapper.theme ? delegateWrapper.theme.getColor("onSurface") : "#ffffff")
                }
            }
        }

        UI.Typography {
            theme: delegateWrapper.theme
            text: delegateWrapper.netInfo.ssid
            variant: "bodyMedium"
            font.bold: delegateWrapper.netInfo.active || delegateWrapper.netInfo.saved
            color: delegateWrapper.netInfo.active
                ? (delegateWrapper.theme ? delegateWrapper.theme.getColor("primary") : "#adc6ff")
                : (delegateWrapper.theme ? delegateWrapper.theme.getColor("onSurface") : "#ffffff")
            Layout.fillWidth: true
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            UI.Typography {
                theme: delegateWrapper.theme
                text: delegateWrapper.netInfo.active ? "Connected" : (delegateWrapper.netInfo.saved ? "Saved" : "")
                variant: "caption"
                font.bold: true
                color: delegateWrapper.netInfo.active ? delegateWrapper.theme.getColor("primary") : (delegateWrapper.netInfo.saved ? delegateWrapper.theme.getColor("primary") : delegateWrapper.theme.getColor("outline"))
                visible: delegateWrapper.netInfo.active || delegateWrapper.netInfo.saved
                Layout.alignment: Qt.AlignVCenter
            }

            IconImage {
                width: 12
                height: 12
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/lock-closed.svg")
                visible: !delegateWrapper.netInfo.active && !delegateWrapper.netInfo.saved && delegateWrapper.netInfo.security !== ""
                Layout.alignment: Qt.AlignVCenter
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: delegateWrapper.theme.getColor("outline")
                }
            }
        }
    }
}
