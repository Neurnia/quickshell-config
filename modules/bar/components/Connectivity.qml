pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services

Item {
    id: root

    property alias panel: panelWindow
    property bool menuOpen: false
    readonly property bool hovered: statusButton.hovered || panelWindow.hovered

    signal configRequested(string page)

    anchors.verticalCenter: parent.verticalCenter
    width: 62
    height: parent.height - 2

    function bluetoothSummary(): string {
        if (!BluetoothState.available)
            return "No adapter detected";
        if (!BluetoothState.enabled)
            return "Bluetooth is off";
        if (BluetoothState.connectedCount === 0)
            return "No connected devices";
        return BluetoothState.connectedDevices
            .map(device => BluetoothState.deviceName(device))
            .join(", ");
    }

    function bluetoothDetails(): string {
        if (!BluetoothState.available)
            return "Unavailable";
        if (!BluetoothState.enabled)
            return "Wireless devices unavailable";
        return BluetoothState.connectedCount === 1
            ? "1 connected device"
            : `${BluetoothState.connectedCount} connected devices`;
    }

    function networkDetails(): string {
        if (!Network.connected)
            return Network.wifiEnabled ? "No connection" : "Wi-Fi is off";

        let details = Network.connectionType === "wifi"
            ? `${Network.signalStrength}% signal`
            : "Wired connection";
        if (Network.ipAddress)
            details += `  ·  ${Network.ipAddress}`;
        if (Network.vpnConnected)
            details += "  \uf023";
        return details;
    }

    function openConfig(page: string): void {
        menuOpen = false;
        configRequested(page);
    }

    ActionCapsule {
        id: statusButton

        anchors.fill: parent
        anchors.verticalCenter: undefined
        content.text: ""
        border.color: root.menuOpen || root.hovered ? Colors.palette.outline : "transparent"
        onHoveredChanged: {
            if (hovered)
                root.menuOpen = true;
        }
        onClicked: root.menuOpen = !root.menuOpen

        Row {
            anchors.centerIn: parent
            height: parent.height
            spacing: 5

            Item {
                width: 18
                height: parent.height

                AppText {
                    anchors.centerIn: parent
                    text: Network.icon
                    font.pixelSize: 12
                }
            }

            Item {
                width: 27
                height: parent.height

                Row {
                    anchors.centerIn: parent
                    spacing: 3

                    AppText {
                        text: BluetoothState.icon
                        font.pixelSize: 11
                        color: BluetoothState.enabled
                            ? Colors.palette.surfaceText
                            : Colors.palette.surfaceVariantText
                    }

                    AppText {
                        width: 8
                        text: BluetoothState.available
                            ? `${BluetoothState.connectedCount}`
                            : "–"
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                        color: BluetoothState.enabled
                            ? Colors.palette.surfaceText
                            : Colors.palette.surfaceVariantText
                    }
                }
            }
        }
    }

    Timer {
        interval: 400
        running: root.menuOpen && !root.hovered
        onTriggered: root.menuOpen = false
    }

    PopupWindow {
        id: panelWindow

        readonly property bool hovered: panelHover.hovered
        readonly property int panelWidth: 270
        readonly property int panelHeight: 108

        implicitWidth: panelWidth
        implicitHeight: panelHeight
        visible: root.menuOpen
        color: "transparent"

        Capsule {
            anchors.fill: parent
            radius: height * 0.045
            color: Colors.palette.surfaceContainerLowest

            HoverHandler {
                id: panelHover
            }

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                StatusRow {
                    width: parent.width
                    icon: Network.icon
                    title: Network.label
                    details: root.networkDetails()
                    switchIcon: "\uf1eb"
                    checked: Network.wifiEnabled
                    switchEnabled: Network.available && !Network.busy
                    onToggleRequested: Network.toggleWifi()
                    onConfigRequested: root.openConfig("wifi")
                }

                StatusRow {
                    width: parent.width
                    icon: BluetoothState.icon
                    title: root.bluetoothSummary()
                    details: root.bluetoothDetails()
                    switchIcon: "\uf293"
                    checked: BluetoothState.enabled
                    switchEnabled: BluetoothState.available
                    onToggleRequested: BluetoothState.toggleEnabled()
                    onConfigRequested: root.openConfig("bluetooth")
                }
            }
        }
    }

    component StatusRow: Rectangle {
        id: row

        property string icon: ""
        property string title: ""
        property string details: ""
        property string switchIcon: ""
        property bool checked: false
        property bool switchEnabled: true

        signal toggleRequested
        signal configRequested

        height: 46
        radius: 8
        color: rowHover.hovered
            ? Colors.palette.surfaceContainerHigh
            : Colors.palette.surfaceVariant

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        HoverHandler {
            id: rowHover
        }

        AppText {
            id: rowIcon
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            text: row.icon
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }

        Column {
            anchors.left: rowIcon.right
            anchors.leftMargin: 8
            anchors.right: switchGroup.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            AppText {
                width: parent.width
                text: row.title
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            AppText {
                width: parent.width
                text: row.details
                color: Colors.palette.surfaceVariantText
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        Row {
            id: switchGroup
            anchors.right: configButton.left
            anchors.rightMargin: 7
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            AppText {
                anchors.verticalCenter: parent.verticalCenter
                text: row.switchIcon
                font.pixelSize: 9
                color: row.checked
                    ? Colors.palette.primary
                    : Colors.palette.surfaceVariantText
            }

            ToggleSwitch {
                anchors.verticalCenter: parent.verticalCenter
                checked: row.checked
                actionEnabled: row.switchEnabled
                onToggled: row.toggleRequested()
            }
        }

        ActionCapsule {
            id: configButton
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            width: 25
            height: 25
            color: "transparent"
            content.text: "\uf054"
            content.font.pixelSize: 8
            onClicked: row.configRequested()
        }
    }
}
