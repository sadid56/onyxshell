import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components" as SettingsUI
import "../../../components/ui" as UI

Item {
    id: pageRoot

    property var theme
    property var settingsService

    property var monitorsList: []
    property var currentMonitor: (monitorsList && monitorsList.length > 0) ? monitorsList[0] : null
    property string selectedRes: currentMonitor ? currentMonitor.currentRes : "1920x1080"
    property int selectedHz: currentMonitor ? currentMonitor.currentHz : 144
    property real selectedScale: currentMonitor ? (currentMonitor.currentScale || 1.0) : 1.0

    readonly property var refreshRatesList: (currentMonitor && currentMonitor.modes && currentMonitor.modes[selectedRes])
        ? currentMonitor.modes[selectedRes]
        : [144, 60]

    readonly property var refreshRateModel: refreshRatesList.map(function(hz) {
        return {
            text: hz + " Hz",
            value: hz
        };
    })

    readonly property var resolutionModel: (currentMonitor && currentMonitor.resolutions)
        ? currentMonitor.resolutions.map(function(r) { return { text: r, value: r }; })
        : [{ text: "1920x1080", value: "1920x1080" }]

    Process {
        id: monitorsProc
        command: ["python", (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getScript("list_monitors.py")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (Array.isArray(parsed) && parsed.length > 0) {
                            pageRoot.monitorsList = parsed;
                            pageRoot.currentMonitor = parsed[0];
                            pageRoot.selectedRes = parsed[0].currentRes;
                            pageRoot.selectedHz = parsed[0].currentHz;
                            pageRoot.selectedScale = parsed[0].currentScale || 1.0;

                            Qt.callLater(function() {
                                if (resDropdown) resDropdown.selectValue(parsed[0].currentRes);
                                if (hzDropdown) hzDropdown.selectValue(parsed[0].currentHz);
                            });
                        }
                    } catch (e) {}
                }
            }
        }
    }

    function applyDisplayMode(res, hz, scale) {
        if (!currentMonitor) return;
        var monName = currentMonitor.name;
        var targetRes = res || pageRoot.selectedRes;
        var targetHz = hz || pageRoot.selectedHz;
        var targetScale = (scale !== undefined && scale > 0) ? scale : pageRoot.selectedScale;

        if (pageRoot.settingsService) {
            pageRoot.settingsService.applyDisplayMode(monName, targetRes, targetHz, targetScale);
        } else {
            var luaCmd = "hyprctl eval 'hl.monitor({ output = [[" + monName + "]], mode = [[" + targetRes + "@" + targetHz + "]], position = [[auto]], scale = " + targetScale + " })'";
            Quickshell.execDetached(["bash", "-c", luaCmd]);
        }

        var pMgr = (typeof popupManager !== "undefined" && popupManager) ? popupManager : ((typeof root !== "undefined" && root.popupManager) ? root.popupManager : null);
        if (pMgr && typeof pMgr.showNotification === "function") {
            pMgr.showNotification({
                appName: "Display",
                summary: "Display Configured",
                body: monName + ": " + targetRes + " @ " + targetHz + "Hz",
                appIcon: "system/monitor.svg"
            });
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 42
            spacing: 12

            Rectangle {
                width: 36
                height: 36
                radius: 10
                color: pageRoot.theme.getColor("surfaceVariant")

                UI.Icon {
                    anchors.centerIn: parent
                    size: 20
                    icon: "system/monitor.svg"
                    color: pageRoot.theme.getColor("primary")
                }
            }

            UI.Typography {
                Layout.fillWidth: true
                theme: pageRoot.theme
                text: "Display"
                variant: "titleMedium"
                Layout.alignment: Qt.AlignVCenter
            }

        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentLayout.implicitHeight + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 14

                SettingsUI.SettingsCard {
                    theme: pageRoot.theme
                    title: "Active Display Configuration"

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Active Display"
                        icon: "system/monitor.svg"
                        visible: pageRoot.monitorsList.length > 1

                        UI.Dropdown {
                            id: monitorDropdown
                            theme: pageRoot.theme
                            implicitWidth: 190
                            model: pageRoot.monitorsList.map(function(m) {
                                return { text: m.name + " (" + m.description + ")", value: m.name };
                            })
                            currentValue: pageRoot.currentMonitor ? pageRoot.currentMonitor.name : ""
                            onActivated: (idx, val, txt) => {
                                for (var i = 0; i < pageRoot.monitorsList.length; i++) {
                                    if (pageRoot.monitorsList[i].name === val) {
                                        pageRoot.currentMonitor = pageRoot.monitorsList[i];
                                        pageRoot.selectedRes = pageRoot.currentMonitor.currentRes;
                                        pageRoot.selectedHz = pageRoot.currentMonitor.currentHz;
                                        pageRoot.selectedScale = pageRoot.currentMonitor.currentScale || 1.0;
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    UI.Divider {
                        theme: pageRoot.theme
                        Layout.fillWidth: true
                        horizontal: true
                        visible: pageRoot.monitorsList.length > 1
                    }

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Screen Resolution"
                        icon: "system/app-window.svg"

                        UI.Dropdown {
                            id: resDropdown
                            theme: pageRoot.theme
                            implicitWidth: 190
                            model: pageRoot.resolutionModel
                            currentValue: pageRoot.selectedRes

                            onActivated: (idx, val, txt) => {
                                if (val) {
                                    pageRoot.selectedRes = val;
                                    var availableRates = (pageRoot.currentMonitor && pageRoot.currentMonitor.modes && pageRoot.currentMonitor.modes[val])
                                        ? pageRoot.currentMonitor.modes[val]
                                        : [60];
                                    if (availableRates.indexOf(pageRoot.selectedHz) === -1) {
                                        pageRoot.selectedHz = availableRates[0];
                                    }
                                    pageRoot.applyDisplayMode(pageRoot.selectedRes, pageRoot.selectedHz, pageRoot.selectedScale);
                                }
                            }
                        }
                    }

                    UI.Divider {
                        theme: pageRoot.theme
                        Layout.fillWidth: true
                        horizontal: true
                    }

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Refresh Rate"
                        icon: "system/zap.svg"

                        UI.Dropdown {
                            id: hzDropdown
                            theme: pageRoot.theme
                            implicitWidth: 190
                            model: pageRoot.refreshRateModel
                            currentValue: pageRoot.selectedHz

                            onActivated: (idx, val, txt) => {
                                if (val !== null && val !== undefined) {
                                    pageRoot.selectedHz = val;
                                    pageRoot.applyDisplayMode(pageRoot.selectedRes, val, pageRoot.selectedScale);
                                }
                            }
                        }
                    }
                }

                SettingsUI.SettingsCard {
                    theme: pageRoot.theme
                    title: "Night Light (Blue Light Filter)"

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Enable Night Light"
                        icon: "system/moon.svg"

                        UI.Switch {
                            theme: pageRoot.theme
                            checked: pageRoot.settingsService ? pageRoot.settingsService.nightLightEnabled : false
                            onToggled: isChecked => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.nightLightEnabled = isChecked;
                                    pageRoot.settingsService.applyNightLight(isChecked, pageRoot.settingsService.nightLightTemp);
                                    pageRoot.settingsService.saveSettings();
                                }
                            }
                        }
                    }

                    UI.Divider {
                        theme: pageRoot.theme
                        Layout.fillWidth: true
                        horizontal: true
                        visible: pageRoot.settingsService && pageRoot.settingsService.nightLightEnabled
                    }

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Color Warmth (" + (pageRoot.settingsService ? Math.round(Math.max(0, Math.min(100, ((6000 - pageRoot.settingsService.nightLightTemp) / 3500.0) * 100))) : 43) + "%)"
                        icon: "system/sun.svg"
                        visible: pageRoot.settingsService && pageRoot.settingsService.nightLightEnabled

                        UI.Slider {
                            theme: pageRoot.theme
                            implicitWidth: 160
                            min: 0
                            max: 100
                            value: pageRoot.settingsService ? Math.round(Math.max(0, Math.min(100, ((6000 - pageRoot.settingsService.nightLightTemp) / 3500.0) * 100))) : 43
                            onMoved: val => {
                                if (pageRoot.settingsService) {
                                    var kelvin = Math.round(6000 - (val / 100.0) * 3500);
                                    pageRoot.settingsService.nightLightTemp = kelvin;
                                }
                            }
                            onReleased: val => {
                                if (pageRoot.settingsService) {
                                    var kelvin = Math.round(6000 - (val / 100.0) * 3500);
                                    pageRoot.settingsService.nightLightTemp = kelvin;
                                    pageRoot.settingsService.applyNightLight(pageRoot.settingsService.nightLightEnabled, kelvin);
                                    pageRoot.settingsService.saveSettings();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
