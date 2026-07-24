import QtQuick
import qs.services

Capsule {
    id: root

    property bool actionEnabled: true
    property int acceptedButtons: Qt.LeftButton
    readonly property bool hovered: hoverHandler.hovered

    signal clicked
    signal wheel(var event)

    border.color: hovered && actionEnabled ? Colors.palette.m3outline : "transparent"

    HoverHandler {
        id: hoverHandler
        enabled: root.actionEnabled
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.actionEnabled
        acceptedButtons: root.acceptedButtons
        cursorShape: root.acceptedButtons === Qt.NoButton ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: event => root.wheel(event)
    }
}
