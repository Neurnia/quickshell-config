pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.services

PanelWindow {
    id: root

    property bool shown: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    visible: shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell:wifi-config"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function open(): void {
        shown = true;
        focusScope.forceActiveFocus();
        if (Network.wifiEnabled)
            Network.rescan();
    }

    function close(): void {
        shown = false;
    }

    function signalIcon(strength: int): string {
        if (strength >= 75)
            return "󰤨";
        if (strength >= 50)
            return "󰤥";
        if (strength >= 25)
            return "󰤢";
        return "󰤟";
    }

    IpcHandler {
        target: "wifiConfig"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            if (root.shown)
                root.close();
            else
                root.open();
        }
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: root.shown

        Keys.onEscapePressed: event => {
            root.close();
            event.accepted = true;
        }

        Rectangle {
            anchors.fill: parent
            color: "#B8000000"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: root.close()
            }
        }

        Capsule {
            id: card

            anchors.centerIn: parent
            width: 440
            height: 500
            radius: 16
            color: Colors.palette.m3surfaceContainerLowest
            border.color: Colors.palette.m3outlineVariant
            content.text: ""

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Item {
                    width: parent.width
                    height: 50

                    Column {
                        anchors.left: parent.left
                        anchors.right: headerActions.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            width: parent.width
                            text: "\uf1eb  Wi-Fi configuration"
                            color: Colors.palette.m3onSurface
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: Network.wifiEnabled ? `${Network.icon}  ${Network.label}` : "󰤭  Wi-Fi is off"
                            color: Colors.palette.m3onSurfaceVariant
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    Row {
                        id: headerActions

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Capsule {
                            id: scanButton

                            anchors.verticalCenter: undefined
                            width: 82
                            height: 30
                            radius: height * 0.2
                            content.text: Network.busy ? "\uf110  Wait" : "\uf2f1  Scan"
                            color: Colors.palette.m3surfaceVariant
                            border.color: scanHover.hovered && Network.wifiEnabled && !Network.busy ? Colors.palette.m3outline : "transparent"

                            HoverHandler {
                                id: scanHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: Network.wifiEnabled && !Network.busy ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: Network.rescan()
                            }
                        }

                        Capsule {
                            id: closeButton

                            anchors.verticalCenter: undefined
                            width: 30
                            height: 30
                            radius: height * 0.2
                            content.text: "\uf00d"
                            color: Colors.palette.m3surfaceVariant
                            border.color: closeHover.hovered ? Colors.palette.m3outline : "transparent"

                            HoverHandler {
                                id: closeHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.close()
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Colors.palette.m3outlineVariant
                    opacity: 0.35
                }

                Item {
                    width: parent.width
                    height: 24

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Network.wifiEnabled ? "Available networks" : "Wireless networking disabled"
                        color: Colors.palette.m3onSurface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Network.wifiEnabled
                        text: `${Network.networks.length} found`
                        color: Colors.palette.m3onSurfaceVariant
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                    }
                }

                ListView {
                    id: networkList

                    width: parent.width
                    height: 381
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: Network.wifiEnabled ? Network.networks : []

                    delegate: Capsule {
                        id: networkRow

                        required property var modelData

                        anchors.verticalCenter: undefined
                        width: networkList.width
                        height: 50
                        radius: height * 0.16
                        content.text: ""
                        color: modelData.active ? Colors.palette.m3secondary : Colors.palette.m3surfaceVariant
                        border.color: networkHover.hovered && Network.canConnect(modelData) && !Network.busy ? Colors.palette.m3outline : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.signalIcon(networkRow.modelData.signal)
                            color: networkRow.modelData.active ? Colors.palette.m3onSecondary : Colors.palette.m3onSurface
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 42
                            anchors.right: signalLabel.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: networkRow.modelData.name
                                color: networkRow.modelData.active ? Colors.palette.m3onSecondary : Colors.palette.m3onSurface
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.weight: networkRow.modelData.active ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: {
                                    if (networkRow.modelData.active)
                                        return "\uf00c  Connected";
                                    if (networkRow.modelData.saved)
                                        return "\uf084  Saved";
                                    if (networkRow.modelData.secured)
                                        return "\uf023  Secured";
                                    return "\uf09c  Open network";
                                }
                                color: networkRow.modelData.active ? Colors.palette.m3onSecondary : Colors.palette.m3onSurfaceVariant
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                            }
                        }

                        Text {
                            id: signalLabel

                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: `${networkRow.modelData.signal}%`
                            color: networkRow.modelData.active ? Colors.palette.m3onSecondary : Colors.palette.m3onSurfaceVariant
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }

                        HoverHandler {
                            id: networkHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Network.canConnect(networkRow.modelData) && !Network.busy ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: Network.connectNetwork(networkRow.modelData)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        visible: networkList.count === 0
                        text: Network.wifiEnabled ? (Network.busy ? "\uf110  Scanning for networks…" : "󰤭  No networks found") : "\uf1eb  Turn on Wi-Fi from the status panel"
                        color: Colors.palette.m3onSurfaceVariant
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
