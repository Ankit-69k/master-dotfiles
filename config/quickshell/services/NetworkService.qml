pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool connected: false
    property string activeSsid: ""
    property int signalStrength: 0
    property var networks: []   // [{ssid, signal, secured, active}]
    property bool scanning: false

    function toggleWifi() {
        powerProc.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]
        powerProc.running = true
    }

    function connectTo(ssid, password) {
        connectProc.command = password
            ? ["nmcli", "device", "wifi", "connect", ssid, "password", password]
            : ["nmcli", "device", "wifi", "connect", ssid]
        connectProc.running = true
    }

    function disconnect() {
        disconnectProc.command = ["nmcli", "device", "disconnect", "wlan0"]  // adjust iface name
        disconnectProc.running = true
    }

    function rescan() {
        scanning = true
        scanProc.running = true
    }

    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: SplitParser {
            onRead: line => root.wifiEnabled = line.trim() === "enabled"
        }
    }

    Process {
      id: scanProc
      command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,ACTIVE", "device", "wifi", "list"]
      property var list: []

      stdout: SplitParser {
        onRead: line => {
          const parts = line.split(":")
          if (parts.length < 4 || !parts[0]) return
          scanProc.list.push({
            ssid: parts[0],
            signal: parseInt(parts[1]) || 0,
            secured: parts[2] !== "" && parts[2] !== "--",
            active: parts[3] === "yes"
          })
        }
      }

      onRunningChanged: if (running) scanProc.list = []
      onExited: {
        root.networks = scanProc.list
        root.connected = scanProc.list.some(n => n.active)
        const activeNet = scanProc.list.find(n => n.active)
        root.activeSsid = activeNet ? activeNet.ssid : ""
        root.signalStrength = activeNet ? activeNet.signal : 0
        root.scanning = false
      }
    }

    Process { id: powerProc; onExited: { statusProc.running = true; root.rescan() } }
    Process { id: connectProc; onExited: root.rescan() }
    Process { id: disconnectProc; onExited: root.rescan() }

    Timer {
      interval: 10000
      running: true
      repeat: true
      onTriggered: { statusProc.running = true; root.rescan() }
    }

    Component.onCompleted: { statusProc.running = true; rescan() }
  }
