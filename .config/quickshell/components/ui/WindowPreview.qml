import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland

Item {
    id: windowPreviewRoot

    property string address: ""
    property var addresses: []
    property bool live: true
    property string fallbackIcon: ""
    property real cornerRadius: 0
    property color backgroundColor: "transparent"

    readonly property var resolvedToplevel: {
        var targets = [];
        if (address) {
            targets.push(address.toLowerCase());
        }
        if (addresses && addresses.length > 0) {
            for (var i = 0; i < addresses.length; i++) {
                if (addresses[i]) targets.push(addresses[i].toLowerCase());
            }
        }

        if (targets.length === 0) return null;

        if (ToplevelManager && ToplevelManager.toplevels && ToplevelManager.toplevels.values) {
            var list = ToplevelManager.toplevels.values;
            for (var t = 0; t < list.length; t++) {
                var top = list[t];
                if (top && top.HyprlandToplevel) {
                    var topAddr = (top.HyprlandToplevel.address || "").toLowerCase();
                    var strippedTop = topAddr.replace(/^0x/, "");
                    for (var k = 0; k < targets.length; k++) {
                        var tgt = targets[k];
                        var strippedTgt = tgt.replace(/^0x/, "");
                        if (topAddr === tgt || strippedTop === strippedTgt || ("0x" + strippedTop) === tgt) {
                            return top;
                        }
                    }
                }
            }
        }
        return null;
    }

    readonly property bool hasCapture: resolvedToplevel !== null

    Rectangle {
        id: bgContainer
        anchors.fill: parent
        radius: windowPreviewRoot.cornerRadius
        color: windowPreviewRoot.backgroundColor
        clip: windowPreviewRoot.cornerRadius > 0

        ScreencopyView {
            id: screencopy
            anchors.fill: parent
            captureSource: windowPreviewRoot.resolvedToplevel
            live: windowPreviewRoot.live && (captureSource !== null)
            visible: captureSource !== null
        }

        Item {
            anchors.centerIn: parent
            width: Math.min(48, Math.min(parent.width * 0.4, parent.height * 0.4))
            height: width
            visible: !screencopy.visible && windowPreviewRoot.fallbackIcon !== ""
            opacity: 0.25

            IconImage {
                anchors.fill: parent
                source: {
                    var ic = windowPreviewRoot.fallbackIcon;
                    if (!ic) return "";
                    if (ic.indexOf("/") === 0) return "file://" + ic;
                    if (ic.startsWith("file://") || ic.startsWith("image://") || ic.startsWith("qrc:/")) return ic;
                    var cfg = ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : (typeof root !== "undefined" ? root.shellConfig : null));
                    var def = (cfg && cfg.defaultAppIcon) ? cfg.defaultAppIcon : (Quickshell.env("HOME") + "/.config/quickshell/assets/icons/system/default-app.svg");
                    return "file://" + def;
                }
            }
        }
    }
}
