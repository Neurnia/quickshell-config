import QtQuick
import qs.components
import qs.services

Capsule {
    id: root

    width: 130
    border.color: hover.hovered ? Colors.palette.m3outline : "transparent"

    content {
        width: root.width - 20
        text: `${Network.icon} ${Network.label}${Network.vpnConnected ? " \uf023" : ""}`
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }

    HoverHandler {
        id: hover
    }
}
