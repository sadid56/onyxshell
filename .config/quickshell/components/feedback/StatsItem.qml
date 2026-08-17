RowLayout {
    id: statsItemRoot
    spacing: 4
    
    property var theme
    property string icon: ""
    property string value: ""
    property string customColor: ""

    readonly property color displayColor: customColor !== "" 
        ? customColor 
        : (theme ? theme.getColor("onSurface") : "#FFFFFF")

    Text {
        text: statsItemRoot.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        font.bold: true
        color: statsItemRoot.displayColor
    }

    Text {
        text: statsItemRoot.value
        font.family: "Noto Sans"
        font.pixelSize: 13
        font.bold: true
        color: statsItemRoot.displayColor
    }
}
