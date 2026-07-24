import qs.services
import QtQuick

Rectangle {
    property AppText content: text

    anchors.verticalCenter: parent.verticalCenter
    height: parent.height - 2
    width: content.width + 20
    antialiasing: true
    radius: height / 2
    color: Colors.palette.m3surfaceVariant
    border.color: "transparent"
    border.width: 1

    AppText {
        id: text
        anchors.centerIn: parent
    }
}
