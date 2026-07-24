pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var opaquePalette: GeneratedPalette.available ? GeneratedPalette.colors : fallbackPalette.colors
    readonly property ResolvedPalette palette: ResolvedPalette {}
    readonly property Transparency transparency: Transparency {}
    readonly property bool usingGeneratedPalette: GeneratedPalette.available
    readonly property string paletteMode: usingGeneratedPalette ? GeneratedPalette.mode : "dark"
    readonly property string paletteSource: usingGeneratedPalette ? "generated" : "fallback"

    FallbackPalette {
        id: fallbackPalette
    }

    component Transparency: QtObject {
        property real base: 0.5
        property real elevated: 1
    }

    component ResolvedPalette: QtObject {
        readonly property color m3primary: root.opaquePalette.primary
        readonly property color m3onPrimary: root.opaquePalette.onPrimary
        readonly property color m3primaryContainer: root.opaquePalette.primaryContainer
        readonly property color m3onPrimaryContainer: root.opaquePalette.onPrimaryContainer

        readonly property color m3secondary: root.opaquePalette.secondary
        readonly property color m3onSecondary: root.opaquePalette.onSecondary
        readonly property color m3secondaryContainer: root.opaquePalette.secondaryContainer
        readonly property color m3onSecondaryContainer: root.opaquePalette.onSecondaryContainer

        readonly property color m3tertiary: root.opaquePalette.tertiary
        readonly property color m3onTertiary: root.opaquePalette.onTertiary
        readonly property color m3tertiaryContainer: root.opaquePalette.tertiaryContainer
        readonly property color m3onTertiaryContainer: root.opaquePalette.onTertiaryContainer

        readonly property color m3error: root.opaquePalette.error
        readonly property color m3onError: root.opaquePalette.onError
        readonly property color m3errorContainer: root.opaquePalette.errorContainer
        readonly property color m3onErrorContainer: root.opaquePalette.onErrorContainer

        readonly property color m3background: root.opaquePalette.background
        readonly property color m3onBackground: root.opaquePalette.onBackground

        readonly property color m3surface: Qt.alpha(root.opaquePalette.surface, root.transparency.base)
        readonly property color m3onSurface: Qt.alpha(root.opaquePalette.onSurface, root.transparency.elevated)
        readonly property color m3surfaceVariant: Qt.alpha(root.opaquePalette.surfaceVariant, root.transparency.base)
        readonly property color m3onSurfaceVariant: Qt.alpha(root.opaquePalette.onSurfaceVariant,
                                                             root.transparency.elevated)

        readonly property color m3outline: root.opaquePalette.outline
        readonly property color m3outlineVariant: root.opaquePalette.outlineVariant

        readonly property color m3shadow: root.opaquePalette.shadow
        readonly property color m3scrim: root.opaquePalette.scrim

        readonly property color m3inverseSurface: root.opaquePalette.inverseSurface
        readonly property color m3inverseOnSurface: root.opaquePalette.inverseOnSurface
        readonly property color m3inversePrimary: root.opaquePalette.inversePrimary

        readonly property color m3primaryFixed: root.opaquePalette.primaryFixed
        readonly property color m3onPrimaryFixed: root.opaquePalette.onPrimaryFixed
        readonly property color m3primaryFixedDim: root.opaquePalette.primaryFixedDim
        readonly property color m3onPrimaryFixedVariant: root.opaquePalette.onPrimaryFixedVariant

        readonly property color m3secondaryFixed: root.opaquePalette.secondaryFixed
        readonly property color m3onSecondaryFixed: root.opaquePalette.onSecondaryFixed
        readonly property color m3secondaryFixedDim: root.opaquePalette.secondaryFixedDim
        readonly property color m3onSecondaryFixedVariant: root.opaquePalette.onSecondaryFixedVariant

        readonly property color m3tertiaryFixed: root.opaquePalette.tertiaryFixed
        readonly property color m3onTertiaryFixed: root.opaquePalette.onTertiaryFixed
        readonly property color m3tertiaryFixedDim: root.opaquePalette.tertiaryFixedDim
        readonly property color m3onTertiaryFixedVariant: root.opaquePalette.onTertiaryFixedVariant

        readonly property color m3surfaceDim: Qt.alpha(root.opaquePalette.surfaceDim, root.transparency.base)
        readonly property color m3surfaceBright: Qt.alpha(root.opaquePalette.surfaceBright, root.transparency.base)
        readonly property color m3surfaceContainerLowest: Qt.alpha(root.opaquePalette.surfaceContainerLowest,
                                                                   root.transparency.base)
        readonly property color m3surfaceContainerLow: Qt.alpha(root.opaquePalette.surfaceContainerLow,
                                                                root.transparency.base)
        readonly property color m3surfaceContainer: Qt.alpha(root.opaquePalette.surfaceContainer,
                                                             root.transparency.base)
        readonly property color m3surfaceContainerHigh: Qt.alpha(root.opaquePalette.surfaceContainerHigh,
                                                                 root.transparency.base)
        readonly property color m3surfaceContainerHighest: Qt.alpha(root.opaquePalette.surfaceContainerHighest,
                                                                    root.transparency.base)
    }
}
