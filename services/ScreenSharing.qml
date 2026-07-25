pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property bool active: {
        if (!Pipewire.ready || !Pipewire.nodes?.values)
            return false;

        for (const node of Pipewire.nodes.values) {
            if (!node || !node.ready)
                continue;

            const mediaClass = node.properties?.["media.class"] || "";
            const isVideoSource = (node.type & PwNodeType.VideoSource) === PwNodeType.VideoSource;
            if ((isVideoSource || mediaClass === "Stream/Output/Video") && looksLikeScreenCast(node))
                return true;
        }

        return false;
    }
    readonly property string icon: "\uf108"

    function looksLikeScreenCast(node): bool {
        const nodeName = (node.name || "").toLowerCase();
        const mediaName = (node.properties?.["media.name"] || "").toLowerCase();
        const applicationName = (node.properties?.["application.name"] || "").toLowerCase();
        return /xdg-desktop-portal|xdpw|screencast|screen-cast|screen|hyprland|niri|gnome shell|kwin|obs/.test(`${nodeName} ${mediaName} ${applicationName}`);
    }

    PwObjectTracker {
        objects: Pipewire.nodes.values.filter(node => node && !node.isStream)
    }
}
