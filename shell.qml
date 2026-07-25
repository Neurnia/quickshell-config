import "modules/bar"
import "modules/bluetooth"
import "modules/network"
import "modules/osd"
import "modules/power"

import Quickshell

ShellRoot {
    Bar {
        onConnectivityConfigRequested: page => {
            if (page === "bluetooth")
                bluetoothConfig.open();
            else
                wifiConfig.open();
        }
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
