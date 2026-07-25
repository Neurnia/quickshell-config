pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    readonly property var devices: adapter?.devices?.values ?? []
    readonly property var connectedDevices: sortDevices(devices.filter(device => device && device.connected))
    readonly property var pairedDevices: sortDevices(devices.filter(device => device && !device.connected && isKnown(device)))
    readonly property var availableDevices: sortDevices(devices.filter(device => device && !device.connected && !isKnown(device) && hasUsefulName(device)))
    readonly property int connectedCount: connectedDevices.length
    readonly property string icon: enabled ? "\uf293" : "󰂲"

    function deviceName(device): string {
        if (!device)
            return "Unknown device";
        return device.name || device.deviceName || device.address || "Unknown device";
    }

    function deviceIcon(device): string {
        if (!device)
            return "\uf293";

        const name = deviceName(device).toLowerCase();
        const iconName = (device.icon || "").toLowerCase();
        const combined = `${name} ${iconName}`;

        if (/headset|headphone|audio-head/.test(combined))
            return "\uf025";
        if (/speaker|audio-speaker/.test(combined))
            return "\uf028";
        if (/keyboard/.test(combined))
            return "\uf11c";
        if (/mouse/.test(combined))
            return "󰍽";
        if (/gamepad|controller|joystick/.test(combined))
            return "\uf11b";
        if (/phone|iphone|android|smartphone/.test(combined))
            return "\uf3cd";
        if (/watch/.test(combined))
            return "\uf017";
        if (/display|television|\\btv\\b/.test(combined))
            return "\uf26c";
        return "\uf293";
    }

    function isKnown(device): bool {
        return !!device && (device.paired || device.bonded || device.trusted);
    }

    function hasUsefulName(device): bool {
        if (!device)
            return false;
        const candidate = (device.name || device.deviceName || "").trim();
        const macAddress = /^[0-9A-F]{2}(?:[:-][0-9A-F]{2}){5}$/i;
        return candidate !== ""
            && !macAddress.test(candidate)
            && candidate.toUpperCase() !== (device.address || "").toUpperCase();
    }

    function sortDevices(source): var {
        return [...source].sort((left, right) => deviceName(left).localeCompare(deviceName(right)));
    }

    function deviceStatus(device): string {
        if (!device)
            return "Unavailable";
        if (device.pairing)
            return "Pairing…";
        if (device.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
        if (device.connected)
            return "Connected";
        if (isKnown(device))
            return "Paired";
        return "Ready to pair";
    }

    function deviceBusy(device): bool {
        return !!device && (device.pairing
                            || device.state === BluetoothDeviceState.Connecting
                            || device.state === BluetoothDeviceState.Disconnecting);
    }

    function toggleDevice(device): void {
        if (!device || deviceBusy(device))
            return;

        if (device.connected) {
            device.disconnect();
            return;
        }

        if (isKnown(device)) {
            device.connect();
            return;
        }

        // New devices are paired by BluetoothPairing's interactive BlueZ agent.
    }

    function toggleEnabled(): void {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function startDiscovery(): void {
        if (adapter && adapter.enabled)
            adapter.discovering = true;
    }

    function stopDiscovery(): void {
        if (adapter && adapter.discovering)
            adapter.discovering = false;
    }
}
