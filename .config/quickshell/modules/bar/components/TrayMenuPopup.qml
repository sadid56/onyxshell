import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.DBusMenu
import "../../../components/containers"

Popup {
    id: trayMenuWindow

    property var activeTrayItem: null

    popupWidth: 230
    popupHeight: Math.min(480, Math.max(50, mainLayout.implicitHeight + 8))

    showCorners: true
    closeOnHoverOutside: true

    QsMenuOpener {
        id: menuOpener
        menu: trayMenuWindow.activeTrayItem ? trayMenuWindow.activeTrayItem.menu : null
    }

    function focusTrayApp(trayItem) {
        if (!trayItem) return;
        var scriptPath = (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getScript("focus_tray_window.py");
        Quickshell.execDetached([
            "python", scriptPath,
            trayItem.id || "",
            trayItem.title || "",
            trayItem.icon || ""
        ]);
    }

    Flickable {
        id: scrollArea
        parent: contentRect
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.bottomMargin: 4
        anchors.topMargin: 0
        contentWidth: width
        contentHeight: mainLayout.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: mainLayout
            width: scrollArea.width
            spacing: 2
            z: 0

            property int hoveredIndex: -1
            property real targetPillY: -100
            property real targetPillHeight: 34
            readonly property bool isPillActive: hoveredIndex >= 0

            Rectangle {
                id: glidingPill
                x: 0
                width: mainLayout.width
                height: mainLayout.targetPillHeight
                radius: 8
                color: trayMenuWindow.theme.getColor("surfaceVariant")
                border.width: 0
                z: 0
                opacity: mainLayout.isPillActive ? 1.0 : 0.0

                y: mainLayout.targetPillY

                Behavior on y {
                    NumberAnimation {
                        duration: 130
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 130
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Repeater {
                model: menuOpener.children
                delegate: Item {
                    id: delegateWrapper
                    readonly property var menuItem: modelData
                    readonly property string rawText: (menuItem && menuItem.text) ? menuItem.text : ""
                    readonly property string cleanText: rawText.replace(/<[^>]*>?/gm, "").trim()
                    readonly property bool isSep: menuItem ? !!menuItem.isSeparator : false
                    readonly property bool isValidItem: isSep || cleanText !== ""

                    visible: isValidItem
                    width: mainLayout.width
                    height: !isValidItem ? 0 : (isSep ? 8 : 34)
                    z: 1

                    readonly property bool isHighlighted: mainLayout.hoveredIndex === index
                    readonly property bool isQuitOrExit: cleanText.toLowerCase().indexOf("quit") !== -1 || cleanText.toLowerCase().indexOf("exit") !== -1

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: trayMenuWindow.theme.getColor("outline")
                        opacity: 0.25
                        visible: delegateWrapper.isSep
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        visible: !delegateWrapper.isSep && delegateWrapper.isValidItem
                        onEntered: {
                            mainLayout.hoveredIndex = index;
                            mainLayout.targetPillY = delegateWrapper.y;
                            mainLayout.targetPillHeight = delegateWrapper.height;
                        }
                        onExited: {
                            if (mainLayout.hoveredIndex === index) {
                                mainLayout.hoveredIndex = -1;
                            }
                        }
                        onClicked: {
                            if (delegateWrapper.menuItem && typeof delegateWrapper.menuItem.triggered === "function") {
                                delegateWrapper.menuItem.triggered();
                            }
                            if (!delegateWrapper.isQuitOrExit) {
                                trayMenuWindow.focusTrayApp(trayMenuWindow.activeTrayItem);
                            }
                            trayMenuWindow.active = false;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8
                        visible: !delegateWrapper.isSep && delegateWrapper.isValidItem

                        Text {
                            text: delegateWrapper.cleanText
                            font.family: "Google Sans Flex, sans-serif"
                            font.pixelSize: 12
                            font.bold: false
                            color: delegateWrapper.isQuitOrExit ? trayMenuWindow.theme.getColor("error") : (delegateWrapper.isHighlighted ? trayMenuWindow.theme.getColor("primary") : trayMenuWindow.theme.getColor("onSurface"))
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }
                }
            }
        }
    }
}
