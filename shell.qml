import "modules/bar"
import "modules/bluetooth"
import "modules/network"
import "modules/osd"

import Quickshell

ShellRoot {
    Bar {
        onWifiConfigRequested: wifiConfig.open()
        onBluetoothConfigRequested: bluetoothConfig.open()
    }
    BluetoothConfig {
        id: bluetoothConfig
    }
    WifiConfig {
        id: wifiConfig
    }
    VolumeOsd {}
}
