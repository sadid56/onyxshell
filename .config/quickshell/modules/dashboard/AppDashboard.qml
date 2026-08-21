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

        for (var i = 0; i < baseList.length; i++) {
            var app = baseList[i];
            var name = (app.name || "").toLowerCase();
            var comment = (app.comment || "").toLowerCase();
            var exec = (app.exec || "").toLowerCase();

            var score = 0;
            if (name === query) {
                score += 1000;
            } else if (name.indexOf(query) === 0) {
                score += 500;
            } else if (name.indexOf(" " + query) !== -1 || name.indexOf("-" + query) !== -1) {
                score += 300;
            } else if (name.indexOf(query) !== -1) {
                score += 150;
            } else if (exec.indexOf(query) !== -1) {
                score += 80;
            } else if (comment.indexOf(query) !== -1) {
                score += 40;
            }

            if (score > 0) {
                score += Math.max(0, 50 - Math.abs(name.length - query.length));
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

    function updateAppsModel() {
        var filtered = getFilteredApps();
        modelUtils.syncListModel(dynamicAppsModel, filtered, "name", 0);
        if (appsGrid && appsGrid.count > 0) {
            appsGrid.currentIndex = 0;
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
        } else if (action === "suspend") {
            askConfirmation({
                title: "Suspend System",
                message: "Are you sure you want to put the computer to sleep?",
                icon: "system/moon.svg",
                confirmText: "Sleep",
                isDanger: false,
                onConfirm: () => {
                    Quickshell.execDetached(["systemctl", "suspend"]);
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
        onEscapePressed: dashboardWindow.active = false
        onReturnPressed: {
            var filtered = dashboardWindow.getFilteredApps();
            if (filtered.length > 0) {
                var targetIdx = (appsGrid.currentIndex >= 0 && appsGrid.currentIndex < filtered.length) ? appsGrid.currentIndex : 0;
                dashboardWindow.launchApp(filtered[targetIdx]);
            }
        }
        onDownPressed: {
            appsGrid.focus = true;
            if (appsGrid.count > 0) {
                if (appsGrid.currentIndex < 0) appsGrid.currentIndex = 0;
                appsGrid.updatePillPosition();
            }
        }
        onSearchTextChanged: {
            dashboardWindow.searchQuery = searchText;
            if (searchText && searchText.trim().length > 0 && dashboardWindow.selectedCategory !== "All") {
                dashboardWindow.selectedCategory = "All";
            }
        }
        onActionTriggered: action => dashboardWindow.handlePowerAction(action)
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
                    updatePillPosition();
                }

                onCountChanged: {
                    if (count > 0) {
                        if (currentIndex < 0 || currentIndex >= count) currentIndex = 0;
                        updatePillPosition();
                    } else {
                        gridHoverPill.isHovered = false;
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Up) {
                        if (currentIndex < cols) {
                            header.forceSearchFocus();
                            gridHoverPill.isHovered = false;
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
                        if (currentIndex >= 0 && currentIndex < count) {
                            var filtered = dashboardWindow.getFilteredApps();
                            if (filtered.length > currentIndex) {
                                dashboardWindow.launchApp(filtered[currentIndex]);
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
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 280; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; from: 0.88; to: 1.0; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.12 }
                    }
                }

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 260; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; from: 0.86; to: 1.0; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
                    }
                }

                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0.0; duration: 180; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; to: 0.86; duration: 180; easing.type: Easing.OutCubic }
                    }
                }

                move: Transition { NumberAnimation { properties: "x,y"; duration: 340; easing.type: Easing.OutCubic } }
                displaced: Transition { NumberAnimation { properties: "x,y"; duration: 340; easing.type: Easing.OutCubic } }

                delegate: Item {
                    id: delegateWrapper
                    width: appsGrid.cellWidth
                    height: appsGrid.cellHeight
                    z: 1

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
                            if (!appsGrid.activeFocus) {
                                gridUnhoverTimer.restart();
                            }
                        }

                        onClicked: appData => dashboardWindow.launchApp(appData)
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                visible: dynamicAppsModel.count === 0

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
