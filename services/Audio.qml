pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio.volume ?? 0
    readonly property bool muted: sink?.audio.muted ?? false
    readonly property int percentage: Math.round(volume * 100)
    readonly property string icon: muted || percentage === 0 ? "\uf6a9" : percentage < 50 ? "\uf027" : "\uf028"

    signal outputChanged

    function setVolume(value: real): void {
        if (!sink)
            return;

        sink.audio.volume = Math.max(0, Math.min(1, value));
        if (sink.audio.muted && value > 0)
            sink.audio.muted = false;
    }

    function adjustVolume(amount: real): void {
        setVolume(volume + amount);
    }

    function toggleMute(): void {
        if (sink)
            sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumesChanged(): void {
            root.outputChanged();
        }

        function onMutedChanged(): void {
            root.outputChanged();
        }
    }
}
