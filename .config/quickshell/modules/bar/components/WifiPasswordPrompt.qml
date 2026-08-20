import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

ColumnLayout {
    id: promptRoot
    Layout.fillWidth: true
    spacing: 14

    property var theme
    property string selectedSsid: ""
    property var wifiConnector
    property string errorMessage: ""
    property bool isConnecting: false
    readonly property bool isValidPassword: passwordInput.text.trim().length >= 8

    signal cancelRequested()
    signal connectRequested(string password)

    function focusInput() {
        passwordInput.forceFocus();
        errorMessage = "";
        isConnecting = false;
    }

    function showError(msg) {
        isConnecting = false;
        errorMessage = msg && msg !== "" ? msg : "Incorrect password. Please try again.";
        passwordInput.forceFocus();
    }

    Text {
        text: "Connect to Network"
        font.family: "Noto Sans"
        font.pixelSize: 15
        font.bold: true
        color: promptRoot.theme ? promptRoot.theme.getColor("onSurface") : "#FFFFFF"
    }

    Text {
        text: promptRoot.selectedSsid
        font.family: "Google Sans Flex, sans-serif"
        font.pixelSize: 13
        font.bold: true
        color: promptRoot.theme ? promptRoot.theme.getColor("primary") : "#ADC6FF"
        elide: Text.ElideRight
        Layout.fillWidth: true
    }

    UI.Input {
        id: passwordInput
        theme: promptRoot.theme
        placeholder: "Enter password (min 8 chars)..."
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("lock-closed.svg")
        echoMode: TextInput.Password
        onTextChanged: {
            if (promptRoot.errorMessage !== "") {
                promptRoot.errorMessage = "";
            }
        }
        onEscapePressed: {
            passwordInput.text = "";
            promptRoot.errorMessage = "";
            promptRoot.cancelRequested();
        }
        onReturnPressed: {
            if (promptRoot.isValidPassword && !promptRoot.isConnecting) {
                promptRoot.isConnecting = true;
                promptRoot.errorMessage = "";
                promptRoot.connectRequested(passwordInput.text);
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: promptRoot.errorMessage !== ""

        IconImage {
            width: 14
            height: 14
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("alert.svg")
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: promptRoot.theme ? promptRoot.theme.getColor("error") : "#FF5555"
            }
        }

        Text {
            Layout.fillWidth: true
            text: promptRoot.errorMessage
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 11
            font.bold: true
            color: promptRoot.theme ? promptRoot.theme.getColor("error") : "#FF5555"
            wrapMode: Text.Wrap
            Layout.alignment: Qt.AlignVCenter
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: 8
            color: promptRoot.theme ? promptRoot.theme.getColor("surfaceVariant") : "#333333"

            Text {
                anchors.centerIn: parent
                text: "Cancel"
                font.family: "Noto Sans"
                font.pixelSize: 12
                font.bold: true
                color: promptRoot.theme ? promptRoot.theme.getColor("onSurface") : "#FFFFFF"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    passwordInput.text = "";
                    promptRoot.errorMessage = "";
                    promptRoot.isConnecting = false;
                    promptRoot.cancelRequested();
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: 8
            color: promptRoot.isValidPassword
                   ? (promptRoot.theme ? promptRoot.theme.getColor("primary") : "#ADC6FF")
                   : (promptRoot.theme ? promptRoot.theme.getColor("surfaceVariant") : "#333333")
            opacity: (promptRoot.isValidPassword && !promptRoot.isConnecting) ? 1.0 : 0.45

            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: promptRoot.isConnecting ? "Connecting..." : "Connect"
                font.family: "Noto Sans"
                font.pixelSize: 12
                font.bold: true
                color: promptRoot.isValidPassword
                       ? (promptRoot.theme ? promptRoot.theme.getColor("onPrimary") : "#000000")
                       : (promptRoot.theme ? promptRoot.theme.getColor("outline") : "#777777")
            }

            MouseArea {
                anchors.fill: parent
                enabled: promptRoot.isValidPassword && !promptRoot.isConnecting
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (promptRoot.isValidPassword && !promptRoot.isConnecting) {
                        promptRoot.isConnecting = true;
                        promptRoot.errorMessage = "";
                        promptRoot.connectRequested(passwordInput.text);
                    }
                }
            }
        }
    }
}
