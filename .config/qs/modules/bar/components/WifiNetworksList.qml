import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

ColumnLayout {
    id: listRoot

    property var wifiWindow
    property var theme

    spacing: 8
    Layout.fillWidth: true
    Layout.fillHeight: true

    UI.SkeletonLoader {
        Layout.fillWidth: true
        theme: listRoot.theme
        count: 3
        itemHeight: 44
        itemRadius: 10
        iconSize: 24
        iconRadius: 8
        visible: wifiWindow && wifiWindow.wifiList.length === 0 && wifiWindow.isScanning
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: wifiWindow && wifiWindow.wifiList.length === 0 && !wifiWindow.isScanning
        spacing: 8
        Layout.topMargin: 12

        IconImage {
            width: 32
            height: 32
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("wifi/wifi-off.svg")
            Layout.alignment: Qt.AlignHCenter
            layer.enabled: true
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: listRoot.theme ? listRoot.theme.getColor("outline") : "#777777" }
        }

        UI.Typography {
            theme: listRoot.theme
            text: "No networks found"
            variant: "bodyMedium"
            font.bold: true
            colorRole: "outline"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
    }

    UI.AnimatedListView {
        id: wifiListView
        theme: listRoot.theme
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: wifiWindow && wifiWindow.wifiList.length > 0
        clip: true
        pillColor: listRoot.theme ? listRoot.theme.getColor("surfaceVariant") : "#2b2a27"
        pillRadius: 14
        pillMargin: 4
        defaultItemHeight: 46
        showPillOnlyOnHover: true
        spacing: 4
        model: wifiWindow ? wifiWindow.wifiList : []
        delegate: WifiItemDelegate {
            parentListView: wifiListView
            wifiWindow: listRoot.wifiWindow
            theme: listRoot.theme
            onItemClicked: info => {
                if (info.active || !wifiWindow || wifiWindow.connectingSsid !== "") return;
                wifiWindow.selectedSsid = info.ssid;
                wifiWindow.selectedSecurity = info.security;
                if (info.saved || info.security === "") wifiWindow.wifiConnector.connectTo(wifiWindow.selectedSsid, "");
                else {
                    wifiWindow.showPasswordPrompt = true;
                    if (wifiWindow.pwdPromptRef) wifiWindow.pwdPromptRef.focusInput();
                }
            }
        }
    }
}
