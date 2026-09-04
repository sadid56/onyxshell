import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

ClippingRectangle {
    id: mediaRoot
    Layout.fillWidth: true
    height: 120
    radius: 18
    color: mediaRoot.theme ? mediaRoot.theme.getColor("surfaceVariant") : "#2b2a27"
    property var theme
    property var mediaService: null
    property string mediaStatus: mediaService ? mediaService.mediaStatus : "Stopped"
    property bool optimisticPlaying: mediaStatus === "Playing"
    onMediaStatusChanged: optimisticPlaying = (mediaStatus === "Playing")
    property string mediaTitle: mediaService ? mediaService.mediaTitle : "No media playing"
    property string mediaArtist: mediaService ? mediaService.mediaArtist : ""
    property string mediaArtUrl: mediaService ? mediaService.mediaArtUrl : ""
    property int mediaPosition: mediaService ? mediaService.mediaPosition : 0
    property int mediaLength: mediaService ? mediaService.mediaLength : 0
    readonly property bool isPlaying: optimisticPlaying
    readonly property bool hasMedia: mediaStatus !== "Stopped" && mediaTitle !== "" && mediaTitle !== "No media playing"
    signal controlAction(string action)
    function formatTime(secs) {
        if (isNaN(secs) || secs < 0) return "0:00";
        var m = Math.floor(secs / 60);
        var s = secs % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
    Image {
        id: bgCoverArt
        anchors.fill: parent
        source: mediaRoot.mediaArtUrl
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(360, 120)
        opacity: 0.18
        visible: mediaRoot.hasMedia && mediaRoot.mediaArtUrl !== ""
        asynchronous: true
    }
    Rectangle {
        anchors.fill: parent
        color: mediaRoot.theme ? mediaRoot.theme.getColor("surfaceVariant") : "#2b2a27"
        opacity: (mediaRoot.hasMedia && mediaRoot.mediaArtUrl !== "") ? 0.65 : 0.0
    }
    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14
        MediaAlbumArt {
            theme: mediaRoot.theme
            mediaArtUrl: mediaRoot.mediaArtUrl
            hasMedia: mediaRoot.hasMedia
            Layout.alignment: Qt.AlignVCenter
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    UI.Typography {
                        theme: mediaRoot.theme
                        text: mediaRoot.mediaTitle
                        variant: "titleSmall"
                        colorRole: "onSurface"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    UI.Typography {
                        theme: mediaRoot.theme
                        text: mediaRoot.mediaArtist !== "" ? mediaRoot.mediaArtist : (mediaRoot.hasMedia ? "Unknown Artist" : "")
                        variant: "bodySmall"
                        colorRole: "outline"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    UI.Typography {
                        theme: mediaRoot.theme
                        text: mediaRoot.mediaLength > 0 ? (mediaRoot.formatTime(mediaRoot.mediaPosition) + " / " + mediaRoot.formatTime(mediaRoot.mediaLength)) : (mediaRoot.hasMedia ? "0:00 / 0:00" : "")
                        variant: "bodySmall"
                        font.bold: true
                        colorRole: "outline"
                        Layout.topMargin: 2
                    }
                }

                Rectangle {
                    width: 46
                    height: 46
                    radius: 16
                    color: mediaRoot.theme ? mediaRoot.theme.getColor("primary") : "#a8c88e"
                    Layout.alignment: Qt.AlignVCenter
                    IconImage {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(mediaRoot.isPlaying ? "media/pause.svg" : "media/play.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: mediaRoot.theme ? mediaRoot.theme.getColor("onPrimary") : "#1b2e11"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scale = 1.08
                        onExited: parent.scale = 1.0
                        onClicked: {
                            mediaRoot.optimisticPlaying = !mediaRoot.optimisticPlaying;
                            if (mediaRoot.mediaService) mediaRoot.mediaService.playPause();
                            mediaRoot.controlAction("play-pause");
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Layout.alignment: Qt.AlignVCenter
                IconImage {
                    width: 16
                    height: 16
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("media/skip-back.svg")
                    opacity: 0.85
                    Layout.alignment: Qt.AlignVCenter
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: mediaRoot.theme ? mediaRoot.theme.getColor("onSurface") : "#ffffff"
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: { parent.scale = 1.25; parent.opacity = 1.0; }
                        onExited: { parent.scale = 1.0; parent.opacity = 0.85; }
                        onClicked: {
                            if (mediaRoot.mediaService) mediaRoot.mediaService.previous();
                            mediaRoot.controlAction("previous");
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 120 } }
                }
                MediaWaveProgressBar {
                    id: waveCanvas
                    Layout.fillWidth: true
                    height: 14
                    Layout.alignment: Qt.AlignVCenter
                    theme: mediaRoot.theme
                    mediaService: mediaRoot.mediaService
                    isPlaying: mediaRoot.isPlaying
                    isWindowActive: (typeof mediaWindow !== "undefined" && mediaWindow) ? Boolean(mediaWindow.active || (mediaWindow.visible && mediaWindow.opacity > 0.01)) : true
                    mediaLength: mediaRoot.mediaLength
                    mediaPosition: mediaRoot.mediaPosition
                }
                IconImage {
                    width: 16
                    height: 16
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("media/skip-forward.svg")
                    opacity: 0.85
                    Layout.alignment: Qt.AlignVCenter
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: mediaRoot.theme ? mediaRoot.theme.getColor("onSurface") : "#ffffff"
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: { parent.scale = 1.25; parent.opacity = 1.0; }
                        onExited: { parent.scale = 1.0; parent.opacity = 0.85; }
                        onClicked: {
                            if (mediaRoot.mediaService) mediaRoot.mediaService.next();
                            mediaRoot.controlAction("next");
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 120 } }
                }
            }
        }
    }
}
