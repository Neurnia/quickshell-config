import QtQuick
import qs.components
import qs.services

ActionCapsule {
    width: 70
    content.text: `${Audio.icon} ${Audio.percentage}%`
    onClicked: Audio.toggleMute()
    onWheel: event => Audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
}
