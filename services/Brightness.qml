pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int maximum: Number(maximumView.text().trim()) || 1
    readonly property int current: Number(currentView.text().trim()) || 0
    readonly property int percentage: Math.round(current / maximum * 100)
    readonly property string icon: percentage < 34 ? "󰖔" : percentage < 67 ? "󰖕" : "󰖙"

    function adjust(amount: int): void {
        setter.exec([
            "brightnessctl",
            "--min-value=1",
            "set",
            amount > 0 ? "5%+" : "5%-"
        ]);
        refreshTimer.restart();
    }

    FileView {
        id: maximumView
        path: "/sys/class/backlight/intel_backlight/max_brightness"
        preload: true
    }

    FileView {
        id: currentView
        path: "/sys/class/backlight/intel_backlight/brightness"
        preload: true
        watchChanges: true
        onFileChanged: reload()
    }

    Process {
        id: setter
        onExited: currentView.reload()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: currentView.reload()
    }

    Timer {
        id: refreshTimer
        interval: 100
        onTriggered: currentView.reload()
    }
}
