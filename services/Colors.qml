pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root
    readonly property M3Palette opaquePalette: preset
    readonly property M3TPalette palette: M3TPalette {}
    readonly property M3Palette preset: M3Palette {}
    readonly property Transparency transparency: Transparency {}

    component Transparency: QtObject {
        property real base: 0.5
        property real elevated: 1
    }

    component M3TPalette: QtObject {
        // primary
        readonly property color m3primary: "#E3F2FF"
        readonly property color m3onPrimary: "#000000"
        readonly property color m3primaryContainer: "#8ECAF1"
        readonly property color m3onPrimaryContainer: "#000D16"
        // secondary
        readonly property color m3secondary: "#E3F2FF"
        readonly property color m3onSecondary: "#000000"
        readonly property color m3secondaryContainer: "#B2C5D4"
        readonly property color m3onSecondaryContainer: "#000D16"
        // tertiary
        readonly property color m3tertiary: "#F5EDFF"
        readonly property color m3onTertiary: "#000000"
        readonly property color m3tertiaryContainer: "#C8BDE5"
        readonly property color m3onTertiaryContainer: "#0E0624"
        // error
        readonly property color m3error: "#FFECE9"
        readonly property color m3onError: "#000000"
        readonly property color m3errorContainer: "#FFAEA4"
        readonly property color m3onErrorContainer: "#220001"
        // background
        readonly property color m3background: "#101417"
        readonly property color m3onBackground: "#DFE3E7"
        // surface
        readonly property color m3surface: Qt.alpha(root.opaquePalette.m3surface, root.transparency.base)
        readonly property color m3onSurface: Qt.alpha(root.opaquePalette.m3onSurface, root.transparency.elevated)
        readonly property color m3surfaceVariant: Qt.alpha(root.opaquePalette.m3surfaceVariant, root.transparency.base)
        readonly property color m3onSurfaceVariant: Qt.alpha(root.opaquePalette.m3onSurfaceVariant, root.transparency.elevated)
        // outline
        readonly property color m3outline: "#EAF1F7"
        readonly property color m3outlineVariant: "#BDC3CA"
        // shadow
        readonly property color m3shadow: "#000000"
        // scrim
        readonly property color m3scrim: "#000000"
        // inverse
        readonly property color m3inverseSurface: "#DFE3E7"
        readonly property color m3inverseOnSurface: "#000000"
        readonly property color m3inversePrimary: "#004D6D"
        // fixed
        readonly property color m3primaryFixed: "#C7E7FF"
        readonly property color m3onPrimaryFixed: "#000000"
        readonly property color m3primaryFixedDim: "#92CEF5"
        readonly property color m3onPrimaryFixedVariant: "#00131F"
        readonly property color m3secondaryFixed: "#D2E5F5"
        readonly property color m3onSecondaryFixed: "#000000"
        readonly property color m3secondaryFixedDim: "#B6C9D8"
        readonly property color m3onSecondaryFixedVariant: "#01131E"
        readonly property color m3tertiaryFixed: "#E8DDFF"
        readonly property color m3onTertiaryFixed: "#000000"
        readonly property color m3tertiaryFixedDim: "#CCC1E9"
        readonly property color m3onTertiaryFixedVariant: "#140B2A"
        // surface containers
        readonly property color m3surfaceDim: Qt.alpha(root.opaquePalette.m3surfaceDim, root.transparency.base)
        readonly property color m3surfaceBright: Qt.alpha(root.opaquePalette.m3surfaceBright, root.transparency.base)
        readonly property color m3surfaceContainerLowest: Qt.alpha(root.opaquePalette.m3surfaceContainerLowest, root.transparency.base)
        readonly property color m3surfaceContainerLow: Qt.alpha(root.opaquePalette.m3surfaceContainerLow, root.transparency.base)
        readonly property color m3surfaceContainer: Qt.alpha(root.opaquePalette.m3surfaceContainer, root.transparency.base)
        readonly property color m3surfaceContainerHigh: Qt.alpha(root.opaquePalette.m3surfaceContainerHigh, root.transparency.base)
        readonly property color m3surfaceContainerHighest: Qt.alpha(root.opaquePalette.m3surfaceContainerHighest, root.transparency.base)
    }

    component M3Palette: QtObject {
        // primary
        property color m3primary: "#E3F2FF"
        property color m3onPrimary: "#000000"
        property color m3primaryContainer: "#8ECAF1"
        property color m3onPrimaryContainer: "#000D16"
        // secondary
        property color m3secondary: "#E3F2FF"
        property color m3onSecondary: "#000000"
        property color m3secondaryContainer: "#B2C5D4"
        property color m3onSecondaryContainer: "#000D16"
        // tertiary
        property color m3tertiary: "#F5EDFF"
        property color m3onTertiary: "#000000"
        property color m3tertiaryContainer: "#C8BDE5"
        property color m3onTertiaryContainer: "#0E0624"
        // error
        property color m3error: "#FFECE9"
        property color m3onError: "#000000"
        property color m3errorContainer: "#FFAEA4"
        property color m3onErrorContainer: "#220001"
        // background
        property color m3background: "#101417"
        property color m3onBackground: "#DFE3E7"
        // surface
        property color m3surface: "#101417"
        property color m3onSurface: "#FFFFFF"
        property color m3surfaceVariant: "#41484D"
        property color m3onSurfaceVariant: "#FFFFFF"
        // outline
        property color m3outline: "#EAF1F7"
        property color m3outlineVariant: "#BDC3CA"
        // shadow
        property color m3shadow: "#000000"
        // scrim
        property color m3scrim: "#000000"
        // inverse
        property color m3inverseSurface: "#DFE3E7"
        property color m3inverseOnSurface: "#000000"
        property color m3inversePrimary: "#004D6D"
        // fixed
        property color m3primaryFixed: "#C7E7FF"
        property color m3onPrimaryFixed: "#000000"
        property color m3primaryFixedDim: "#92CEF5"
        property color m3onPrimaryFixedVariant: "#00131F"
        property color m3secondaryFixed: "#D2E5F5"
        property color m3onSecondaryFixed: "#000000"
        property color m3secondaryFixedDim: "#B6C9D8"
        property color m3onSecondaryFixedVariant: "#01131E"
        property color m3tertiaryFixed: "#E8DDFF"
        property color m3onTertiaryFixed: "#000000"
        property color m3tertiaryFixedDim: "#CCC1E9"
        property color m3onTertiaryFixedVariant: "#140B2A"
        // surface containers
        property color m3surfaceDim: "#101417"
        property color m3surfaceBright: "#4C5154"
        property color m3surfaceContainerLowest: "#000000"
        property color m3surfaceContainerLow: "#1C2024"
        property color m3surfaceContainer: "#2D3135"
        property color m3surfaceContainerHigh: "#383C40"
        property color m3surfaceContainerHighest: "#43474B"
    }
}
