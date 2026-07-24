import QtQuick
import qs.components
import qs.services

ActionCapsule {
    width: 70
    content.text: `${AudioInput.icon} ${AudioInput.percentage}%`
    color: AudioInput.inUse ? Colors.palette.m3errorContainer : Colors.palette.m3surfaceVariant
    content.color: AudioInput.inUse ? Colors.palette.m3onErrorContainer : Colors.palette.m3onSurface
    border.color: AudioInput.inUse || hovered ? Colors.palette.m3outline : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    onClicked: AudioInput.toggleMute()
    onWheel: event => AudioInput.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
}
