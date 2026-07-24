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
        readonly property color secondaryContainer: root.resolveColor("secondaryContainer", fallbackPalette.secondaryContainerColor)
        readonly property color secondaryContainerText: root.resolveColor("onSecondaryContainer", fallbackPalette.secondaryContainerTextColor)

        readonly property color tertiary: root.resolveColor("tertiary", fallbackPalette.tertiaryColor)
        readonly property color tertiaryText: root.resolveColor("onTertiary", fallbackPalette.tertiaryTextColor)
        readonly property color tertiaryContainer: root.resolveColor("tertiaryContainer", fallbackPalette.tertiaryContainerColor)
        readonly property color tertiaryContainerText: root.resolveColor("onTertiaryContainer", fallbackPalette.tertiaryContainerTextColor)

        readonly property color error: root.resolveColor("error", fallbackPalette.errorColor)
        readonly property color errorText: root.resolveColor("onError", fallbackPalette.errorTextColor)
        readonly property color errorContainer: root.resolveColor("errorContainer", fallbackPalette.errorContainerColor)
        readonly property color errorContainerText: root.resolveColor("onErrorContainer", fallbackPalette.errorContainerTextColor)

        readonly property color background: root.resolveColor("background", fallbackPalette.backgroundColor)
        readonly property color backgroundText: root.resolveColor("onBackground", fallbackPalette.backgroundTextColor)

        readonly property color surface: Qt.alpha(root.resolveColor("surface", fallbackPalette.surfaceColor), root.surfaceOpacity)
        readonly property color surfaceText: root.resolveColor("onSurface", fallbackPalette.surfaceTextColor)
        readonly property color surfaceVariant: Qt.alpha(root.resolveColor("surfaceVariant", fallbackPalette.surfaceVariantColor), root.surfaceOpacity)
        readonly property color surfaceVariantText: root.resolveColor("onSurfaceVariant", fallbackPalette.surfaceVariantTextColor)

        readonly property color outline: root.resolveColor("outline", fallbackPalette.outlineColor)
        readonly property color outlineVariant: root.resolveColor("outlineVariant", fallbackPalette.outlineVariantColor)

        readonly property color shadow: root.resolveColor("shadow", fallbackPalette.shadowColor)
        readonly property color scrim: root.resolveColor("scrim", fallbackPalette.scrimColor)

        readonly property color inverseSurface: root.resolveColor("inverseSurface", fallbackPalette.inverseSurfaceColor)
        readonly property color inverseSurfaceText: root.resolveColor("inverseOnSurface", fallbackPalette.inverseSurfaceTextColor)
        readonly property color inversePrimary: root.resolveColor("inversePrimary", fallbackPalette.inversePrimaryColor)

        readonly property color primaryFixed: root.resolveColor("primaryFixed", fallbackPalette.primaryFixedColor)
        readonly property color primaryFixedText: root.resolveColor("onPrimaryFixed", fallbackPalette.primaryFixedTextColor)
        readonly property color primaryFixedDim: root.resolveColor("primaryFixedDim", fallbackPalette.primaryFixedDimColor)
        readonly property color primaryFixedVariantText: root.resolveColor("onPrimaryFixedVariant", fallbackPalette.primaryFixedVariantTextColor)

        readonly property color secondaryFixed: root.resolveColor("secondaryFixed", fallbackPalette.secondaryFixedColor)
        readonly property color secondaryFixedText: root.resolveColor("onSecondaryFixed", fallbackPalette.secondaryFixedTextColor)
        readonly property color secondaryFixedDim: root.resolveColor("secondaryFixedDim", fallbackPalette.secondaryFixedDimColor)
        readonly property color secondaryFixedVariantText: root.resolveColor("onSecondaryFixedVariant", fallbackPalette.secondaryFixedVariantTextColor)

        readonly property color tertiaryFixed: root.resolveColor("tertiaryFixed", fallbackPalette.tertiaryFixedColor)
        readonly property color tertiaryFixedText: root.resolveColor("onTertiaryFixed", fallbackPalette.tertiaryFixedTextColor)
        readonly property color tertiaryFixedDim: root.resolveColor("tertiaryFixedDim", fallbackPalette.tertiaryFixedDimColor)
        readonly property color tertiaryFixedVariantText: root.resolveColor("onTertiaryFixedVariant", fallbackPalette.tertiaryFixedVariantTextColor)

        readonly property color surfaceDim: Qt.alpha(root.resolveColor("surfaceDim", fallbackPalette.surfaceDimColor), root.surfaceOpacity)
        readonly property color surfaceBright: Qt.alpha(root.resolveColor("surfaceBright", fallbackPalette.surfaceBrightColor), root.surfaceOpacity)
        readonly property color surfaceContainerLowest: Qt.alpha(root.resolveColor("surfaceContainerLowest", fallbackPalette.surfaceContainerLowestColor), root.surfaceOpacity)
        readonly property color surfaceContainerLow: Qt.alpha(root.resolveColor("surfaceContainerLow", fallbackPalette.surfaceContainerLowColor), root.surfaceOpacity)
        readonly property color surfaceContainer: Qt.alpha(root.resolveColor("surfaceContainer", fallbackPalette.surfaceContainerColor), root.surfaceOpacity)
        readonly property color surfaceContainerHigh: Qt.alpha(root.resolveColor("surfaceContainerHigh", fallbackPalette.surfaceContainerHighColor), root.surfaceOpacity)
        readonly property color surfaceContainerHighest: Qt.alpha(root.resolveColor("surfaceContainerHighest", fallbackPalette.surfaceContainerHighestColor), root.surfaceOpacity)
    }
}
