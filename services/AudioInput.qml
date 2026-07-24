pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: source?.audio.volume ?? 0
    readonly property bool muted: source?.audio.muted ?? false
    readonly property int percentage: Math.round(volume * 100)
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
        if (!source)
            return;

        source.audio.volume = Math.max(0, Math.min(1, value));
        if (source.audio.muted && value > 0)
            source.audio.muted = false;
    }

    function adjustVolume(amount: real): void {
        setVolume(volume + amount);
    }

    function toggleMute(): void {
        if (source)
            source.audio.muted = !source.audio.muted;
    }

    PwObjectTracker {
        objects: Pipewire.nodes.values.filter(node => node && !node.isStream)
    }

    Connections {
        target: root.source?.audio ?? null

        function onVolumesChanged(): void {
            root.inputChanged();
        }

        function onMutedChanged(): void {
            root.inputChanged();
        }
    }
}
