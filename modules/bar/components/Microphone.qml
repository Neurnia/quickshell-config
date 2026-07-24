import QtQuick
import qs.components
import qs.services

Capsule {
    width: 70
    content.text: `${AudioInput.icon} ${AudioInput.percentage}%`
    border.color: hover.hovered ? Colors.palette.m3outline : "transparent"

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        onClicked: AudioInput.toggleMute()
        onWheel: event => AudioInput.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
    }
}
