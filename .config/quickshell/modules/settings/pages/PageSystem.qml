import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../components" as SettingsUI
import "../../../components/ui" as UI

Item {
    id: pageRoot

    property var theme
    property var settingsService

    property var sysInfo: ({
        "osName": (typeof shellConfig !== "undefined" && shellConfig) ? (shellConfig.currentDistro.toUpperCase() + " Linux") : "Linux",
        "distroId": (typeof shellConfig !== "undefined" && shellConfig) ? shellConfig.currentDistro : "linux",
        "host": "Loading device...",
        "cpu": "Loading processor...",
        "gpus": [],
        "ram": "",
        "ramUsed": "",
        "disk": "",
        "kernel": "Linux",
        "arch": "x86_64",
        "packages": "...",
        "shell": "...",
        "uptime": "Active",
        "wm": "Hyprland (Wayland)",
        "dm": "Wayland",
        "hyprlandVersion": "Hyprland",
        "quickshellVersion": "Quickshell"
    })

    property bool isCopied: false

    Timer {
        id: copyResetTimer
        interval: 2500
        repeat: false
        onTriggered: pageRoot.isCopied = false
    }

    Process {
        id: sysInfoProc
        command: ["python", (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getScript("sys_info.py")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (parsed && parsed.osName) pageRoot.sysInfo = parsed;
                    } catch (e) {}
                }
            }
        }
    }

    function copySystemInfo() {
        var text = "--- System Specifications ---\n"
            + "OS: " + (pageRoot.sysInfo.osName || "Arch Linux") + " (" + (pageRoot.sysInfo.arch || "x86_64") + ")\n"
            + "Kernel: " + (pageRoot.sysInfo.kernel || "") + "\n"
            + "Hyprland: " + (pageRoot.sysInfo.hyprlandVersion || "Hyprland") + "\n"
            + "Quickshell: " + (pageRoot.sysInfo.quickshellVersion || "Quickshell") + "\n"
            + "Device: " + (pageRoot.sysInfo.host || "Linux Device") + "\n"
            + "Processor: " + (pageRoot.sysInfo.cpu || "") + "\n"
            + "GPU: " + (pageRoot.sysInfo.gpus ? pageRoot.sysInfo.gpus.join(" / ") : "") + "\n";

        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy", "copy-sysinfo", text]);
        pageRoot.isCopied = true;
        copyResetTimer.restart();

        var pMgr = (typeof popupManager !== "undefined" && popupManager) ? popupManager : ((typeof root !== "undefined" && root.popupManager) ? root.popupManager : null);
        if (pMgr && typeof pMgr.showNotification === "function") {
            pMgr.showNotification({
                appName: "System",
                summary: "System Information Copied",
                body: "Hardware specifications copied to clipboard",
                appIcon: "system/info.svg"
            });
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 42
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: 8
                color: pageRoot.theme.getColor("surfaceVariant")

                UI.Icon {
                    anchors.centerIn: parent
                    size: 18
                    icon: "system/info.svg"
                    color: pageRoot.theme.getColor("primary")
                }
            }

            UI.Typography {
                Layout.fillWidth: true
                theme: pageRoot.theme
                text: "About this System"
                variant: "titleMedium"
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentLayout.implicitHeight + 12
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 10

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 145

                    Image {
                        anchors.centerIn: parent
                        width: 145
                        height: 145
                        sourceSize: Qt.size(145, 145)
                        source: {
                            var dId = (pageRoot.sysInfo && pageRoot.sysInfo.distroId) ? pageRoot.sysInfo.distroId : "";
                            if (typeof shellConfig !== "undefined" && shellConfig) return shellConfig.getDistroIcon(dId);
                            if (typeof root !== "undefined" && root.shellConfig) return root.shellConfig.getDistroIcon(dId);
                            return Quickshell.env("HOME") + "/.config/quickshell/assets/distros/" + (dId || "linux") + ".svg";
                        }
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 10

                    UI.Typography {
                        theme: pageRoot.theme
                        text: "System Specifications"
                        variant: "labelMedium"
                        font.weight: Font.DemiBold
                        colorRole: "primary"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: copyBtn
                        height: 28
                        implicitWidth: copyBtnRow.implicitWidth + 18
                        radius: 8
                        color: pageRoot.isCopied
                            ? pageRoot.theme.getColor("primaryContainer")
                            : (copyBtnArea.containsMouse ? pageRoot.theme.getColor("surfaceVariant") : pageRoot.theme.getColor("surface"))
                        border.width: 1
                        border.color: pageRoot.isCopied ? pageRoot.theme.getColor("primary") : pageRoot.theme.getColor("outlineVariant") + "30"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: copyBtnRow
                            anchors.centerIn: parent
                            spacing: 6

                            IconImage {
                                width: 14
                                height: 14
                                source: pageRoot.isCopied
                                    ? (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/check.svg")
                                    : (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/image-copy.svg")
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: pageRoot.isCopied ? pageRoot.theme.getColor("primary") : pageRoot.theme.getColor("onSurfaceVariant")
                                }
                            }

                            UI.Typography {
                                theme: pageRoot.theme
                                text: pageRoot.isCopied ? "Copied" : "Copy Info"
                                variant: "labelSmall"
                                font.weight: Font.Medium
                                colorRole: pageRoot.isCopied ? "primary" : "onSurfaceVariant"
                            }
                        }

                        MouseArea {
                            id: copyBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pageRoot.copySystemInfo()
                        }
                    }
                }

                SettingsUI.SystemSpecsCards {
                    theme: pageRoot.theme
                    sysInfo: pageRoot.sysInfo
                }
            }
        }
    }
}
