import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../theme"

PanelWindow {
    id: root
    default property alias content: contentArea.children
    property alias open: root.visible

    visible: false
    implicitWidth: Theme.panelWidth
    implicitHeight: contentArea.implicitHeight + 24
    color: "transparent"

    anchors {
        top: true
        right: true   // adjust per where the trigger icon sits in your bar
    }
    margins {
        top: 8
        right: 8
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.background
        border.color: Theme.border
        border.width: 1

        Column {
            id: contentArea
            anchors.fill: parent
            anchors.margins: 12
            spacing: Theme.spacing
        }
    }

    // click-away to close
    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }
}
