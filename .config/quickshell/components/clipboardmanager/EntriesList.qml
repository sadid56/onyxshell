import QtQuick
import QtQuick.Layouts

ListView {
    id: entriesListRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: contentHeight
    clip: true
    spacing: 8

    property var theme
    property var clipService
    property alias entriesModel: entriesListRoot.model

    signal entryClicked(string entryText)
    signal deleteClicked(string entryText)

    add: Transition {
        NumberAnimation { properties: "opacity,scale"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
    }
    remove: Transition {
        NumberAnimation { properties: "opacity,scale"; to: 0.0; duration: 150 }
    }
    displaced: Transition {
        NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutBack }
    }

    delegate: Rectangle {
        id: delegateBg
        width: entriesListRoot.width
        radius: 10
        color: mouseArea.containsMouse ? entriesListRoot.theme.getColor("surfaceVariant") : "transparent"
        
        property string entryText: modelData
        property bool isImage: entriesListRoot.clipService ? entriesListRoot.clipService.isImageEntry(entryText) : false
        property string imageSource: (isImage && entriesListRoot.clipService) ? entriesListRoot.clipService.getImagePreview(entryText) : ""
        property string cleanDisplay: entryText.substring(entryText.indexOf("\t") + 1).replace(/\r?\n|\r/g, " ")

        // Dynamic height: taller for image entries
        height: isImage && imageSource !== "" ? 80 : 46

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                entriesListRoot.entryClicked(delegateBg.entryText);
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // Icon or Image Thumbnail
            Item {
                Layout.preferredWidth: delegateBg.isImage && delegateBg.imageSource !== "" ? 60 : 20
                Layout.preferredHeight: delegateBg.isImage && delegateBg.imageSource !== "" ? 56 : 20
                Layout.alignment: Qt.AlignVCenter

                // Text icon for non-image entries
                Text {
                    anchors.centerIn: parent
                    text: "󰅍"
                    font.family: "Noto Sans"
                    font.pixelSize: 15
                    color: entriesListRoot.theme.getColor("primary")
                    visible: !(delegateBg.isImage && delegateBg.imageSource !== "")
                }

                // Image thumbnail for image entries
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: entriesListRoot.theme.getColor("surfaceVariant")
                    visible: delegateBg.isImage && delegateBg.imageSource !== ""
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: delegateBg.imageSource
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                    }
                }
            }

            // Text content
            Text {
                text: delegateBg.isImage ? "📷 Image" : delegateBg.cleanDisplay
                font.family: "Noto Sans"
                font.pixelSize: 12
                color: entriesListRoot.theme.getColor("onSurface")
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.alignment: Qt.AlignVCenter
            }

            // Delete button
            Text {
                text: ""
                font.family: "Noto Sans"
                font.pixelSize: 13
                color: entriesListRoot.theme.getColor("error")
                opacity: mouseArea.containsMouse ? 1.0 : 0.0
                Layout.alignment: Qt.AlignVCenter

                Behavior on opacity { NumberAnimation { duration: 150 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        entriesListRoot.deleteClicked(delegateBg.entryText);
                    }
                }
            }
        }
    }
}
