import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../components/ui" as UI

UI.AnimatedListView {
    id: appListRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: Math.min(380, count * 54)
    pillColor: appListRoot.theme ? appListRoot.theme.getColor("surfaceVariant") : "#2b2a27"

    property var appsModel: []
    onAppsModelChanged: syncListModel(dynamicAppModel, appsModel, "name", 12)

    signal appClicked(var app)
    signal upPressedAtStart()
    signal escapePressed()

    function getIconSource(iconName) {
        if (!iconName) return "file://" + shellConfig.defaultAppIcon;
        if (iconName.indexOf("/") === 0) {
            return "file://" + iconName;
        }
        return "file://" + shellConfig.defaultAppIcon;
    }

    ListModel {
        id: dynamicAppModel
    }

    model: dynamicAppModel
    currentIndex: -1

    delegate: Item {
        id: delegateWrapper
        width: appListRoot.width
        height: 48
        z: 1

        readonly property var appInfo: ({ "name": name, "exec": exec, "icon": icon, "comment": comment })
        readonly property bool isHighlighted: appListRoot.isItemHighlighted(index)

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                appListRoot.hoverItem(index, delegateWrapper.y, delegateWrapper.height);
            }
            onExited: {
                appListRoot.unhoverItem(index);
            }
            onClicked: {
                appListRoot.appClicked(delegateWrapper.appInfo);
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 12

            Image {
                id: appIcon
                width: 24
                height: 24
                sourceSize.width: 24
                sourceSize.height: 24
                source: appListRoot.getIconSource(icon)
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignVCenter

                onStatusChanged: {
                    if (status === Image.Error) {
                        source = "file://" + shellConfig.defaultAppIcon;
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: name
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 13
                    font.bold: true
                    color: delegateWrapper.isHighlighted ? appListRoot.theme.getColor("primary") : appListRoot.theme.getColor("onSurface")
                    elide: Text.ElideRight
                    Layout.fillWidth: true

                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                Text {
                    text: comment || exec
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 11
                    color: appListRoot.theme.getColor("outline")
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: (comment || exec) !== ""
                }
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Down) {
            if (currentIndex < count - 1) {
                currentIndex++;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            if (currentIndex > 0) {
                currentIndex--;
            } else if (currentIndex === 0) {
                currentIndex = -1;
                appListRoot.upPressedAtStart();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Return) {
            if (currentIndex >= 0 && currentIndex < count) {
                var itm = dynamicAppModel.get(currentIndex);
                if (itm) {
                    appListRoot.appClicked(itm);
                }
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            appListRoot.escapePressed();
            event.accepted = true;
        }
    }
}
