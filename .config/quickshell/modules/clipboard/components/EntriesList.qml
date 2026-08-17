import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

UI.AnimatedListView {
    id: entriesListRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: Math.min(380, count * 54)
    spacing: 8
    focus: true
    pillColor: entriesListRoot.theme.getColor("surfaceVariant")

    property var theme
    property var clipService
    property string searchQuery: ""
    property var entriesModel: []
    onEntriesModelChanged: syncListModel(dynamicClipModel, entriesModel, "", 20)

    signal entryClicked(string entryText)
    signal deleteClicked(string entryText)
    signal upPressedAtStart()
    signal escapePressed()

    ListModel {
        id: dynamicClipModel
    }

    model: dynamicClipModel
    currentIndex: -1

    delegate: Item {
        id: delegateWrapper
        width: entriesListRoot.width
        height: 52
        z: 1

        readonly property string entryText: entryData !== undefined ? entryData : (modelData !== undefined ? modelData : "")
        readonly property bool isHighlighted: entriesListRoot.isItemHighlighted(index)
        property bool isImage: entriesListRoot.clipService ? entriesListRoot.clipService.isImageEntry(entryText) : false
        property string imageSource: (isImage && entriesListRoot.clipService) ? entriesListRoot.clipService.getImagePreview(entryText) : ""
        property string cleanDisplay: entryText.indexOf("\t") !== -1 ? entryText.substring(entryText.indexOf("\t") + 1).replace(/\r?\n|\r/g, " ") : entryText.replace(/\r?\n|\r/g, " ")

        transform: Translate {
            id: slideTrans
            y: 0
        }

        ParallelAnimation {
            id: entranceAnim
            NumberAnimation {
                target: slideTrans
                property: "y"
                from: 14
                to: 0
                duration: 260
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
            NumberAnimation {
                target: delegateWrapper
                property: "opacity"
                from: 0.90
                to: 1.0
                duration: 220
                easing.type: Easing.OutQuad
            }
        }

        onEntryTextChanged: entranceAnim.restart()

        Connections {
            target: entriesListRoot
            function onSearchQueryChanged() {
                entranceAnim.restart();
            }
        }

        Component.onCompleted: {
            entranceAnim.restart();
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                entriesListRoot.hoverItem(index, delegateWrapper.y, delegateWrapper.height);
            }
            onExited: {
                entriesListRoot.unhoverItem(index);
            }
            onClicked: {
                entriesListRoot.entryClicked(delegateWrapper.entryText);
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 12

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: entriesListRoot.theme.getColor("surface")
                Layout.alignment: Qt.AlignVCenter
                clip: true

                Image {
                    anchors.fill: parent
                    source: delegateWrapper.imageSource
                    fillMode: Image.PreserveAspectCrop
                    visible: delegateWrapper.isImage && delegateWrapper.imageSource !== ""
                }

                Text {
                    anchors.centerIn: parent
                    text: delegateWrapper.isImage ? "󰋩" : "󰆏"
                    font.family: "Noto Sans"
                    font.pixelSize: 14
                    color: delegateWrapper.isHighlighted ? entriesListRoot.theme.getColor("primary") : entriesListRoot.theme.getColor("outline")
                    visible: !delegateWrapper.isImage || delegateWrapper.imageSource === ""

                    Behavior on color { ColorAnimation { duration: 140 } }
                }
            }

            Text {
                text: delegateWrapper.cleanDisplay
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 13
                font.bold: false
                color: delegateWrapper.isHighlighted ? entriesListRoot.theme.getColor("primary") : entriesListRoot.theme.getColor("onSurface")
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 140 } }
            }

            Rectangle {
                id: deleteBtn
                width: 24
                height: 24
                radius: 12
                color: deleteMouse.containsMouse ? entriesListRoot.theme.getColor("errorContainer") : "transparent"
                Layout.alignment: Qt.AlignVCenter
                visible: mouseArea.containsMouse

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: "Noto Sans"
                    font.pixelSize: 13
                    color: deleteMouse.containsMouse ? entriesListRoot.theme.getColor("onErrorContainer") : entriesListRoot.theme.getColor("outline")
                }

                MouseArea {
                    id: deleteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        entriesListRoot.deleteClicked(delegateWrapper.entryText);
                    }
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
                entriesListRoot.upPressedAtStart();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Return) {
            if (currentIndex >= 0 && currentIndex < count) {
                var itm = dynamicClipModel.get(currentIndex);
                if (itm) {
                    var str = itm.entryData !== undefined ? itm.entryData : itm;
                    entriesListRoot.entryClicked(str);
                }
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            entriesListRoot.escapePressed();
            event.accepted = true;
        }
    }
}
