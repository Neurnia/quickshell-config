import Quickshell
import qs.services
import "./components"

PanelWindow {

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
    }

    Clock {
        id: clock
        anchors.right: power.left
        anchors.rightMargin: 5
    }

    Browser {
        id: browser
        anchors.right: clock.left
        anchors.rightMargin: 5
    }

    Workspaces {
        height: parent.height
        anchors.left: parent.left
    }
}
