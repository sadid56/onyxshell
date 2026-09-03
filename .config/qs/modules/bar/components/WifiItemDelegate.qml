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
    property var wifiWindow
    property var theme
    readonly property var netInfo: modelData
    readonly property bool isHighlighted: parentListView ? parentListView.isItemHighlighted(index) : false

    readonly property bool isConnecting: wifiWindow ? (wifiWindow.connectingSsid === delegateWrapper.netInfo.ssid) : false
    readonly property bool isFailed: wifiWindow ? (wifiWindow.failedSsid === delegateWrapper.netInfo.ssid) : false

    readonly property string statusText: {
        if (isConnecting) return "Connecting...";
        if (isFailed) return "Failed";
        if (delegateWrapper.netInfo.active) return "Connected";
        if (delegateWrapper.netInfo.saved) return "Saved";
        return "";
    }

    readonly property color statusColor: {
        if (isFailed) return (delegateWrapper.theme ? delegateWrapper.theme.getColor("error") : "#ff5449");
        if (isConnecting || delegateWrapper.netInfo.active || delegateWrapper.netInfo.saved) return (delegateWrapper.theme ? delegateWrapper.theme.getColor("primary") : "#adc6ff");
        return (delegateWrapper.theme ? delegateWrapper.theme.getColor("outline") : "#aaaaaa");
    }

    signal itemClicked(var info)

    Rectangle {
        id: highlightBg
        anchors.fill: parent
        radius: 14
        visible: false
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: (delegateWrapper.netInfo.active || delegateWrapper.isConnecting) ? Qt.ArrowCursor : Qt.PointingHandCursor
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
        onClicked: {
            if (!delegateWrapper.isConnecting) {
                delegateWrapper.itemClicked(delegateWrapper.netInfo);
            }
        }
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
            color: (delegateWrapper.netInfo.active || delegateWrapper.isConnecting)
                ? (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("primary"), 0.20) : "#40adc6ff")
                : (delegateWrapper.isFailed
                    ? (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("error"), 0.20) : "#40ff5449")
                    : (delegateWrapper.theme ? Qt.alpha(delegateWrapper.theme.getColor("surfaceVariant"), 0.60) : "#20ffffff"))
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getWifiIcon(delegateWrapper.netInfo.signal, true, true)
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: delegateWrapper.statusColor
                }
            }
        }

        UI.Typography {
            theme: delegateWrapper.theme
            text: delegateWrapper.netInfo.ssid
            variant: "bodyMedium"
            font.bold: delegateWrapper.netInfo.active || delegateWrapper.netInfo.saved || delegateWrapper.isConnecting
            color: (delegateWrapper.netInfo.active || delegateWrapper.isConnecting)
                ? (delegateWrapper.theme ? delegateWrapper.theme.getColor("primary") : "#adc6ff")
                : (delegateWrapper.theme ? delegateWrapper.theme.getColor("onSurface") : "#ffffff")
            Layout.fillWidth: true
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        RowLayout {
            spacing: 5
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                width: 12
                height: 12
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/arrow-clockwise-filled.svg")
                visible: delegateWrapper.isConnecting
                Layout.alignment: Qt.AlignVCenter
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: delegateWrapper.statusColor
                }
                RotationAnimation on rotation {
                    running: delegateWrapper.isConnecting
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                }
            }

            IconImage {
                width: 12
                height: 12
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/dismiss.svg")
                visible: delegateWrapper.isFailed
                Layout.alignment: Qt.AlignVCenter
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: delegateWrapper.statusColor
                }
            }

            UI.Typography {
                theme: delegateWrapper.theme
                text: delegateWrapper.statusText
                variant: "caption"
                font.bold: true
                color: delegateWrapper.statusColor
                visible: delegateWrapper.statusText !== ""
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            IconImage {
                width: 12
                height: 12
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/lock-closed.svg")
                visible: !delegateWrapper.netInfo.active && !delegateWrapper.netInfo.saved && !delegateWrapper.isConnecting && !delegateWrapper.isFailed && delegateWrapper.netInfo.security !== ""
                Layout.alignment: Qt.AlignVCenter
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: delegateWrapper.theme ? delegateWrapper.theme.getColor("outline") : "#aaaaaa"
                }
            }
        }
    }
}
