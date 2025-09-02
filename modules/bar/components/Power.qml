pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.services
import qs.components

Capsule {
    id: root
    property Panel panel: Panel {}
    property Actions actions: Actions {}
    property bool hover: buttonHover.hovered || root.panel.hover
    property bool isExpanded: false

    width: root.isExpanded ? root.content.width * 1.2 : root.height

    border.color: isExpanded ? Colors.palette.m3outline : "transparent"

    content {
        text: "Power & Session"
        visible: root.isExpanded ? true : false
    }

    IconImage {
        implicitSize: parent.height
        anchors.left: parent.left
        source: `file://${Paths.iconDir}/system-shutdown.svg`
        visible: root.isExpanded ? false : true
    }

    HoverHandler {
        id: buttonHover
    }

    Behavior on width {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutCubic
        }
    }

    // panel
    component Panel: PopupWindow {
        property bool hover: panelHover.hovered

        implicitWidth: 180
        implicitHeight: 100

        visible: root.isExpanded ? true : false
        color: "transparent"

        Capsule {
            anchors.centerIn: parent
            height: parent.height * 0.9
            width: parent.width
            radius: height * 0.1

            color: Colors.palette.m3surfaceContainerLowest

            HoverHandler {
                id: panelHover
            }

            Column {
                id: panelColumn
                anchors.centerIn: parent
                height: parent.height - 6
                width: parent.width - 6

                spacing: 3
                Repeater {
                    id: panelRepeater
                    model: root.actions.list
                    Capsule {
                        id: panelButton
                        required property var modelData
                        anchors.verticalCenter: undefined
                        height: panelColumn.height / panelRepeater.count
                        width: panelColumn.width
                        radius: height * 0.1

                        border.color: panelButtonHover.hovered ? Colors.palette.m3outline : "transparent"

                        content.text: modelData.desc

                        IconImage {
                            anchors.left: panelButton.left
                            implicitSize: panelButton.height * 0.8
                            source: `file://${Paths.iconDir}/system-${panelButton.modelData.icon}.svg`
                        }

                        HoverHandler {
                            id: panelButtonHover
                        }

                        MouseArea {
                            anchors.fill: panelButton
                            onClicked: root.actions.runner.exec(["sh", "-c", panelButton.modelData.cmd])
                        }
                    }
                }
            }
        }
    }

    // hide timer
    onHoverChanged: {
        if (hover) {
            hideTimer.stop();
            root.isExpanded = true;
        } else {
            hideTimer.start();
        }
    }

    Timer {
        id: hideTimer
        interval: 500
        onTriggered: root.isExpanded = false
    }

    // the actual action
    component Actions: QtObject {
        readonly property Process runner: Process {}
        readonly property var list: [shutdown, reboot, lock]

        readonly property var shutdown: ({
                icon: "shutdown",
                desc: "Shut down",
                cmd: "systemctl poweroff",
                check: true
            })
        readonly property var reboot: ({
                icon: "reboot",
                desc: "Restart",
                cmd: "systemctl reboot",
                check: true
            })
        readonly property var lock: ({
                icon: "lock-screen",
                desc: "Lock",
                cmd: "hyprlock",
                check: false
            })
    }
}
