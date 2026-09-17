pragma Singleton
import QtQuick

QtObject {
    // colors — swap these for your catppuccin-mocha palette values
    readonly property color background: "#1e1e2e"
    readonly property color surface:    "#313244"
    readonly property color foreground: "#cdd6f4"
    readonly property color subtext:    "#a6adc8"
    readonly property color accent:     "#89b4fa"
    readonly property color danger:     "#f38ba8"
    readonly property color border:     "#45475a"

    readonly property int radius: 12
    readonly property int spacing: 8
    readonly property int panelWidth: 300

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
}
