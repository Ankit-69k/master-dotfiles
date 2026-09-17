import QtQuick
import QtQuick.Layouts
import "../components"
import "../services"
import "../theme"

Panel {
    id: root

    Popup {
        title: "Wi-Fi"
        checked: NetworkService.wifiEnabled
        onToggled: NetworkService.toggleWifi()
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

    Repeater {
        model: NetworkService.networks
        delegate: NetworkRow {
            ssid: modelData.ssid
            signal: modelData.signal
            secured: modelData.secured
            active: modelData.active
        }
    }

    Text {
        visible: NetworkService.networks.length === 0
        text: NetworkService.scanning ? "Scanning…" : "No networks found"
        color: Theme.subtext
    }
}
