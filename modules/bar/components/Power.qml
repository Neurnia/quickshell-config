import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.components

Capsule {
    width: this.height
    border.color: hover.hovered ? Colors.palette.m3outline : "transparent"

    IconImage {
        implicitSize: parent.height

        source: Quickshell.iconPath("system-shutdown-panel")
        anchors.centerIn: parent
    }

    HoverHandler {
        id: hover
    }
    MouseArea {
        anchors.fill: parent
    }
}
