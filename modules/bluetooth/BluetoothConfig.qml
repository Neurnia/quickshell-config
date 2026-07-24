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

    WlrLayershell.namespace: "quickshell:bluetooth-config"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function open(): void {
        shown = true;
        focusScope.forceActiveFocus();
        BluetoothState.startDiscovery();
    }

    function close(): void {
        shown = false;
        BluetoothState.stopDiscovery();
    }

    IpcHandler {
        target: "bluetoothConfig"

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
                            text: "\uf293  Bluetooth configuration"
                            color: Colors.palette.m3onSurface
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: {
                                if (!BluetoothState.available)
                                    return "󰂲  No Bluetooth adapter";
                                if (!BluetoothState.enabled)
                                    return "󰂲  Bluetooth is off";
                                if (BluetoothState.connectedCount === 0)
                                    return "\uf293  No connected devices";
                                return BluetoothState.connectedCount === 1 ? "\uf00c  1 connected device" : `\uf00c  ${BluetoothState.connectedCount} connected devices`;
                            }
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
                            content.text: BluetoothState.discovering ? "\uf110  Scan" : "\uf2f1  Scan"
                            color: BluetoothState.discovering ? Colors.palette.m3secondary : Colors.palette.m3surfaceVariant
                            content.color: BluetoothState.discovering ? Colors.palette.m3onSecondary : Colors.palette.m3onSurface
                            border.color: scanHover.hovered && BluetoothState.enabled ? Colors.palette.m3outline : "transparent"

                            HoverHandler {
                                id: scanHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: BluetoothState.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (BluetoothState.discovering)
                                        BluetoothState.stopDiscovery();
                                    else
                                        BluetoothState.startDiscovery();
                                }
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

                ListView {
                    id: deviceList

                    width: parent.width
                    height: 405
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: BluetoothState.enabled ? BluetoothState.displayItems : []

                    delegate: Item {
                        id: itemDelegate

                        required property var modelData

                        width: deviceList.width
                        height: modelData.kind === "header" ? 24 : 52

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: itemDelegate.modelData.kind === "header"
                            text: itemDelegate.modelData.kind === "header" ? `${itemDelegate.modelData.icon}  ${itemDelegate.modelData.title}` : ""
                            color: Colors.palette.m3onSurface
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: itemDelegate.modelData.kind === "header"
                            text: itemDelegate.modelData.kind === "header" ? itemDelegate.modelData.count : ""
                            color: Colors.palette.m3onSurfaceVariant
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }

                        Capsule {
                            id: deviceRow

                            readonly property var device: itemDelegate.modelData.kind === "device" ? itemDelegate.modelData.device : null

                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 50
                            radius: height * 0.16
                            visible: itemDelegate.modelData.kind === "device"
                            content.text: ""
                            color: device?.connected ? Colors.palette.m3secondary : Colors.palette.m3surfaceVariant
                            border.color: deviceHover.hovered && !BluetoothState.deviceBusy(device) ? Colors.palette.m3outline : "transparent"

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: BluetoothState.deviceIcon(deviceRow.device)
                                color: deviceRow.device?.connected ? Colors.palette.m3onSecondary : Colors.palette.m3onSurface
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 42
                                anchors.right: deviceAction.left
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: BluetoothState.deviceName(deviceRow.device)
                                    color: deviceRow.device?.connected ? Colors.palette.m3onSecondary : Colors.palette.m3onSurface
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.weight: deviceRow.device?.connected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: {
                                        const status = BluetoothState.deviceStatus(deviceRow.device);
                                        if (deviceRow.device?.batteryAvailable)
                                            return `${status}  ·  \uf240 ${Math.round(deviceRow.device.battery * 100)}%`;
                                        return status;
                                    }
                                    color: deviceRow.device?.connected ? Colors.palette.m3onSecondary : Colors.palette.m3onSurfaceVariant
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                id: deviceAction

                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    if (BluetoothState.deviceBusy(deviceRow.device))
                                        return "\uf110";
                                    if (deviceRow.device?.connected)
                                        return "\uf127";
                                    return "\uf0c1";
                                }
                                color: deviceRow.device?.connected ? Colors.palette.m3onSecondary : Colors.palette.m3onSurfaceVariant
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }

                            HoverHandler {
                                id: deviceHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: !BluetoothState.deviceBusy(deviceRow.device) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: BluetoothState.toggleDevice(deviceRow.device)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        visible: deviceList.count === 0
                        text: {
                            if (!BluetoothState.available)
                                return "󰂲  No Bluetooth adapter detected";
                            if (!BluetoothState.enabled)
                                return "\uf293  Turn on Bluetooth from the status panel";
                            if (BluetoothState.discovering)
                                return "\uf110  Looking for nearby devices…";
                            return "\uf293  No Bluetooth devices found";
                        }
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
