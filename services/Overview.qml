pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
    function toggle(): void {
        Hyprland.dispatch('hl.plugin.scrolloverview.overview("toggle")');
    }
}
