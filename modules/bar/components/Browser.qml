import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.components

Capsule {
    id: root
    property DesktopEntry browser: DesktopEntries.byId("google-chrome")

    width: this.height
    border.color: hover.hovered ? Colors.palette.m3outline : "transparent"

    IconImage {
        implicitSize: parent.height

        source: Quickshell.iconPath(root.browser.icon)
        anchors.centerIn: parent
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.browser.execute()
    }
}
