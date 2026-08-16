import Quickshell
import qs.services
import "./components"

PanelWindow {
    id: root

    signal connectivityConfigRequested(string page)
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

    SystemControls {
        id: systemControls
        anchors.right: clock.left
        anchors.rightMargin: 5

        panel.anchor.window: root
        panel.anchor.rect.x: systemControls.x + systemControls.width - systemControls.panel.panelWidth
        panel.anchor.rect.y: root.height
    }

    Connectivity {
        id: connectivity
        anchors.right: systemControls.left
        anchors.rightMargin: 5

        panel.anchor.window: root
        panel.anchor.rect.x: connectivity.x + (connectivity.width - connectivity.panel.panelWidth) / 2
        panel.anchor.rect.y: root.height
        onConfigRequested: page => root.connectivityConfigRequested(page)
    }

    Tray {
        id: tray
        anchors.right: connectivity.left
        anchors.rightMargin: 5

        panel.anchor.window: root
        panel.anchor.rect.x: tray.x + (tray.width - tray.panel.panelWidth) / 2
        panel.anchor.rect.y: root.height
    }

    Workspaces {
        height: parent.height
        anchors.left: parent.left
    }
}
