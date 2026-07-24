pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool connected: false
    property bool wifiEnabled: false
    property bool vpnConnected: false
    property string connectionType: "offline"
    property string connectionName: ""
    property string device: ""
    property string ipAddress: ""
    property string vpnName: ""
    property int signalStrength: 0
    property var networks: []
    property var savedNetworks: []
    property bool refreshing: false
    property int pendingReads: 0

    readonly property string icon: {
        if (connectionType === "ethernet")
            return "󰈀";
        if (connectionType !== "wifi")
            return "󰤭";
        if (signalStrength >= 75)
            return "󰤨";
        if (signalStrength >= 50)
            return "󰤥";
        if (signalStrength >= 25)
            return "󰤢";
        return "󰤟";
    }
    readonly property string label: {
        if (connected)
            return connectionName || (connectionType === "ethernet" ? "Ethernet" : "Wi-Fi");
        if (!available)
            return "Network";
        return wifiEnabled ? "Offline" : "Wi-Fi off";
    }

    function splitEscaped(line: string): list<string> {
        const fields = [];
        let field = "";
        let escaped = false;

        for (let index = 0; index < line.length; index++) {
            const character = line[index];
            if (escaped) {
                field += character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else if (character === ":") {
                fields.push(field);
                field = "";
            } else {
                field += character;
            }
        }

        fields.push(field);
        return fields;
    }

    function refresh(): void {
        if (refreshing)
            return;

        refreshing = true;
        pendingReads = 4;
        statusReader.running = true;
        wifiReader.running = true;
        savedReader.running = true;
        radioReader.running = true;
    }

    function finishRead(): void {
        pendingReads = Math.max(0, pendingReads - 1);
        if (pendingReads === 0)
            refreshing = false;
    }

    function parseStatus(output: string): void {
        const lines = output.split("\n");
        let ethernet = null;
        let wifi = null;
        let hasNetworkDevice = false;
        let activeVpn = "";

        for (const line of lines) {
            if (!line)
                continue;

            const fields = splitEscaped(line);
            const entry = {
                device: fields[0] || "",
                type: fields[1] || "",
                state: fields[2] || "",
                connection: fields[3] || ""
            };
            const isConnected = entry.state.indexOf("connected") === 0;

            if (entry.type === "wifi" || entry.type === "ethernet")
                hasNetworkDevice = true;
            if (entry.type === "ethernet" && isConnected)
                ethernet = entry;
            else if (entry.type === "wifi" && isConnected)
                wifi = entry;
            else if (entry.type === "tun" && isConnected)
                activeVpn = entry.connection;
        }

        const primary = ethernet || wifi;
        available = hasNetworkDevice;
        connected = primary !== null;
        connectionType = ethernet ? "ethernet" : wifi ? "wifi" : "offline";
        connectionName = primary ? primary.connection : "";
        device = primary ? primary.device : "";
        vpnConnected = activeVpn !== "";
        vpnName = activeVpn;

        if (device) {
            ipAddress = "";
            ipReader.exec(["nmcli", "-g", "IP4.ADDRESS", "device", "show", device]);
        } else {
            ipAddress = "";
            signalStrength = 0;
        }
    }

    function parseWifi(output: string): void {
        const strongestByName = {};

        for (const line of output.split("\n")) {
            if (!line)
                continue;

            const fields = splitEscaped(line);
            const name = fields[1] || "";
            if (!name)
                continue;

            const candidate = {
                active: fields[0] === "*",
                name: name,
                signal: Number(fields[2]) || 0,
                security: fields[3] || "",
                secured: Boolean(fields[3]),
                saved: savedNetworks.indexOf(name) !== -1
            };
            const existing = strongestByName[name];
            if (!existing || candidate.active || candidate.signal > existing.signal)
                strongestByName[name] = candidate;
        }

        const result = Object.keys(strongestByName).map(name => strongestByName[name]);
        result.sort((left, right) => {
            if (left.active !== right.active)
                return left.active ? -1 : 1;
            return right.signal - left.signal;
        });
        networks = result;

        const active = result.find(network => network.active);
        if (active) {
            signalStrength = active.signal;
            if (connectionType === "wifi")
                connectionName = active.name;
        }
    }

    function parseSaved(output: string): void {
        const names = [];
        for (const line of output.split("\n")) {
            if (!line)
                continue;

            const fields = splitEscaped(line);
            if (fields[1] === "802-11-wireless")
                names.push(fields[0]);
        }

        savedNetworks = names;
        networks = networks.map(network => ({
            active: network.active,
            name: network.name,
            signal: network.signal,
            security: network.security,
            secured: network.secured,
            saved: names.indexOf(network.name) !== -1
        }));
    }

    Process {
        id: statusReader
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseStatus(text.trim());
                root.finishRead();
            }
        }
    }

    Process {
        id: wifiReader
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseWifi(text.trim());
                root.finishRead();
            }
        }
    }

    Process {
        id: savedReader
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseSaved(text.trim());
                root.finishRead();
            }
        }
    }

    Process {
        id: radioReader
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
                root.finishRead();
            }
        }
    }

    Process {
        id: ipReader
        stdout: StdioCollector {
            onStreamFinished: {
                const address = text.trim().split("\n")[0] || "";
                root.ipAddress = address.split("/")[0];
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
