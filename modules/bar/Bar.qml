import Quickshell
import qs.services
import "./components"

PanelWindow {
    id: root

    signal wifiConfigRequested
    signal bluetoothConfigRequested
    signal powerMenuRequested

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 25
    color: Colors.palette.surfaceContainerLow

    Title {
        anchors.centerIn: parent
    }

    Power {
        id: power
        anchors.right: parent.right
        onMenuRequested: root.powerMenuRequested()
    }

    Clock {
        id: clock
        anchors.right: power.left
        anchors.rightMargin: 5
    }

    Volume {
        id: volume
        anchors.right: clock.left
        anchors.rightMargin: 5
    }

    Microphone {
        id: microphone
        anchors.right: volume.left
        anchors.rightMargin: 5
    }

    Brightness {
        id: brightness
        anchors.right: microphone.left
        anchors.rightMargin: 5
    }

    Internet {
        id: internet
        anchors.right: brightness.left
        anchors.rightMargin: 5

        panel.anchor.window: root
        panel.anchor.rect.x: internet.x + (internet.width - internet.panel.panelWidth) / 2
        panel.anchor.rect.y: root.height
        onConfigRequested: root.wifiConfigRequested()
    }

    Bluetooth {
        id: bluetooth
        anchors.right: internet.left
        anchors.rightMargin: 5

        panel.anchor.window: root
        panel.anchor.rect.x: bluetooth.x + (bluetooth.width - bluetooth.panel.panelWidth) / 2
        panel.anchor.rect.y: root.height
        onConfigRequested: root.bluetoothConfigRequested()
    }

    Workspaces {
        height: parent.height
        anchors.left: parent.left
    }
}
