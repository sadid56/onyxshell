import QtQuick
import Quickshell

QtObject {
    id: paths

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string quickshellDir: home + "/.config/qs"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")) + "/qs"
    readonly property string cToolsDir: quickshellDir + "/c_tools"
    readonly property string binDir: cToolsDir + "/bin"

    // Central registry for all high-performance C binaries
    readonly property string sysTelemetry: binDir + "/sys_telemetry"
    readonly property string sysResources: binDir + "/sys_resources"
    readonly property string decodeClip: binDir + "/decode_clip"
    readonly property string toggleFloat: binDir + "/toggle_float"

    function get(toolName) {
        return binDir + "/" + toolName;
    }
}
