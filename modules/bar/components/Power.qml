import QtQuick
import qs.components
import qs.services

Capsule {
    id: root

    signal menuRequested

    width: height
    content.text: "\uf011"
    border.color: buttonHover.hovered ? Colors.palette.m3outline : "transparent"

    HoverHandler {
        id: buttonHover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.menuRequested()
    }
}
