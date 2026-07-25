import QtQuick
import qs.components
import qs.services

Capsule {
    id: root

    width: controls.implicitWidth + 8
    content.text: ""

    component ControlSegment: Item {
        id: segment

        property string label: ""
        property color foreground: Colors.palette.surfaceText
        property color activeBackground: Colors.palette.surfaceContainerHigh
        property bool emphasized: false
        property bool actionEnabled: true
        property int acceptedButtons: Qt.LeftButton

        signal clicked
        signal wheel(var event)

        implicitWidth: segmentText.implicitWidth + 8
        implicitHeight: root.height - 4

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: segment.emphasized || hoverHandler.hovered ? segment.activeBackground : "transparent"
            border.color: segment.emphasized ? Colors.palette.outline : "transparent"
            border.width: 1

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }

        AppText {
            id: segmentText

            anchors.centerIn: parent
            text: segment.label
            color: segment.foreground
        }

        HoverHandler {
            id: hoverHandler

            enabled: segment.actionEnabled
        }

        MouseArea {
            anchors.fill: parent
            enabled: segment.actionEnabled
            acceptedButtons: segment.acceptedButtons
            cursorShape: segment.acceptedButtons === Qt.NoButton ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: segment.clicked()
            onWheel: event => segment.wheel(event)
        }
    }

    Row {
        id: controls

        anchors.centerIn: parent
        height: parent.height - 4
        spacing: 1

        ControlSegment {
            height: parent.height
            label: `${Brightness.icon} ${Brightness.percentage}`
            acceptedButtons: Qt.NoButton
            onWheel: event => Brightness.adjust(event.angleDelta.y > 0 ? 1 : -1)
        }

        ControlSegment {
            height: parent.height
            label: `${Audio.icon} ${Audio.percentage}`
            onClicked: Audio.toggleMute()
            onWheel: event => Audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
        }

        ControlSegment {
            height: parent.height
            visible: AudioInput.inUse || AudioInput.muted
            label: AudioInput.icon
            emphasized: AudioInput.inUse
            foreground: AudioInput.inUse ? Colors.palette.errorContainerText : Colors.palette.surfaceText
            activeBackground: AudioInput.inUse ? Colors.palette.errorContainer : Colors.palette.surfaceContainerHigh
            onClicked: AudioInput.toggleMute()
            onWheel: event => AudioInput.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
        }

        ControlSegment {
            height: parent.height
            visible: Battery.available
            label: `${Battery.icon} ${Battery.percentage}`
            foreground: Battery.low ? Colors.palette.error : Battery.powerConnected ? Colors.palette.primary : Colors.palette.surfaceText
            actionEnabled: false
            acceptedButtons: Qt.NoButton
        }
    }
}
