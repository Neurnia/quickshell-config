import qs.services
import QtQuick

Rectangle {
    property Text content: text

    anchors.verticalCenter: parent.verticalCenter
    height: parent.height - 2
    width: content.width + 20
    antialiasing: true
    radius: height / 2
    color: Colors.palette.m3surfaceVariant
    border.color: "transparent"
    border.width: 1

    Text {
        id: text
        anchors.centerIn: parent
        color: Colors.palette.m3onSurface
        font.family: "JetBrainsMono Nerd Font"
    }
}
