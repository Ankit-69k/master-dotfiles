import QtQuick
import QtQuick.Layouts
import "../services"
import "../theme"

Item {
    id: root
    property string ssid
    property int signal
    property bool secured
    property bool active

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        Text {
            text: signal >= 70 ? "󰤨" : signal >= 40 ? "󰤢" : "󰤟"
            color: active ? Theme.accent : Theme.foreground
        }

        Text {
            text: ssid
            color: active ? Theme.accent : Theme.foreground
            font.bold: active
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Text {
            visible: secured
            text: "󰌾"
            color: Theme.subtext
            font.pixelSize: 11
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (active) return
            NetworkService.connectTo(ssid, "")
        }
    }
}
