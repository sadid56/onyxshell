import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../../../components/ui" as UI

Item {
    id: profileRoot

    property var theme
    property bool expanded: false
    property string currentProfile: "performance"
    property var setProfileProc

    signal profileSelected(string profileId)

    readonly property int selectedIndex: {
        if (profileRoot.currentProfile === "balanced") return 1;
        if (profileRoot.currentProfile === "power-saver") return 2;
        return 0;
    }

    Layout.fillWidth: true
    implicitHeight: expanded ? 40 : 0
    opacity: expanded ? 1.0 : 0.0
    visible: expanded || opacity > 0.01
    clip: true

    Behavior on implicitHeight {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 140 }
    }

    Rectangle {
        id: cardWrapper
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        radius: 12
        color: profileRoot.theme ? profileRoot.theme.getColor("surfaceVariant") : "#524343"

        Rectangle {
            id: activePill
            height: parent.height - 6
            y: 3
            radius: 9
            color: profileRoot.theme ? profileRoot.theme.getColor("primary") : "#ffb3b4"
            z: 0

            readonly property real segWidth: (cardWrapper.width - 12) / 3
            width: Math.max(0, segWidth)
            x: 3 + profileRoot.selectedIndex * (segWidth + 3)

            Behavior on x {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
            Behavior on width {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 3
            z: 1

            Repeater {
                model: [
                    { profileId: "performance", name: "Performance", icon: "system/zap.svg" },
                    { profileId: "balanced", name: "Balanced", icon: "system/memory.svg" },
                    { profileId: "power-saver", name: "Saver", icon: "system/leaf-two.svg" }
                ]

                delegate: Item {
                    id: segmentItem
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        IconImage {
                            width: 17
                            height: 17
                            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(modelData.icon)
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: profileRoot.currentProfile === modelData.profileId ?
                                       (profileRoot.theme ? profileRoot.theme.getColor("onPrimary") : "#561d21") :
                                       (profileRoot.theme ? profileRoot.theme.getColor("onSurface") : "#f0dede")
                            }
                        }

                        UI.Typography {
                            theme: profileRoot.theme
                            text: modelData.name
                            variant: "bodySmall"
                            font.bold: profileRoot.currentProfile === modelData.profileId
                            color: profileRoot.currentProfile === modelData.profileId ?
                                   (profileRoot.theme ? profileRoot.theme.getColor("onPrimary") : "#561d21") :
                                   (profileRoot.theme ? profileRoot.theme.getColor("onSurface") : "#f0dede")

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: segMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (profileRoot.setProfileProc) {
                                profileRoot.setProfileProc.command = ["powerprofilesctl", "set", modelData.profileId];
                                profileRoot.setProfileProc.running = false;
                                profileRoot.setProfileProc.running = true;
                            }
                            profileRoot.profileSelected(modelData.profileId);
                        }
                    }
                }
            }
        }
    }
}
