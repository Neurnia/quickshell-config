import QtQuick
import qs.components
import qs.services

Capsule {
    id: root

    property alias panel: notificationPanel

    width: controls.implicitWidth + 8
    clip: true
    content.text: ""

    Behavior on width {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    component ControlSegment: Item {
        id: segment

        property string label: ""
        property color foreground: Colors.palette.surfaceText
        property color activeBackground: Colors.palette.surfaceContainerHigh
        property bool emphasized: false
        property bool actionEnabled: true
        property int acceptedButtons: Qt.LeftButton

        signal clicked(var event)
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
            onClicked: event => segment.clicked(event)
            onWheel: event => segment.wheel(event)
        }
    }

    Row {
        id: controls

        anchors {
            right: parent.right
            rightMargin: 4
            verticalCenter: parent.verticalCenter
        }
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
            implicitWidth: 20
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
            implicitWidth: 20
            visible: ScreenSharing.active
            label: ScreenSharing.icon
            emphasized: true
            foreground: Colors.palette.errorContainerText
            activeBackground: Colors.palette.errorContainer
            actionEnabled: false
            acceptedButtons: Qt.NoButton
        }

        ControlSegment {
            height: parent.height
            visible: Battery.available
            label: `${Battery.icon} ${Battery.percentage}`
            emphasized: Battery.low || Battery.powerConnected
            foreground: Battery.low ? Colors.palette.errorContainerText : Battery.powerConnected ? Colors.palette.primaryContainerText : Colors.palette.surfaceText
            activeBackground: Battery.low ? Colors.palette.errorContainer : Battery.powerConnected ? Colors.palette.primaryContainer : Colors.palette.surfaceContainerHigh
            actionEnabled: false
            acceptedButtons: Qt.NoButton
        }

        ControlSegment {
            id: notificationSegment

            height: parent.height
            implicitWidth: 20
            label: MakoState.doNotDisturb ? "\uf1f6" : "\uf0f3"
            emphasized: MakoState.doNotDisturb || notificationPanel.visible
            foreground: MakoState.doNotDisturb
                ? Colors.palette.primaryContainerText
                : Colors.palette.surfaceText
            activeBackground: MakoState.doNotDisturb
                ? Colors.palette.primaryContainer
                : Colors.palette.surfaceContainerHigh
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onClicked: event => {
                if (event.button === Qt.LeftButton) {
                    MakoState.toggleDoNotDisturb();
                } else if (event.button === Qt.MiddleButton) {
                    MakoState.dismissAll();
                } else if (event.button === Qt.RightButton) {
                    notificationPanel.visible = !notificationPanel.visible;
                }
            }
        }
    }

    NotificationHistory {
        id: notificationPanel
    }
}
