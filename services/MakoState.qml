pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool doNotDisturb: false
    property var history: []
    property bool actionRunning: false

    readonly property int historyLimit: 10

    function cleanText(value): string {
        return String(value ?? "")
            .replace(/<[^>]*>/g, " ")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"")
            .replace(/&#39;|&apos;/g, "'")
            .replace(/\s+/g, " ")
            .trim();
    }

    function urgencyLevel(value): int {
        if (value === "critical" || Number(value) >= 2)
            return 2;
        if (value === "low" || Number(value) === 0)
            return 0;
        return 1;
    }

    function parseHistory(output: string): void {
        try {
            const entries = JSON.parse(output || "[]");
            history = entries.slice(0, historyLimit).map(entry => ({
                id: entry.id ?? 0,
                appName: cleanText(entry.app_name) || "Unknown application",
                summary: cleanText(entry.summary) || "Notification",
                body: cleanText(entry.body),
                urgency: urgencyLevel(entry.urgency)
            }));
        } catch (error) {
            history = [];
        }
    }

    function refresh(): void {
        if (!modeReader.running)
            modeReader.running = true;
        if (!historyReader.running)
            historyReader.running = true;
    }

    function toggleDoNotDisturb(): void {
        runAction(["makoctl", "mode", "-t", "do-not-disturb"]);
    }

    function dismissAll(): void {
        runAction(["makoctl", "dismiss", "--all"]);
    }

    function runAction(command): void {
        if (actionRunning)
            return;

        actionRunning = true;
        actionRunner.exec(command);
    }

    Process {
        id: modeReader

        command: ["makoctl", "mode"]
        stdout: StdioCollector {
            onStreamFinished: {
                const modes = text.trim().split(/\s+/);
                root.doNotDisturb = modes.indexOf("do-not-disturb") !== -1;
            }
        }
    }

    Process {
        id: historyReader

        command: ["makoctl", "history", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parseHistory(text.trim())
        }
    }

    Process {
        id: actionRunner

        onExited: {
            root.actionRunning = false;
            refreshAfterAction.restart();
        }
    }

    Timer {
        id: refreshAfterAction

        interval: 100
        onTriggered: root.refresh()
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!modeReader.running)
                modeReader.running = true;
        }
    }
}
