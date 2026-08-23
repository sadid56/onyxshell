import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import "./components"
import "../../core"
import "../../components/containers"

Popup {
    id: dashboardWindow

    popupWidth: 800
    popupHeight: 550
    closeOnHoverOutside: true

    property string selectedCategory: "All"
    property string searchQuery: ""
    property var allApps: []

    ListModelUtils { id: modelUtils }

    ListModel {
        id: dynamicAppsModel
    }

    function getFilteredApps() {
        var baseList = allApps;
        if (selectedCategory !== "All") {
            baseList = [];
            for (var k = 0; k < allApps.length; k++) {
                var a = allApps[k];
                if (a && a.categories && a.categories.indexOf(selectedCategory) !== -1) {
                    baseList.push(a);
                }
            }
        }

        if (!searchQuery || searchQuery.trim() === "") {
            return baseList;
        }

        var scored = [];
        var query = searchQuery.trim().toLowerCase();
        var queryWords = query.split(/\s+/);

        for (var i = 0; i < baseList.length; i++) {
            var app = baseList[i];
            var name = (app.name || "").toLowerCase();
            var comment = (app.comment || "").toLowerCase();
            var exec = (app.exec || "").toLowerCase();
            // Extract just the binary name from exec (e.g. "org.gnome.Nautilus" -> "nautilus")
            var execBase = exec.split(/\s/)[0].split("/").pop().split(".").pop().toLowerCase();

            var score = 0;

            // Exact name match
            if (name === query) {
                score = 10000;
            }
            // Name starts with query
            else if (name.indexOf(query) === 0) {
                score = 5000;
            }
            // Word in name starts with query (e.g. "System Monitor" matches "mon")
            else if (name.indexOf(" " + query) !== -1 || name.indexOf("-" + query) !== -1) {
                score = 2000;
            }
            // Name contains query substring
            else if (name.indexOf(query) !== -1) {
                score = 1000;
            }
            // Exec binary name matches
            else if (execBase === query || execBase.indexOf(query) === 0) {
                score = 400;
            }
            else if (execBase.indexOf(query) !== -1) {
                score = 200;
            }
            // Comment contains query — low priority, only for single meaningful words
            else if (query.length >= 4 && comment.indexOf(query) !== -1) {
                score = 30;
            }

            if (score > 0) {
                // Bonus for shorter names (closer match)
                var lengthBonus = Math.max(0, 20 - Math.abs(name.length - query.length));
                score += lengthBonus;
                scored.push({ app: app, score: score });
            }
        }

        scored.sort((x, y) => y.score - x.score);
        var res = [];
        for (var j = 0; j < scored.length; j++) {
            res.push(scored[j].app);
        }
        return res;
    }

    property bool _isSyncing: false

    function updateAppsModel() {
        var filtered = getFilteredApps();
        gridUnhoverTimer.stop();
        _isSyncing = true;
        modelUtils.syncListModel(dynamicAppsModel, filtered, "name", 0);
        _isSyncing = false;
        if (appsGrid) {
            if (dynamicAppsModel.count > 0) {
                appsGrid.currentIndex = 0;
                pillUpdateTimer.restart();
            } else {
                appsGrid.currentIndex = -1;
                pillUpdateTimer.stop();
                gridHoverPill.isHovered = false;
            }
        }
    }

    Timer {
        id: searchDebounceTimer
        interval: 40
        repeat: false
        onTriggered: {
            updateAppsModel();
        }
    }

    onSearchQueryChanged: searchDebounceTimer.restart()
    onSelectedCategoryChanged: updateAppsModel()
    onAllAppsChanged: updateAppsModel()

    property var appsProc: Process {
        id: appsProc
        command: ["python", ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getScript("list_apps.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var txt = this.text ? this.text.trim() : "";
                    if (!txt) return;
                    var parsed = JSON.parse(txt);
                    if (parsed && parsed.length > 0) {
                        dashboardWindow.allApps = parsed;
                    }
                } catch(e) {}
            }
        }
    }

    function refreshApps() {
        appsProc.running = false;
        appsProc.running = true;
    }

    function launchApp(app) {
        if (app && app.exec) {
            dashboardWindow.active = false;
            Quickshell.execDetached(app.exec.split(/\s+/));
        }
    }

    function askConfirmation(options) {
        dashboardWindow.active = false;
        if (typeof root !== "undefined" && typeof root.confirm === "function") {
            root.confirm(options);
        } else if (typeof popupManager !== "undefined" && popupManager.confirmationModal) {
            popupManager.confirmationModal.ask(options);
        }
    }

    function handlePowerAction(action) {
        if (action === "lock") {
            askConfirmation({
                title: "Lock Screen",
                message: "Are you sure you want to lock the screen?",
                icon: "system/lock-closed.svg",
                confirmText: "Lock",
                isDanger: false,
                onConfirm: () => {
                    var cfg = ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig);
                    var home = cfg ? cfg.homeDir : Quickshell.env("HOME");
                    Quickshell.execDetached(["sh", "-c", "pidof hyprlock || hyprlock -c " + home + "/.config/hypr/config/hyprlock.conf"]);
                }
            });
        } else if (action === "logout") {
            askConfirmation({
                title: "Log Out",
                message: "Are you sure you want to log out of your session?",
                icon: "system/logout.svg",
                confirmText: "Log Out",
                isDanger: false,
                onConfirm: () => {
                    Quickshell.execDetached(["sh", "-c", "hyprctl dispatch exit || loginctl terminate-user $USER || pkill -U $UID -9 -f Hyprland"]);
                }
            });
        } else if (action === "reboot") {
            askConfirmation({
                title: "Restart Computer",
                message: "Are you sure you want to restart your computer?",
                icon: "system/arrow-clockwise-filled.svg",
                confirmText: "Restart",
                isDanger: false,
                onConfirm: () => {
                    Quickshell.execDetached(["systemctl", "reboot"]);
                }
            });
        } else if (action === "shutdown") {
            askConfirmation({
                title: "Power Off",
                message: "Are you sure you want to power off the system?",
                icon: "system/power.svg",
                confirmText: "Power Off",
                isDanger: true,
                onConfirm: () => {
                    Quickshell.execDetached(["systemctl", "poweroff"]);
                }
            });
        }
    }

    onActiveChanged: {
        if (active) {
            refreshApps();
            selectedCategory = "All";
            searchQuery = "";
            header.searchText = "";
            updateAppsModel();
            Qt.callLater(() => header.forceSearchFocus());
        }
    }

    Component.onCompleted: {
        refreshApps();
    }

    DashboardHeader {
        id: header
        theme: dashboardWindow.theme
        onActionTriggered: action => dashboardWindow.handlePowerAction(action)
        onEscapePressed: dashboardWindow.active = false
        onReturnPressed: {
            if (dynamicAppsModel.count > 0) {
                var targetIdx = (appsGrid.currentIndex >= 0 && appsGrid.currentIndex < dynamicAppsModel.count) ? appsGrid.currentIndex : 0;
                var appItem = dynamicAppsModel.get(targetIdx);
                if (appItem) {
                    dashboardWindow.launchApp(appItem);
                }
            }
        }
        onDownPressed: {
            if (appsGrid.count > 0) {
                if (appsGrid.currentIndex < 0) appsGrid.currentIndex = 0;
                var newIdx = Math.min(appsGrid.count - 1, appsGrid.currentIndex + appsGrid.cols);
                appsGrid.currentIndex = newIdx;
                appsGrid.updatePillPosition();
            }
        }
        onUpPressed: {
            if (appsGrid.count > 0 && appsGrid.currentIndex > 0) {
                var newIdx = Math.max(0, appsGrid.currentIndex - appsGrid.cols);
                appsGrid.currentIndex = newIdx;
                appsGrid.updatePillPosition();
            }
        }
        onLeftPressed: {
            if (appsGrid.count > 0 && appsGrid.currentIndex > 0) {
                appsGrid.currentIndex = appsGrid.currentIndex - 1;
                appsGrid.updatePillPosition();
            }
        }
        onRightPressed: {
            if (appsGrid.count > 0 && appsGrid.currentIndex < appsGrid.count - 1) {
                appsGrid.currentIndex = appsGrid.currentIndex + 1;
                appsGrid.updatePillPosition();
            }
        }
        onSearchTextChanged: {
            dashboardWindow.searchQuery = searchText;
            if (searchText && searchText.trim().length > 0 && dashboardWindow.selectedCategory !== "All") {
                dashboardWindow.selectedCategory = "All";
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: dashboardWindow.theme ? dashboardWindow.theme.getColor("outlineVariant") : "#30FFFFFF"
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        CategorySidebar {
            Layout.fillHeight: true
            theme: dashboardWindow.theme
            allApps: dashboardWindow.allApps
            selectedCategory: dashboardWindow.selectedCategory
            onCategorySelected: cat => {
                dashboardWindow.selectedCategory = cat;
                header.forceSearchFocus();
            }
        }

        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: dashboardWindow.theme ? dashboardWindow.theme.getColor("outlineVariant") : "#30FFFFFF"
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Timer {
                id: gridUnhoverTimer
                interval: 80
                repeat: false
                onTriggered: {
                    gridHoverPill.isHovered = false;
                }
            }

            Timer {
                id: pillUpdateTimer
                interval: 60
                repeat: false
                onTriggered: {
                    if (appsGrid.count > 0) {
                        appsGrid.updatePillPosition();
                    }
                }
            }

            GridView {
                id: appsGrid
                anchors.fill: parent
                focus: false
                keyNavigationEnabled: true
                keyNavigationWraps: false

                readonly property int targetWidth: 125
                readonly property int cols: Math.max(1, Math.floor(width / targetWidth))
                cellWidth: Math.floor(width / cols)
                cellHeight: 122
                boundsBehavior: Flickable.StopAtBounds
                visible: count > 0

                model: dynamicAppsModel

                function updatePillPosition() {
                    if (currentIndex >= 0 && currentIndex < count) {
                        var col = currentIndex % cols;
                        var row = Math.floor(currentIndex / cols);
                        gridUnhoverTimer.stop();
                        gridHoverPill.targetX = col * cellWidth + 4;
                        gridHoverPill.targetY = row * cellHeight + 4;
                        gridHoverPill.targetWidth = cellWidth - 8;
                        gridHoverPill.targetHeight = cellHeight - 8;
                        gridHoverPill.isHovered = true;
                    } else {
                        gridHoverPill.isHovered = false;
                    }
                }

                onCurrentIndexChanged: {
                    if (!dashboardWindow._isSyncing) {
                        updatePillPosition();
                    }
                }

                onCountChanged: {
                    if (count > 0) {
                        if (currentIndex < 0 || currentIndex >= count) currentIndex = 0;
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Up) {
                        if (currentIndex < cols) {
                            header.forceSearchFocus();
                            event.accepted = true;
                            return;
                        }
                        currentIndex = Math.max(0, currentIndex - cols);
                        updatePillPosition();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        currentIndex = Math.min(count - 1, currentIndex + cols);
                        updatePillPosition();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left) {
                        currentIndex = Math.max(0, currentIndex - 1);
                        updatePillPosition();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right) {
                        currentIndex = Math.min(count - 1, currentIndex + 1);
                        updatePillPosition();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        if (currentIndex >= 0 && currentIndex < dynamicAppsModel.count) {
                            var appToLaunch = dynamicAppsModel.get(currentIndex);
                            if (appToLaunch) {
                                dashboardWindow.launchApp(appToLaunch);
                            }
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        dashboardWindow.active = false;
                        event.accepted = true;
                    }
                }

                Rectangle {
                    id: gridHoverPill
                    parent: appsGrid.contentItem
                    z: 0
                    radius: 16
                    color: dashboardWindow.theme ? dashboardWindow.theme.getColor("surfaceVariant") : "#2b2a27"

                    property real targetX: 0
                    property real targetY: 0
                    property real targetWidth: 0
                    property real targetHeight: 0
                    property bool isHovered: false

                    x: targetX
                    y: targetY
                    width: targetWidth
                    height: targetHeight
                    opacity: isHovered ? 1.0 : 0.0

                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                }

                populate: Transition {
                    NumberAnimation { property: "scale"; from: 0.92; to: 1.0; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
                }

                add: Transition {
                    NumberAnimation { property: "scale"; from: 0.92; to: 1.0; duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
                }

                move: Transition {
                    NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic }
                }

                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic }
                }

                delegate: Item {
                    id: delegateWrapper
                    width: appsGrid.cellWidth
                    height: appsGrid.cellHeight
                    z: 1
                    opacity: 1.0
                    scale: 1.0

                    readonly property var appItem: ({
                        "name": model.name,
                        "exec": model.exec,
                        "icon": model.icon,
                        "comment": model.comment
                    })

                    AppCard {
                        anchors.fill: parent
                        anchors.margins: 4
                        app: delegateWrapper.appItem
                        theme: dashboardWindow.theme
                        isSelected: appsGrid.currentIndex === index

                        onHovered: {
                            gridUnhoverTimer.stop();
                            appsGrid.currentIndex = index;
                            var pos = delegateWrapper.mapToItem(appsGrid.contentItem, 0, 0);
                            gridHoverPill.targetX = pos.x + 4;
                            gridHoverPill.targetY = pos.y + 4;
                            gridHoverPill.targetWidth = delegateWrapper.width - 8;
                            gridHoverPill.targetHeight = delegateWrapper.height - 8;
                            gridHoverPill.isHovered = true;
                        }

                        onUnhovered: {
                            if (!appsGrid.activeFocus && (!header.searchText || header.searchText.trim().length === 0)) {
                                gridUnhoverTimer.restart();
                            }
                        }

                        onClicked: appData => dashboardWindow.launchApp(appData)
                    }
                }
            }

            // 1. Skeleton Loading Grid (when fetching for the first time)
            Grid {
                anchors.fill: parent
                columns: appsGrid.cols
                visible: appsProc.running && allApps.length === 0
                clip: true

                Repeater {
                    model: appsGrid.cols * 4

                    Item {
                        width: appsGrid.cellWidth
                        height: appsGrid.cellHeight

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.topMargin: 10
                            anchors.bottomMargin: 10
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 8

                            // Icon Skeleton
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 44
                                height: 44
                                radius: 14
                                color: dashboardWindow.theme ? dashboardWindow.theme.getColor("surfaceVariant") : "#2b2a27"
                                opacity: skeletonAnim.shimmerOpacity
                            }

                            // App Name Line 1 Skeleton
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 68
                                height: 11
                                radius: 5
                                color: dashboardWindow.theme ? dashboardWindow.theme.getColor("surfaceVariant") : "#2b2a27"
                                opacity: skeletonAnim.shimmerOpacity
                            }

                            // App Name Line 2 Skeleton
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 44
                                height: 9
                                radius: 4
                                color: dashboardWindow.theme ? dashboardWindow.theme.getColor("surfaceVariant") : "#2b2a27"
                                opacity: skeletonAnim.shimmerOpacity * 0.7
                            }
                        }
                    }
                }

                QtObject {
                    id: skeletonAnim
                    property real shimmerOpacity: 0.35

                    SequentialAnimation on shimmerOpacity {
                        loops: Animation.Infinite
                        running: dashboardWindow.visible && appsProc.running && allApps.length === 0

                        NumberAnimation {
                            to: 0.8
                            duration: 650
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 0.35
                            duration: 650
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            // 2. Empty Search Result State
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                visible: dynamicAppsModel.count === 0 && (!appsProc.running || allApps.length > 0)

                IconImage {
                    width: 44
                    height: 44
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/search.svg")
                    Layout.alignment: Qt.AlignHCenter
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: dashboardWindow.theme ? dashboardWindow.theme.getColor("outline") : "#777777"
                    }
                }

                Text {
                    text: "No applications found"
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                    color: dashboardWindow.theme ? dashboardWindow.theme.getColor("onSurface") : "#FFFFFF"
                }

                Text {
                    text: "Try searching with a different keyword or category"
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignHCenter
                    color: dashboardWindow.theme ? dashboardWindow.theme.getColor("outline") : "#999999"
                }
            }
        }
    }
}
