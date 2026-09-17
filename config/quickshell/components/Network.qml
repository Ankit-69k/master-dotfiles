import QtQuick
import "../services"
import "../panels"
import "../theme"

Item {
    id: root
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight
    property alias panel: networkPanel

    Text {
        id: icon
        anchors.centerIn: parent
        color: Theme.foreground
        font.family: Theme.fontFamily
        text: !NetworkService.wifiEnabled ? "󰤭"
            : NetworkService.connected ? "󰤨"
            : "󰤯"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: networkPanel.open = !networkPanel.open
    }

    NetworkPanel {
        id: networkPanel
    }
}
