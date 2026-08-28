import QtQuick

Loader {
    id: loaderRoot

    property bool loaded: false
    active: loaded
    property int unloadDelay: 60000
    property bool autoUnloadEnabled: true

    signal itemInitialized(var item)

    onLoaded: {
        if (item) {
            loaderRoot.itemInitialized(item);
        }
    }

    Connections {
        target: (loaderRoot.autoUnloadEnabled && loaderRoot.item && typeof loaderRoot.item.activeChanged !== "undefined") ? loaderRoot.item : null
        function onActiveChanged() {
            if (!loaderRoot.item) return;
            if (!loaderRoot.item.active) {
                unloadTimer.restart();
            } else {
                unloadTimer.stop();
            }
        }
    }

    Timer {
        id: unloadTimer
        interval: loaderRoot.unloadDelay
        repeat: false
        onTriggered: {
            if (loaderRoot.autoUnloadEnabled && (!loaderRoot.item || !loaderRoot.item.active)) {
                loaderRoot.loaded = false;
                if (typeof gc === "function") gc();
            }
        }
    }
}
