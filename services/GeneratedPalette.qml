pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string path: Quickshell.cachePath("palette.json")
    property var colors: ({})
    property string mode: ""
    property string seed: ""
    readonly property var requiredRoles: [
        "primary",
        "onPrimary",
        "primaryContainer",
        "onPrimaryContainer",
        "secondary",
        "onSecondary",
        "error",
        "errorContainer",
        "onErrorContainer",
        "onSurface",
        "surfaceVariant",
        "onSurfaceVariant",
        "outline",
        "outlineVariant",
        "surfaceContainerLowest",
        "surfaceContainerLow",
        "surfaceContainerHigh",
        "surfaceContainerHighest"
    ]

    property bool available: false
    property string errorMessage: "Generated palette has not been loaded"

    function isHexColor(value): bool {
        return typeof value === "string" && /^#[0-9a-f]{6}$/i.test(value);
    }

    function reject(message: string): void {
        colors = {};
        mode = "";
        seed = "";
        available = false;
        errorMessage = message;
    }

    function load(): void {
        let document;

        try {
            document = JSON.parse(paletteFile.text());
        } catch (error) {
            reject(`Malformed palette JSON: ${error}`);
            return;
        }

        if (document === null || typeof document !== "object" || Array.isArray(document)) {
            reject("Palette root must be a JSON object");
            return;
        }

        if (document.version !== 1) {
            reject(`Unsupported palette version: ${document.version}`);
            return;
        }

        if (document.mode !== "dark" && document.mode !== "light") {
            reject(`Unsupported palette mode: ${document.mode || "missing"}`);
            return;
        }

        for (const role of requiredRoles) {
            if (!isHexColor(document.colors?.[role])) {
                reject(`Invalid or missing color role: ${role}`);
                return;
            }
        }

        colors = document.colors;
        mode = document.mode;
        seed = typeof document.seed === "string" ? document.seed : "";
        available = true;
        errorMessage = "";
    }

    function reload(): void {
        paletteFile.reload();
    }

    IpcHandler {
        target: "palette"

        function reload(): void {
            root.reload();
        }

        function status(): string {
            return root.available ? `generated (${root.mode})` : `fallback: ${root.errorMessage}`;
        }

        function path(): string {
            return root.path;
        }
    }

    FileView {
        id: paletteFile

        path: root.path
        preload: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: root.load()
        onLoadFailed: error => {
            root.reject(FileViewError.toString(error));
        }
    }
}
