import qs.components
import qs.services

StatusPopover {
    statusIcon: BluetoothState.icon
    statusText: BluetoothState.label
    details: {
        if (!BluetoothState.available)
            return "No adapter detected";
        if (!BluetoothState.enabled)
            return "Wireless devices unavailable";
        if (BluetoothState.connectedCount === 0)
            return "No connected devices";
        return BluetoothState.connectedCount === 1
            ? "1 connected device"
            : `${BluetoothState.connectedCount} connected devices`;
    }
    toggleIcon: "\uf293"
    toggleText: `Bluetooth ${BluetoothState.enabled ? "on" : "off"}`
    toggleActive: BluetoothState.enabled
    toggleEnabled: BluetoothState.available
    configText: "BT config"

    onToggleRequested: BluetoothState.toggleEnabled()
}
