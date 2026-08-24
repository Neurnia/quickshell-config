pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int maximum: 1
    property int current: 0
    readonly property int percentage: Math.round(current / maximum * 100)
    readonly property string icon: percentage < 34 ? "󰖔" : percentage < 67 ? "󰖕" : "󰖙"

    function refresh(): void {
        if (!reader.running)
            reader.running = true;
    }

    function update(output: string): void {
        const fields = output.split("\n")[0].split(",");
        if (fields.length < 5)
            return;

        const nextCurrent = Number(fields[2]);
        const nextMaximum = Number(fields[4]);
        if (isNaN(nextCurrent) || isNaN(nextMaximum) || nextMaximum <= 0)
            return;

        current = nextCurrent;
        maximum = nextMaximum;
    }

    function adjust(amount: int): void {
        setter.exec([
            "brightnessctl",
            "--class=backlight",
            "--min-value=1",
            "set",
            amount > 0 ? "5%+" : "5%-"
        ]);
        refreshTimer.restart();
    }

    Process {
        id: reader
        command: ["brightnessctl", "--class=backlight", "--machine-readable", "info"]
        stdout: StdioCollector {
            onStreamFinished: root.update(text.trim())
        }
    }

    Process {
        id: setter
        onExited: root.refresh()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshTimer
        interval: 100
        onTriggered: root.refresh()
    }
}
