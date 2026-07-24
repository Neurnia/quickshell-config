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
    readonly property var connectedDevices: devices.filter(device => device && device.connected)
    readonly property var pairedDevices: devices.filter(device => device && (device.paired || device.bonded || device.trusted))
    readonly property int connectedCount: connectedDevices.length
    readonly property string icon: enabled ? "\uf293" : "󰂲"
    readonly property string label: {
        if (!available)
            return "No Bluetooth";
        if (!enabled)
            return "Bluetooth off";
        if (connectedCount === 1)
            return deviceName(connectedDevices[0]);
        if (connectedCount > 1)
            return `${connectedCount} connected`;
        return "Bluetooth";
    }

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
