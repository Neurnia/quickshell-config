import QtQuick
import Quickshell.Hyprland
import qs.services
import qs.components

Row {
    spacing: 3
    Repeater {
        // normal workspaces
        model: Hyprland.workspaces.values.filter(ws => ws.id > 0)
        Capsule {
            required property HyprlandWorkspace modelData
            content.text: modelData.id
            width: 20
            radius: height / 4

            color: modelData.focused ? Colors.palette.m3secondary : Colors.palette.m3surfaceVariant
            content.color: modelData.focused ? Colors.palette.m3onSecondary : Colors.palette.m3onSurface

            border.color: hover.hovered ? Colors.palette.m3outline : "transparent"
            HoverHandler {
                id: hover
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch(`workspace ${modelData.id}`)
            }
        }
    }
}
