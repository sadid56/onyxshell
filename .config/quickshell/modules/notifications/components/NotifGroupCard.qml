import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "./"

Rectangle {
    id: groupCardRoot
    width: ListView.view ? ListView.view.width : (parent ? parent.width : 380)
    height: isExpanded ? (groupMainCol.implicitHeight + 20) : 58
    implicitHeight: height
    radius: 16
    color: groupCardRoot.theme ? groupCardRoot.theme.getColor("surfaceVariant") : "#2b2a2a"
    clip: true

    property var theme
    property var groupData: modelData
    property var parentList
    property bool isExpanded: parentList ? parentList.isGroupExpanded(groupName) : false

    function toggleGroup() {
        var nextState = !isExpanded;
        if (parentList) parentList.setGroupExpanded(groupName, nextState);
        else isExpanded = nextState;
    }

    readonly property string groupName: groupData ? (groupData.appName || "Application") : "Application"
    readonly property string groupIcon: groupData ? (groupData.appIcon || "") : ""
    readonly property var groupItems: (groupData && groupData.items) ? groupData.items : []
    readonly property int groupCount: groupItems.length

    function getGroupAppIcon() {
        if (!groupIcon) return "file://" + shellConfig.defaultAppIcon;
        return groupIcon.indexOf("/") === 0 ? ("file://" + groupIcon) : groupIcon;
    }

    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

    ColumnLayout {
        id: groupMainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        spacing: 8

        // Group Header Bar
        Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: 12
            color: groupCardRoot.theme ? groupCardRoot.theme.getColor("surface") : "#1e1e1e"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: groupCardRoot.toggleGroup()
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                // App Icon
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: "transparent"
                    clip: true
                    Layout.alignment: Qt.AlignVCenter

                    IconImage {
                        anchors.fill: parent
                        source: groupCardRoot.getGroupAppIcon()
                        onStatusChanged: {
                            if (status === Image.Error) source = "file://" + shellConfig.defaultAppIcon;
                        }
                    }
                }

                // App Name
                Text {
                    text: groupCardRoot.groupName
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 12
                    font.bold: true
                    color: groupCardRoot.theme ? groupCardRoot.theme.getColor("onSurface") : "#FFFFFF"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                // Count Badge
                Rectangle {
                    height: 20
                    implicitWidth: Math.max(20, countText.implicitWidth + 10)
                    radius: 10
                    color: groupCardRoot.theme ? groupCardRoot.theme.getColor("surfaceVariant") : "#333333"
                    visible: groupCardRoot.groupCount > 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: String(groupCardRoot.groupCount)
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 10
                        font.bold: true
                        color: groupCardRoot.theme ? groupCardRoot.theme.getColor("primary") : "#ffb3b4"
                    }
                }

                // Clear Group Button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: "transparent"
                    opacity: clearMouse.containsMouse ? 0.7 : 1.0
                    Layout.alignment: Qt.AlignVCenter

                    IconImage {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/dismiss.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: groupCardRoot.theme ? groupCardRoot.theme.getColor("outline") : "#888888"
                        }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            for (var i = 0; i < groupCardRoot.groupItems.length; i++) {
                                var it = groupCardRoot.groupItems[i];
                                if (it && it.rawNotif && typeof it.rawNotif.dismiss === "function") {
                                    it.rawNotif.dismiss();
                                }
                            }
                        }
                    }
                }

                // Chevron Expand/Collapse
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: "transparent"
                    Layout.alignment: Qt.AlignVCenter

                    IconImage {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/chevron-down.svg")
                        rotation: groupCardRoot.isExpanded ? 180 : 0
                        Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: groupCardRoot.theme ? groupCardRoot.theme.getColor("onSurface") : "#FFFFFF"
                        }
                    }
                }
            }
        }

        // Expanded Notification Items Column
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: groupCardRoot.isExpanded
            opacity: groupCardRoot.isExpanded ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 160 } }

            Repeater {
                model: groupCardRoot.groupItems

                delegate: NotifCard {
                    Layout.fillWidth: true
                    theme: groupCardRoot.theme
                    notifItem: modelData
                    parentList: groupCardRoot.parentList
                    onDismissRequested: {
                        if (modelData.rawNotif && typeof modelData.rawNotif.dismiss === "function") {
                            modelData.rawNotif.dismiss();
                        }
                    }
                }
            }
        }
    }
}
