pragma Singleton

import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    readonly property var sourceItems: SystemTray.items.values
    readonly property var inputMethod: sourceItems.find(item => isInputMethod(item)) ?? null
    readonly property var items: sourceItems.filter(item => !isInputMethod(item))

    function isInputMethod(item): bool {
        if (!item)
            return false;

        const id = (item.id || "").toLowerCase();
        const title = (item.title || "").toLowerCase();
        return id.startsWith("fcitx") || id === "ibus" || title === "input method";
    }

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
