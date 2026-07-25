import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root

    property PwNode node: null
    readonly property real volume: node?.audio.volume ?? 0
    readonly property bool muted: node?.audio.muted ?? false
    readonly property int percentage: Math.round(volume * 100)

    signal changed

    function setVolume(value: real): void {
        if (!node)
            return;

        node.audio.volume = Math.max(0, Math.min(1, value));
        if (node.audio.muted && value > 0)
            node.audio.muted = false;
    }

    function adjustVolume(amount: real): void {
        setVolume(volume + amount);
    }

    function toggleMute(): void {
        if (node)
            node.audio.muted = !node.audio.muted;
    }

    PwObjectTracker {
        objects: root.node ? [root.node] : []
    }

    Connections {
        target: root.node?.audio ?? null

        function onVolumesChanged(): void {
            root.changed();
        }

        function onMutedChanged(): void {
            root.changed();
        }
    }
}
