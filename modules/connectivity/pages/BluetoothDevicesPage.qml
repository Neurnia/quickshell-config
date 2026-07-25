import QtQuick
import qs.components
import qs.services

Item {
    id: root

    property string query: ""

    signal deviceChosen(var device)

    function filteredDevices(): var {
        if (!BluetoothState.enabled)
            return [];
        const devices = [
            ...BluetoothState.connectedDevices,
            ...BluetoothState.pairedDevices,
            ...BluetoothState.availableDevices
        ];
        const needle = query.trim().toLowerCase();
        if (!needle)
            return devices;
        return devices.filter(device => {
            const name = BluetoothState.deviceName(device).toLowerCase();
            const address = (device.address || "").toLowerCase();
            return name.indexOf(needle) !== -1 || address.indexOf(needle) !== -1;
        });
    }

    ListView {
        id: deviceList
        anchors.fill: parent
        spacing: 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.filteredDevices()

        delegate: ActionCapsule {
            id: deviceRow

            required property var modelData
            readonly property var device: modelData

            actionEnabled: !BluetoothState.deviceBusy(device)
            anchors.verticalCenter: undefined
            width: deviceList.width
            height: 50
            content.text: ""
            color: device?.connected
                ? Colors.palette.secondary
                : Colors.palette.surfaceVariant
            onClicked: root.deviceChosen(device)

            AppText {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: BluetoothState.deviceIcon(deviceRow.device)
                color: deviceRow.device?.connected
                    ? Colors.palette.secondaryText
                    : Colors.palette.surfaceText
                font.pixelSize: 15
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 42
                anchors.right: stateIcon.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                AppText {
                    width: parent.width
                    text: BluetoothState.deviceName(deviceRow.device)
                    color: deviceRow.device?.connected
                        ? Colors.palette.secondaryText
                        : Colors.palette.surfaceText
                    font.pixelSize: 11
                    font.weight: deviceRow.device?.connected ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                AppText {
                    width: parent.width
                    text: {
                        const status = BluetoothState.deviceStatus(deviceRow.device);
                        if (deviceRow.device?.batteryAvailable)
                            return `${status}  ·  \uf240 ${Math.round(deviceRow.device.battery * 100)}%`;
                        return status;
                    }
                    color: deviceRow.device?.connected
                        ? Colors.palette.secondaryText
                        : Colors.palette.surfaceVariantText
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            AppText {
                id: stateIcon
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: BluetoothState.deviceBusy(deviceRow.device)
                    ? "\uf110"
                    : deviceRow.device?.connected
                        ? "\uf127"
                        : "\uf0c1"
                color: deviceRow.device?.connected
                    ? Colors.palette.secondaryText
                    : Colors.palette.surfaceVariantText
                font.pixelSize: 10
            }
        }

        AppText {
            anchors.centerIn: parent
            width: parent.width - 40
            visible: deviceList.count === 0
            text: {
                if (!BluetoothState.available)
                    return "󰂲  No Bluetooth adapter";
                if (!BluetoothState.enabled)
                    return "\uf293  Bluetooth is off";
                if (root.query)
                    return "\uf002  No matching devices";
                if (BluetoothState.discovering)
                    return "\uf110  Looking for nearby devices…";
                return "\uf293  No devices found";
            }
            color: Colors.palette.surfaceVariantText
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
