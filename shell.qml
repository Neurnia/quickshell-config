//@ pragma UseQApplication

import "modules/bar"
import "modules/connectivity"
import "modules/osd"
import "modules/power"

import Quickshell

ShellRoot {
    Bar {
        onConnectivityConfigRequested: page => connectivityConfig.open(page)
        onPowerMenuRequested: powerMenu.open()
    }
    ConnectivityConfig {
        id: connectivityConfig
    }
    PowerMenu {
        id: powerMenu
    }
    VolumeOsd {}
}
