import Quickshell
import qs.services
import "./components"

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 25
    color: Colors.palette.m3surfaceContainerLow

    Title {
        anchors.centerIn: parent
    }

    Power {
        id: power
        anchors.right: parent.right

        panel.anchor.window: root
        panel.anchor.rect.x: root.width - width / 2
        panel.anchor.rect.y: root.height
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

    Brightness {
        id: brightness
        anchors.right: volume.left
        anchors.rightMargin: 5
    }

    Internet {
        id: internet
        anchors.right: brightness.left
        anchors.rightMargin: 5

        panel.anchor.window: root
        panel.anchor.rect.x: internet.x + internet.width / 2
        panel.anchor.rect.y: root.height
    }

    Workspaces {
        height: parent.height
        anchors.left: parent.left
    }
}
