import QtQuick
import qs.services

Item {
    id: root

    property bool checked: false
    property bool actionEnabled: true

    signal toggled

    implicitWidth: 30
    implicitHeight: 16
    opacity: actionEnabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Colors.palette.primary : Colors.palette.surfaceContainerHighest

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    Rectangle {
        width: 12
        height: 12
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        radius: width / 2
        color: root.checked ? Colors.palette.primaryText : Colors.palette.surfaceVariantText

        Behavior on x {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.actionEnabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
