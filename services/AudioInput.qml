pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: endpoint.volume
    readonly property bool muted: endpoint.muted
    readonly property int percentage: endpoint.percentage
    readonly property string icon: muted || percentage === 0 ? "\uf131" : "\uf130"
    readonly property bool inUse: {
        if (!Pipewire.ready || !Pipewire.nodes?.values)
            return false;

        for (const node of Pipewire.nodes.values) {
            if (!node)
                continue;

            if ((node.type & PwNodeType.AudioInStream) === PwNodeType.AudioInStream && !looksLikeSystemCapture(node))
                return true;
        }

        return false;
    }

    signal inputChanged

    function looksLikeSystemCapture(node): bool {
        const name = (node.name || "").toLowerCase();
        const mediaName = (node.properties?.["media.name"] || "").toLowerCase();
        const applicationName = (node.properties?.["application.name"] || "").toLowerCase();
        return /cava|spectrum|visuali[sz]er|monitor/.test(`${name} ${mediaName} ${applicationName}`);
    }

    function setVolume(value: real): void {
        endpoint.setVolume(value);
    }

    function adjustVolume(amount: real): void {
        endpoint.adjustVolume(amount);
    }

    function toggleMute(): void {
        endpoint.toggleMute();
    }

    AudioEndpoint {
        id: endpoint
        node: root.source
        onChanged: root.inputChanged()
    }

    PwObjectTracker {
        objects: Pipewire.nodes.values.filter(node => node && !node.isStream)
    }
}
