pragma Singleton

import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: device?.ready && device.isPresent
    readonly property int percentage: Math.round((device?.percentage ?? 0) * 100)
    readonly property bool powerConnected: available && !UPower.onBattery
    readonly property bool low: available && !powerConnected && percentage <= 15
    readonly property string icon: powerConnected ? "󰂄" : percentage <= 10 ? "\uf244" : percentage <= 35 ? "\uf243" : percentage <= 60 ? "\uf242" : percentage <= 85 ? "\uf241" : "\uf240"
}
