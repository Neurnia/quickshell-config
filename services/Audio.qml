pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: endpoint.volume
    readonly property bool muted: endpoint.muted
    readonly property int percentage: endpoint.percentage
    readonly property string icon: muted || percentage === 0 ? "󰝟" : percentage < 50 ? "\uf027" : "\uf028"

    signal outputChanged

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
        node: root.sink
        onChanged: root.outputChanged()
    }
}
