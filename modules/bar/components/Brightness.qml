import QtQuick
import qs.components
import qs.services

ActionCapsule {
    width: 70
    content.text: `${Brightness.icon} ${Brightness.percentage}%`
    acceptedButtons: Qt.NoButton
    onWheel: event => Brightness.adjust(event.angleDelta.y > 0 ? 1 : -1)
}
