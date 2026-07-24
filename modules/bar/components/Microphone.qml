import QtQuick
import qs.components
import qs.services

Capsule {
    id: root

    width: 70
    content.text: `${AudioInput.icon} ${AudioInput.percentage}%`
    color: AudioInput.inUse ? Colors.palette.m3errorContainer : Colors.palette.m3surfaceVariant
    content.color: AudioInput.inUse ? Colors.palette.m3onErrorContainer : Colors.palette.m3onSurface
    border.color: AudioInput.inUse || hover.hovered ? Colors.palette.m3outline : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

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
