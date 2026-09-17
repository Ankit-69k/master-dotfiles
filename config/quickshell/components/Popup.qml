import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    property string title
    property bool checked
    signal toggled()

    Layout.fillWidth: true

    Text {
        text: title
        color: Theme.foreground
        font.bold: true
        font.pixelSize: Theme.fontSize + 1
        Layout.fillWidth: true
    }

    Rectangle {
        width: 36; height: 20; radius: 10
        color: checked ? Theme.accent : Theme.surface
        border.color: Theme.border

        Rectangle {
            width: 16; height: 16; radius: 8
            color: Theme.background
            anchors.verticalCenter: parent.verticalCenter
            x: checked ? parent.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: 120 } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: toggled()
        }
    }
}
