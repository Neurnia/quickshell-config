pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property var entries: []
    property bool active: false
    property int session: 0
    property var pasteTarget: null
    readonly property var terminalApps: DesktopEntries.applications.values.filter(
        app => app.categories.includes("TerminalEmulator"))
    property int generation: 0
    property var requestedEntry: null
    property string imageSource: ""
    property string previewText: ""
    property string previewError: ""
    property string listError: ""
    property bool textTruncated: false
    property bool previewLoading: false
    readonly property bool loading: listReader.running
    readonly property bool restoring: restorer.running

    signal restored

    function open(): void {
        pasteDelay.stop();
        session++;
        pasteTarget = Hyprland.activeToplevel;
        active = true;
        refresh();
    }

    function close(): void {
        pasteDelay.stop();
        active = false;
        entries = [];
        preview(null);
    }

    function notifyError(message: string): void {
        Quickshell.execDetached(["notify-send", "--urgency=critical", "Clipboard history", message]);
    }

    function refresh(): void {
        if (listReader.running)
            return;
        listError = "";
        listReader.running = true;
    }

    function parseEntries(output: string): var {
        const result = [];
        for (const line of output.replace(/\0/g, "").split("\n")) {
            const match = /^(\d+)\t(.*)$/.exec(line);
            if (!match)
                continue;
            const label = match[2];
            const binary = label.startsWith("[[ binary data ");
            const metadata = /^\[\[ binary data \S+ \S+ (\S+)/.exec(label);
            const format = metadata ? metadata[1].toLowerCase() : "";
            const mimeTypes = {
                png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg",
                gif: "image/gif", webp: "image/webp", bmp: "image/bmp",
                svg: "image/svg+xml", tiff: "image/tiff", avif: "image/avif"
            };
            result.push({ id: match[1], label, binary, format, mime: mimeTypes[format] || "" });
        }
        return result;
    }

    function decodePreviewText(data, utf8Text: string): string {
        if (utf8Text === "")
            return utf8Text;
        const bytes = new Uint8Array(data);
        if (bytes.length % 2 !== 0)
            return utf8Text;

        const hasBom = bytes[0] === 0xff && bytes[1] === 0xfe;
        let prefix = "";
        for (let i = 0; i < Math.min(bytes.length, 16); i += 2)
            prefix += String.fromCharCode(bytes[i] | (bytes[i + 1] << 8));

        // Browser URL/title payloads use UTF-16LE, often without a BOM.
        // Recognize their URL prefix instead of guessing all text encodings.
        if (!hasBom && !/^https?:\/\//.test(prefix))
            return utf8Text;

        let text = "";
        for (let i = hasBom ? 2 : 0; i < bytes.length; i += 2)
            text += String.fromCharCode(bytes[i] | (bytes[i + 1] << 8));
        return text;
    }

    function preview(entry): void {
        generation++;
        requestedEntry = entry;
        imageSource = "";
        previewText = "";
        previewError = "";
        textTruncated = false;
        previewLoading = entry !== null && (!entry.binary || entry.mime !== "");
        previewDelay.restart();
    }

    function loadPreview(): void {
        if (!active || !requestedEntry || !previewLoading || previewReader.running)
            return;
        previewReader.entry = requestedEntry;
        previewReader.generation = generation;
        // Keep image bytes out of text decoding and avoid persistent preview files.
        previewReader.command = requestedEntry.mime
            ? ["bash", "-o", "pipefail", "-c", 'cliphist decode "$1" | base64 -w0', "clipboard-preview", requestedEntry.id]
            : ["cliphist", "decode", requestedEntry.id];
        previewReader.running = true;
    }

    function restore(entry): void {
        if (!entry || restoring)
            return;
        // Decode completely before taking clipboard ownership, including stale IDs.
        restorer.command = ["bash", "-c", `set -euo pipefail
file=$(mktemp)
trap 'rm -f -- "$file"' EXIT
cliphist decode "$1" > "$file"
wl-copy < "$file"`, "clipboard-restore", entry.id];
        restorer.session = session;
        restorer.running = true;
    }

    function paste(): void {
        if (!pasteTarget || !Hyprland.toplevels.values.includes(pasteTarget)) {
            notifyError("The destination window is no longer available.");
            return;
        }
        const window = `"address:0x${pasteTarget.address}"`;
        const app = DesktopEntries.heuristicLookup(pasteTarget.lastIpcObject.class);
        const modifiers = terminalApps.includes(app) ? "CTRL + SHIFT" : "CTRL";
        paster.command = ["hyprctl", "eval",
            `hl.dispatch(hl.dsp.focus({window = ${window}}))
hl.dispatch(hl.dsp.send_shortcut({mods = "${modifiers}", key = "V", window = ${window}}))`];
        paster.running = true;
    }

    Timer {
        id: pasteDelay
        // Let the layer surface unmap and release its exclusive keyboard focus.
        interval: 100
        onTriggered: root.paste()
    }

    Process {
        id: paster
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (code !== 0 || status !== 0)
                root.notifyError(`Could not paste into the destination window (exit ${code}).`);
        }
    }

    Timer {
        id: previewDelay
        interval: 70
        onTriggered: root.loadPreview()
    }

    Process {
        id: listReader
        command: ["cliphist", "list"]
        stdout: StdioCollector { id: listOutput }
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (!root.active)
                return;
            if (code !== 0 || status !== 0) {
                root.listError = `Could not read clipboard history (exit ${code}).`;
                root.entries = [];
                root.notifyError(root.listError);
                return;
            }
            root.entries = root.parseEntries(listOutput.text);
        }
    }

    Process {
        id: previewReader
        property var entry: null
        property int generation: -1
        stdout: StdioCollector { id: previewOutput }
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (generation !== root.generation) {
                Qt.callLater(() => root.loadPreview());
                return;
            }
            root.previewLoading = false;
            if (code !== 0 || status !== 0) {
                root.previewError = `Could not load this entry (exit ${code}).`;
                root.notifyError(root.previewError);
            } else if (entry.mime) {
                root.imageSource = `data:${entry.mime};base64,${previewOutput.text.trim()}`;
            } else {
                const text = root.decodePreviewText(previewOutput.data, previewOutput.text);
                root.textTruncated = text.length > 32768;
                root.previewText = text.slice(0, 32768);
            }
        }
    }

    Process {
        id: restorer
        property int session: -1
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (session !== root.session || !root.active)
                return;
            if (code === 0 && status === 0) {
                root.restored();
                pasteDelay.restart();
            } else
                root.notifyError(`Could not restore this entry (exit ${code}).`);
        }
    }
}
