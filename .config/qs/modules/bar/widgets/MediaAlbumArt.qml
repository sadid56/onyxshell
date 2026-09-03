import QtQuick
import QtQuick.Effects
import Quickshell.Widgets

ClippingRectangle {
    id: albumArtRect
    width: 78
    height: 78
    radius: 14
    color: theme ? theme.getColor("surface") : "#1b1b1b"

    property var theme
    property string mediaArtUrl: ""
    property bool hasMedia: false

    Image {
        id: albumArtImage
        anchors.fill: parent
        source: albumArtRect.mediaArtUrl
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(156, 156)
        visible: albumArtRect.hasMedia && albumArtRect.mediaArtUrl !== "" && status === Image.Ready
        asynchronous: true
    }

    IconImage {
        anchors.centerIn: parent
        width: 32
        height: 32
        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("media/music.svg")
        visible: !albumArtImage.visible
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: albumArtRect.theme ? albumArtRect.theme.getColor("primary") : "#a8c88e"
        }
    }
}
