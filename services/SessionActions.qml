pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var actions: [lockAction, suspendAction, restartAction, shutdownAction]
    readonly property var lockAction: ({
        id: "lock",
        icon: "\uf023",
        label: "Lock",
        description: "Lock this session",
        command: ["hyprlock"],
        dangerous: false
    })
    readonly property var suspendAction: ({
        id: "suspend",
        icon: "\uf186",
        label: "Suspend",
        description: "Sleep until you return",
        command: ["systemctl", "suspend"],
        dangerous: false
    })
    readonly property var restartAction: ({
        id: "restart",
        icon: "\uf2f9",
        label: "Restart",
        description: "Restart the computer",
        command: ["systemctl", "reboot"],
        dangerous: true
    })
    readonly property var shutdownAction: ({
        id: "shutdown",
        icon: "\uf011",
        label: "Shut down",
        description: "Turn off the computer",
        command: ["systemctl", "poweroff"],
        dangerous: true
    })

    readonly property bool busy: runner.running

    function execute(action): void {
        if (!action || busy)
            return;
        runner.exec(action.command);
    }

    Process {
        id: runner
    }
}
