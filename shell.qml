import "modules/bar"
import "modules/network"
import "modules/osd"

import Quickshell

ShellRoot {
    Bar {
        onWifiConfigRequested: wifiConfig.open()
    }
    WifiConfig {
        id: wifiConfig
    }
    VolumeOsd {}
}
