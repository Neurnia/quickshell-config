import QtQuick
import qs.components
import qs.services

Capsule {
    width: 70
    content.text: `${Brightness.icon} ${Brightness.percentage}%`
    border.color: hover.hovered ? Colors.palette.m3outline : "transparent"

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => Brightness.adjust(event.angleDelta.y > 0 ? 1 : -1)
    }
}
