import qs.services
import QtQuick

Rectangle {
    property AppText content: text
    readonly property int horizontalPadding: 20

    anchors.verticalCenter: parent.verticalCenter
    height: parent.height - 2
    width: content.width + horizontalPadding
    antialiasing: true
    radius: height / 2
    color: Colors.palette.surfaceVariant
    border.color: "transparent"
    border.width: 1

    AppText {
        id: text
        anchors.centerIn: parent
    }
}
