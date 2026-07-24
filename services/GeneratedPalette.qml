pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string path: Quickshell.cachePath("palette.json")
    readonly property var colors: paletteAdapter.colors
    readonly property string mode: paletteAdapter.mode
    readonly property string seed: paletteAdapter.seed
    readonly property var requiredRoles: ["primary", "onPrimary", "primaryContainer", "onPrimaryContainer", "secondary",
        "onSecondary", "secondaryContainer", "onSecondaryContainer", "tertiary", "onTertiary", "tertiaryContainer",
        "onTertiaryContainer", "error", "onError", "errorContainer", "onErrorContainer", "background", "onBackground",
        "surface", "onSurface", "surfaceVariant", "onSurfaceVariant", "outline", "outlineVariant", "shadow", "scrim",
        "inverseSurface", "inverseOnSurface", "inversePrimary", "primaryFixed", "onPrimaryFixed", "primaryFixedDim",
        "onPrimaryFixedVariant", "secondaryFixed", "onSecondaryFixed", "secondaryFixedDim", "onSecondaryFixedVariant",
        "tertiaryFixed", "onTertiaryFixed", "tertiaryFixedDim", "onTertiaryFixedVariant", "surfaceDim", "surfaceBright",
        "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh",
        "surfaceContainerHighest"]

    property bool available: false
    property string errorMessage: "Generated palette has not been loaded"

    function isHexColor(value): bool {
        return typeof value === "string" && /^#[0-9a-f]{6}$/i.test(value);
    }

    function validate(): void {
        if (paletteAdapter.version !== 1) {
            available = false;
            errorMessage = `Unsupported palette version: ${paletteAdapter.version}`;
            return;
        }

        if (paletteAdapter.mode !== "dark" && paletteAdapter.mode !== "light") {
            available = false;
            errorMessage = `Unsupported palette mode: ${paletteAdapter.mode || "missing"}`;
            return;
        }

        for (const role of requiredRoles) {
            if (!isHexColor(colors[role])) {
                available = false;
                errorMessage = `Invalid or missing color role: ${role}`;
                return;
            }
        }

        available = true;
        errorMessage = "";
    }

    function reload(): void {
        paletteFile.reload();
    }

    FileView {
        id: paletteFile

        path: root.path
        preload: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: root.validate()
        onLoadFailed: error => {
            root.available = false;
            root.errorMessage = FileViewError.toString(error);
        }

        JsonAdapter {
            id: paletteAdapter

            property int version: 0
            property string mode: ""
            property string seed: ""
            property var colors: ({})
        }
    }
}
