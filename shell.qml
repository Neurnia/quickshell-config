import "modules/bar"
import "modules/bluetooth"
import "modules/network"
import "modules/osd"
import "modules/power"

import Quickshell

ShellRoot {
    Bar {
        onWifiConfigRequested: wifiConfig.open()
        onBluetoothConfigRequested: bluetoothConfig.open()
        onPowerMenuRequested: powerMenu.open()
    }
    BluetoothConfig {
        id: bluetoothConfig
    }
    WifiConfig {
        id: wifiConfig
    }
    PowerMenu {
        id: powerMenu
    }
    VolumeOsd {}
}
