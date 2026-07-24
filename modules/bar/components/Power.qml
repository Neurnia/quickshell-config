pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

Capsule {
    id: root

    property Panel panel: Panel {}
    property Actions actions: Actions {}
    property bool menuOpen: false
    property var pendingAction: null

    width: height
    content.text: "\uf011"
    border.color: menuOpen || buttonHover.hovered ? Colors.palette.m3outline : "transparent"

    function closeMenu(): void {
        pendingAction = null;
        menuOpen = false;
    }

    function confirmPendingAction(): void {
        if (!pendingAction)
            return;

        actions.runner.exec(pendingAction.command);
        closeMenu();
    }

    HoverHandler {
        id: buttonHover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (root.menuOpen)
                root.closeMenu();
            else
                root.menuOpen = true;
        }
    }

    component Panel: PopupWindow {
        id: panel

        readonly property int panelWidth: 183
        readonly property int panelHeight: 94
        readonly property int buttonWidth: 180
        readonly property int buttonHeight: 25
        readonly property int buttonSpacing: 3

        implicitWidth: panelWidth
        implicitHeight: panelHeight
        visible: root.menuOpen
        color: "transparent"

        Capsule {
            anchors.fill: parent
            radius: height * 0.1
            color: Colors.palette.m3surfaceContainerLowest

            Column {
                anchors.centerIn: parent
                spacing: panel.buttonSpacing
                visible: root.pendingAction === null

                Repeater {
                    model: root.actions.list

                    Capsule {
                        id: actionButton

                        required property var modelData

                        anchors.verticalCenter: undefined
                        width: panel.buttonWidth
                        height: panel.buttonHeight
                        radius: height * 0.1
                        content.text: modelData.description
                        border.color: actionHover.hovered ? Colors.palette.m3outline : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            text: actionButton.modelData.icon
                            color: Colors.palette.m3onSurface
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        HoverHandler {
                            id: actionHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pendingAction = actionButton.modelData
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: root.pendingAction !== null

                Text {
                    width: panel.buttonWidth
                    text: root.pendingAction ? `${root.pendingAction.icon}  Confirm ${root.pendingAction.description.toLowerCase()}?` : ""
                    color: Colors.palette.m3onSurface
                    font.family: "JetBrainsMono Nerd Font"
                    horizontalAlignment: Text.AlignHCenter
                }

                Row {
                    spacing: 6

                    Capsule {
                        id: backButton

                        anchors.verticalCenter: undefined
                        width: 87
                        height: panel.buttonHeight
                        radius: height * 0.1
                        content.text: "\uf060  Back"
                        border.color: backHover.hovered ? Colors.palette.m3outline : "transparent"

                        HoverHandler {
                            id: backHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pendingAction = null
                        }
                    }

                    Capsule {
                        id: confirmButton

                        anchors.verticalCenter: undefined
                        width: 87
                        height: panel.buttonHeight
                        radius: height * 0.1
                        color: Colors.palette.m3secondary
                        content.text: "\uf00c  Confirm"
                        content.color: Colors.palette.m3onSecondary
                        border.color: confirmHover.hovered ? Colors.palette.m3outline : "transparent"

                        HoverHandler {
                            id: confirmHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.confirmPendingAction()
                        }
                    }
                }
            }
        }
    }

    component Actions: QtObject {
        readonly property Process runner: Process {}
        readonly property var list: [shutdown, reboot, lock]

        readonly property var shutdown: ({
            icon: "\uf011",
            description: "Shut down",
            command: ["systemctl", "poweroff"]
        })
        readonly property var reboot: ({
            icon: "\uf2f9",
            description: "Restart",
            command: ["systemctl", "reboot"]
        })
        readonly property var lock: ({
            icon: "\uf023",
            description: "Lock",
            command: ["hyprlock"]
        })
    }
}
