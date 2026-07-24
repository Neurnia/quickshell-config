import QtQuick
import qs.components
import qs.services

ActionCapsule {
    width: 70
    content.text: `${AudioInput.icon} ${AudioInput.percentage}%`
    color: AudioInput.inUse ? Colors.palette.errorContainer : Colors.palette.surfaceVariant
    content.color: AudioInput.inUse ? Colors.palette.errorContainerText : Colors.palette.surfaceText
    border.color: AudioInput.inUse || hovered ? Colors.palette.outline : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    onClicked: AudioInput.toggleMute()
    onWheel: event => AudioInput.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
}
