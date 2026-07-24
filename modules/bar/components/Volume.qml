pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services

Capsule {
    id: root

    property Panel panel: Panel {}
    property bool hover: capsuleHover.hovered || panel.hover
    property bool isExpanded: false

    content.text: `${Audio.icon} ${Audio.percentage}%`
    border.color: isExpanded ? Colors.palette.m3outline : "transparent"

    HoverHandler {
        id: capsuleHover
    }

    onHoverChanged: {
        if (hover) {
            hideTimer.stop();
            isExpanded = true;
        } else {
            hideTimer.start();
        }
    }

    Timer {
        id: hideTimer
        interval: 400
        onTriggered: root.isExpanded = false
    }

    component Panel: PopupWindow {
        id: panel

        property bool hover: panelHover.hovered
        readonly property int buttonWidth: 180
        readonly property int buttonHeight: 25
        readonly property int buttonSpacing: 3

        implicitWidth: buttonWidth + buttonSpacing
        implicitHeight: (buttonHeight + buttonSpacing) * 2 + 10
        visible: root.isExpanded
        color: "transparent"

        Capsule {
            anchors.fill: parent
            radius: height * 0.1
            color: Colors.palette.m3surfaceContainerLowest

            HoverHandler {
                id: panelHover
            }

            Column {
                anchors.centerIn: parent
                spacing: panel.buttonSpacing

                Capsule {
                    id: muteButton

                    anchors.verticalCenter: undefined
                    width: panel.buttonWidth
                    height: panel.buttonHeight
                    radius: height * 0.1
                    content.text: Audio.muted ? "Unmute" : "Mute"
                    border.color: muteHover.hovered ? Colors.palette.m3outline : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        text: Audio.icon
                        color: Colors.palette.m3onSurface
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    HoverHandler {
                        id: muteHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor

                        onClicked: Audio.toggleMute()
                        onWheel: event => Audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
                    }
                }

                Capsule {
                    id: volumeButton

                    anchors.verticalCenter: undefined
                    width: panel.buttonWidth
                    height: panel.buttonHeight
                    radius: height * 0.1
                    border.color: volumeHover.hovered ? Colors.palette.m3outline : "transparent"

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        onWheel: event => Audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            text: "\uf027"
                            color: Colors.palette.m3onSurface
                            font.family: "JetBrainsMono Nerd Font"
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 95
                            height: panel.buttonHeight

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 5
                                radius: height / 2
                                color: Colors.palette.m3surfaceContainerHigh

                                Rectangle {
                                    width: parent.width * Math.min(Audio.volume, 1)
                                    height: parent.height
                                    radius: parent.radius
                                    color: Colors.palette.m3primary
                                }

                                Rectangle {
                                    x: Math.min(Audio.volume, 1) * (parent.width - width)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 10
                                    height: 10
                                    radius: width / 2
                                    color: Colors.palette.m3primary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: Qt.PointingHandCursor

                                function setFromMouse(mouseX: real): void {
                                    Audio.setVolume(mouseX / width);
                                }

                                onPressed: mouse => setFromMouse(mouse.x)
                                onPositionChanged: mouse => {
                                    if (pressed)
                                        setFromMouse(mouse.x);
                                }
                                onWheel: event => Audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38
                            text: `${Audio.percentage}%`
                            color: Colors.palette.m3onSurface
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    HoverHandler {
                        id: volumeHover
                    }
                }
            }
        }
    }
}
