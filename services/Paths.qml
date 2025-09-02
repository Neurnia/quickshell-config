pragma Singleton

import Quickshell

Singleton {
    // paths do not contain "/" at the end
    readonly property string configDir: Quickshell.shellDir
    readonly property string iconDir: `${Quickshell.shellDir}/assets/icons`
}
