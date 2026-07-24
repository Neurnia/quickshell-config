import QtQuick
import Quickshell.Hyprland
import qs.services
import qs.components

Row {
    spacing: 3
    Repeater {
        // normal workspaces
        model: Hyprland.workspaces.values.filter(ws => ws.id > 0)
        ActionCapsule {
            required property HyprlandWorkspace modelData
            content.text: modelData.id
            width: 20
            radius: height / 4

            color: modelData.focused ? Colors.palette.secondary : Colors.palette.surfaceVariant
            content.color: modelData.focused ? Colors.palette.secondaryText : Colors.palette.surfaceText

            onClicked: Hyprland.dispatch(`workspace ${modelData.id}`)
        }
    }
}
