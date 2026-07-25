pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property ResolvedPalette palette: ResolvedPalette {}
    readonly property bool usingGeneratedPalette: GeneratedPalette.available
    readonly property string paletteMode: usingGeneratedPalette ? GeneratedPalette.mode : "dark"
    readonly property string paletteSource: usingGeneratedPalette ? "generated" : "fallback"
    property real surfaceOpacity: 0.5

    FallbackPalette {
        id: fallbackPalette
    }

    function resolveColor(role: string, fallback: color): color {
        return usingGeneratedPalette ? GeneratedPalette.colors[role] : fallback;
    }

    IpcHandler {
        target: "colors"

        function status(): string {
            return `${root.paletteSource} (${root.paletteMode}), surface text: ${root.palette.surfaceText}`;
        }
    }

    component ResolvedPalette: QtObject {
        readonly property color primary: root.resolveColor("primary", fallbackPalette.primaryColor)
        readonly property color primaryText: root.resolveColor("onPrimary", fallbackPalette.primaryTextColor)
        readonly property color primaryContainer: root.resolveColor("primaryContainer", fallbackPalette.primaryContainerColor)
        readonly property color primaryContainerText: root.resolveColor("onPrimaryContainer", fallbackPalette.primaryContainerTextColor)

        readonly property color secondary: root.resolveColor("secondary", fallbackPalette.secondaryColor)
        readonly property color secondaryText: root.resolveColor("onSecondary", fallbackPalette.secondaryTextColor)
        readonly property color error: root.resolveColor("error", fallbackPalette.errorColor)
        readonly property color errorContainer: root.resolveColor("errorContainer", fallbackPalette.errorContainerColor)
        readonly property color errorContainerText: root.resolveColor("onErrorContainer", fallbackPalette.errorContainerTextColor)

        readonly property color surfaceText: root.resolveColor("onSurface", fallbackPalette.surfaceTextColor)
        readonly property color surfaceVariant: Qt.alpha(root.resolveColor("surfaceVariant", fallbackPalette.surfaceVariantColor), root.surfaceOpacity)
        readonly property color surfaceVariantText: root.resolveColor("onSurfaceVariant", fallbackPalette.surfaceVariantTextColor)

        readonly property color outline: root.resolveColor("outline", fallbackPalette.outlineColor)
        readonly property color outlineVariant: root.resolveColor("outlineVariant", fallbackPalette.outlineVariantColor)

        readonly property color surfaceContainerLowest: Qt.alpha(root.resolveColor("surfaceContainerLowest", fallbackPalette.surfaceContainerLowestColor), root.surfaceOpacity)
        readonly property color surfaceContainerLow: Qt.alpha(root.resolveColor("surfaceContainerLow", fallbackPalette.surfaceContainerLowColor), root.surfaceOpacity)
        readonly property color surfaceContainerHigh: Qt.alpha(root.resolveColor("surfaceContainerHigh", fallbackPalette.surfaceContainerHighColor), root.surfaceOpacity)
        readonly property color surfaceContainerHighest: Qt.alpha(root.resolveColor("surfaceContainerHighest", fallbackPalette.surfaceContainerHighestColor), root.surfaceOpacity)
    }
}
