import QtQuick
import qs.components
import qs.services

Capsule {
    id: root

    content.text: `${Audio.icon} ${Audio.percentage}%`
    border.color: hover.hovered ? Colors.palette.m3outline : "transparent"

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton

        onClicked: Audio.toggleMute()
        onWheel: event => Audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
    }
}
