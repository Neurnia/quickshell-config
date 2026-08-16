pragma Singleton

import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    readonly property var items: SystemTray.items

    function activate(item): void {
        if (item)
            item.activate();
    }

    function secondaryActivate(item): void {
        if (item)
            item.secondaryActivate();
    }

    function scroll(item, delta: int, horizontal: bool): void {
        if (item && delta !== 0)
            item.scroll(delta, horizontal);
    }
}
