pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var device: null
    property string mode: "waiting"
    property string message: ""
    property string code: ""
    property string errorMessage: ""
    property string outputBuffer: ""
    property int stdoutLength: 0
    property int stderrLength: 0
    readonly property bool running: pairingRunner.running

    signal completed

    function begin(target): void {
        if (!target || running)
            return;

        device = target;
        mode = "waiting";
        message = "Waiting for the device to respond…";
        code = "";
        errorMessage = "";
        outputBuffer = "";
        stdoutLength = 0;
        stderrLength = 0;
        pairingRunner.exec(["bluetoothctl", "--agent", "KeyboardDisplay", "--timeout", "90", "pair", target.address]);
    }

    function cancel(): void {
        if (running)
            pairingRunner.signal(15);
        if (device?.pairing)
            device.cancelPair();
        clear();
    }

    function clear(): void {
        device = null;
        mode = "waiting";
        message = "";
        code = "";
        errorMessage = "";
        outputBuffer = "";
        stdoutLength = 0;
        stderrLength = 0;
    }

    function answer(value: string): void {
        if (!running || !value.trim())
            return;
        pairingRunner.write(value.trim() + "\n");
        outputBuffer = "";
        mode = "waiting";
        message = "Waiting for pairing to finish…";
    }

    function cleanOutput(output: string): string {
        return output.replace(/\x1b\[[0-9;?]*[ -/]*[@-~]/g, "").replace(/\r/g, "");
    }

    function handleOutput(output: string): void {
        outputBuffer = (outputBuffer + cleanOutput(output)).slice(-600);
        const cleaned = outputBuffer;
        let match = cleaned.match(/Confirm passkey\s+([0-9]+)/i);
        if (match) {
            mode = "confirm";
            code = match[1];
            message = "Check that this code matches the device.";
            outputBuffer = "";
            return;
        }

        match = cleaned.match(/Passkey:\s*([0-9]+)/i);
        if (match) {
            code = match[1];
            message = "Enter this passkey on the device.";
        }

        if (/Enter (?:PIN code|passkey)/i.test(cleaned)) {
            mode = "input";
            message = "Enter the PIN or passkey shown by the device.";
            outputBuffer = "";
        }

        if (/Pairing successful/i.test(cleaned)) {
            mode = "waiting";
            message = "Pairing complete. Connecting…";
            outputBuffer = "";
        }

        const failure = cleaned.match(/Failed to pair:\s*(.+)/i)
            || cleaned.match(/AuthenticationFailed/i)
            || cleaned.match(/AuthenticationCanceled/i)
            || cleaned.match(/ConnectionAttemptFailed/i);
        if (failure) {
            mode = "failed";
            errorMessage = failure[1] || "The device rejected the pairing request.";
            outputBuffer = "";
        }
    }

    Process {
        id: pairingRunner

        stdinEnabled: true

        stdout: StdioCollector {
            waitForEnd: false
            onDataChanged: {
                const chunk = text.slice(root.stdoutLength);
                root.stdoutLength = text.length;
                root.handleOutput(chunk);
            }
        }

        stderr: StdioCollector {
            waitForEnd: false
            onDataChanged: {
                const chunk = text.slice(root.stderrLength);
                root.stderrLength = text.length;
                root.handleOutput(chunk);
            }
        }

        onExited: exitCode => {
            if (!root.device)
                return;

            if (exitCode === 0) {
                const pairedDevice = root.device;
                root.clear();
                pairedDevice.trusted = true;
                pairedDevice.connect();
                root.completed();
            } else if (!root.errorMessage) {
                root.mode = "failed";
                root.errorMessage = "Pairing was cancelled or could not be completed.";
            }
        }
    }
}
