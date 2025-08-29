pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    FileView {
        id: osInfo

        path: "/etc/os-release"
    }

    FileView {
        id: uptime

        path: "/proc/uptime"
    }
}
