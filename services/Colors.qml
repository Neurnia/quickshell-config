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
        readonly property color primary: root.opaquePalette.primary
        readonly property color onPrimary: root.opaquePalette.onPrimary
        readonly property color primaryContainer: root.opaquePalette.primaryContainer
        readonly property color onPrimaryContainer: root.opaquePalette.onPrimaryContainer

        readonly property color secondary: root.opaquePalette.secondary
        readonly property color onSecondary: root.opaquePalette.onSecondary
        readonly property color secondaryContainer: root.opaquePalette.secondaryContainer
        readonly property color onSecondaryContainer: root.opaquePalette.onSecondaryContainer

        readonly property color tertiary: root.opaquePalette.tertiary
        readonly property color onTertiary: root.opaquePalette.onTertiary
        readonly property color tertiaryContainer: root.opaquePalette.tertiaryContainer
        readonly property color onTertiaryContainer: root.opaquePalette.onTertiaryContainer

        readonly property color error: root.opaquePalette.error
        readonly property color onError: root.opaquePalette.onError
        readonly property color errorContainer: root.opaquePalette.errorContainer
        readonly property color onErrorContainer: root.opaquePalette.onErrorContainer

        readonly property color background: root.opaquePalette.background
        readonly property color onBackground: root.opaquePalette.onBackground

        readonly property color surface: Qt.alpha(root.opaquePalette.surface, root.transparency.base)
        readonly property color onSurface: Qt.alpha(root.opaquePalette.onSurface, root.transparency.elevated)
        readonly property color surfaceVariant: Qt.alpha(root.opaquePalette.surfaceVariant, root.transparency.base)
        readonly property color onSurfaceVariant: Qt.alpha(root.opaquePalette.onSurfaceVariant,
                                                           root.transparency.elevated)

        readonly property color outline: root.opaquePalette.outline
        readonly property color outlineVariant: root.opaquePalette.outlineVariant

        readonly property color shadow: root.opaquePalette.shadow
        readonly property color scrim: root.opaquePalette.scrim

        readonly property color inverseSurface: root.opaquePalette.inverseSurface
        readonly property color inverseOnSurface: root.opaquePalette.inverseOnSurface
        readonly property color inversePrimary: root.opaquePalette.inversePrimary

        readonly property color primaryFixed: root.opaquePalette.primaryFixed
        readonly property color onPrimaryFixed: root.opaquePalette.onPrimaryFixed
        readonly property color primaryFixedDim: root.opaquePalette.primaryFixedDim
        readonly property color onPrimaryFixedVariant: root.opaquePalette.onPrimaryFixedVariant

        readonly property color secondaryFixed: root.opaquePalette.secondaryFixed
        readonly property color onSecondaryFixed: root.opaquePalette.onSecondaryFixed
        readonly property color secondaryFixedDim: root.opaquePalette.secondaryFixedDim
        readonly property color onSecondaryFixedVariant: root.opaquePalette.onSecondaryFixedVariant

        readonly property color tertiaryFixed: root.opaquePalette.tertiaryFixed
        readonly property color onTertiaryFixed: root.opaquePalette.onTertiaryFixed
        readonly property color tertiaryFixedDim: root.opaquePalette.tertiaryFixedDim
        readonly property color onTertiaryFixedVariant: root.opaquePalette.onTertiaryFixedVariant

        readonly property color surfaceDim: Qt.alpha(root.opaquePalette.surfaceDim, root.transparency.base)
        readonly property color surfaceBright: Qt.alpha(root.opaquePalette.surfaceBright, root.transparency.base)
        readonly property color surfaceContainerLowest: Qt.alpha(root.opaquePalette.surfaceContainerLowest,
                                                                 root.transparency.base)
        readonly property color surfaceContainerLow: Qt.alpha(root.opaquePalette.surfaceContainerLow,
                                                              root.transparency.base)
        readonly property color surfaceContainer: Qt.alpha(root.opaquePalette.surfaceContainer, root.transparency.base)
        readonly property color surfaceContainerHigh: Qt.alpha(root.opaquePalette.surfaceContainerHigh,
                                                               root.transparency.base)
        readonly property color surfaceContainerHighest: Qt.alpha(root.opaquePalette.surfaceContainerHighest,
                                                                  root.transparency.base)
    }
}
