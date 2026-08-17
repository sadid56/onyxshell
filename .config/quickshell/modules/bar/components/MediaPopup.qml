import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../components/containers"
import "../../controlcenter/widgets"

Popup {
    id: mediaPopupWindow

    popupWidth: 440
    popupHeight: 120 + topOverlap + 32

    property var mediaService: typeof root !== "undefined" ? root.mediaService : null

    onActiveChanged: {
        if (active && mediaPopupWindow.mediaService) {
            mediaPopupWindow.mediaService.refresh();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: mediaPopupWindow.active
        onActivated: mediaPopupWindow.active = false
    }

    MediaControls {
        id: mediaControlsWidget
        theme: mediaPopupWindow.theme
        mediaService: mediaPopupWindow.mediaService
    }
}
