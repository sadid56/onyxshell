import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../components/ui" as UI

Item {
    id: mediaBarRoot

    property var theme
    property var mediaService
    property var toggleMedia

    readonly property bool isPlaying: mediaBarRoot.mediaService ? Boolean(mediaBarRoot.mediaService.isPlaying) : false
    readonly property bool hasMedia: mediaBarRoot.mediaService ? Boolean(mediaBarRoot.mediaService.hasMedia) : false

    implicitHeight: 28
    implicitWidth: hasMedia ? Math.min(240, contentRow.implicitWidth + 12) : 0
    visible: opacity > 0.001
    opacity: hasMedia ? 1.0 : 0.0
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

    Layout.alignment: Qt.AlignVCenter

    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            if (typeof root !== "undefined" && root.stopLoaderTimerAndActivate && typeof mediaLoader !== "undefined" && typeof statusBar !== "undefined") {
                root.stopLoaderTimerAndActivate(mediaLoader, statusBar.getMediaX());
            }
        }
        onExited: {
            if (typeof root !== "undefined" && root.restartLoaderTimer && typeof mediaLoader !== "undefined") {
                root.restartLoaderTimer(mediaLoader);
            }
        }
        onClicked: {
            if (mediaBarRoot.toggleMedia) {
                mediaBarRoot.toggleMedia();
            } else if (typeof root !== "undefined" && root.toggleLoaderActive && typeof mediaLoader !== "undefined" && typeof statusBar !== "undefined") {
                root.toggleLoaderActive(mediaLoader, statusBar.getMediaX());
            }
        }
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 4
        spacing: 8

        Rectangle {
            width: 1
            height: 16
            radius: 0.5
            color: mediaBarRoot.theme ? mediaBarRoot.theme.getColor("outline") : "#9f8c8c"
            opacity: 0.45
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 2
        }

        UI.Icon {
            size: 15
            icon: "media/music.svg"
            color: mediaBarRoot.theme ? mediaBarRoot.theme.getColor("primary") : "#ffb3b4"
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            Layout.fillWidth: true
            Layout.maximumWidth: 160
            Layout.alignment: Qt.AlignVCenter
            text: {
                if (!mediaBarRoot.mediaService) return "";
                var t = mediaBarRoot.mediaService.mediaTitle || "";
                var a = mediaBarRoot.mediaService.mediaArtist || "";
                if (t === "No media playing" || t === "") return "";
                return a ? (t + " • " + a) : t;
            }
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 13
            font.bold: true
            color: mediaBarRoot.theme ? mediaBarRoot.theme.getColor("onSurface") : "#FFFFFF"
            elide: Text.ElideRight
        }
    }
}
