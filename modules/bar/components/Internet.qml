import qs.components
import qs.services

StatusPopover {
    statusIcon: Network.icon
    statusText: `${Network.label}${Network.vpnConnected ? " \uf023" : ""}`
    details: {
        const quality = Network.connectionType === "wifi"
            ? `${Network.signalStrength}%`
            : Network.connectionType === "ethernet"
                ? "Wired connection"
                : "No connection";
        const address = Network.ipAddress ? `  ·  ${Network.ipAddress}` : "";
        return quality + address;
    }
    toggleIcon: "\uf1eb"
    toggleText: `Wi-Fi ${Network.wifiEnabled ? "on" : "off"}`
    toggleActive: Network.wifiEnabled
    toggleEnabled: !Network.busy
    configText: "Wi-Fi config"

    onToggleRequested: Network.toggleWifi()
}
