pragma Singleton

import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: device?.ready && device.isPresent
    readonly property int percentage: Math.round((device?.percentage ?? 0) * 100)
    readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.PendingCharge
    readonly property bool low: available && !charging && percentage <= 15
    readonly property string icon: charging ? "󰂄" : percentage <= 10 ? "\uf244" : percentage <= 35 ? "\uf243" : percentage <= 60 ? "\uf242" : percentage <= 85 ? "\uf241" : "\uf240"
}
