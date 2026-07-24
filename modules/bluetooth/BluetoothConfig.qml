pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.components
import qs.services

OverlayDialog {
    id: root

    property var selectedDevice: null
    property string pairingMode: "waiting"
    property string pairingMessage: ""
    property string pairingCode: ""
    property string pairingError: ""
    property string pairingOutputBuffer: ""
    property int pairingStdoutLength: 0
    property int pairingStderrLength: 0
    property var unpairCandidate: null

    layerNamespace: "quickshell:bluetooth-config"
    onDismissRequested: root.close()
    onEscapePressed: {
        if (root.selectedDevice)
            root.showDeviceList();
        else
            root.close();
    }

    function open(): void {
        shown = true;
        BluetoothState.startDiscovery();
        Qt.callLater(() => deviceList.positionViewAtBeginning());
    }

    function close(): void {
        shown = false;
        unpairCandidate = null;
        unpairReset.stop();
        cancelPairing();
        BluetoothState.stopDiscovery();
    }

    function beginPairing(device): void {
        if (!device || pairingRunner.running)
            return;

        selectedDevice = device;
        pairingMode = "waiting";
        pairingMessage = "Waiting for the device to respond…";
        pairingCode = "";
        pairingError = "";
        pairingOutputBuffer = "";
        pairingStdoutLength = 0;
        pairingStderrLength = 0;
        pairingInput.text = "";
        pairingRunner.exec(["bluetoothctl", "--agent", "KeyboardDisplay", "--timeout", "90", "pair", device.address]);
        Qt.callLater(() => root.takeFocus());
    }

    function showDeviceList(): void {
        cancelPairing();
        selectedDevice = null;
        pairingMode = "waiting";
        pairingMessage = "";
        pairingCode = "";
        pairingError = "";
        pairingInput.text = "";
        takeFocus();
    }

    function cancelPairing(): void {
        if (pairingRunner.running)
            pairingRunner.signal(15);
        if (selectedDevice?.pairing)
            selectedDevice.cancelPair();
    }

    function cleanPairingOutput(output: string): string {
        return output.replace(/\x1b\[[0-9;?]*[ -/]*[@-~]/g, "").replace(/\r/g, "");
    }

    function handlePairingOutput(output: string): void {
        pairingOutputBuffer = (pairingOutputBuffer + cleanPairingOutput(output)).slice(-600);
        const cleaned = pairingOutputBuffer;
        let match = cleaned.match(/Confirm passkey\s+([0-9]+)/i);
        if (match) {
            pairingMode = "confirm";
            pairingCode = match[1];
            pairingMessage = "Check that this code matches the one shown on the device.";
            pairingOutputBuffer = "";
            return;
        }

        match = cleaned.match(/Passkey:\s*([0-9]+)/i);
        if (match) {
            pairingCode = match[1];
            pairingMessage = "Enter this passkey on the Bluetooth device.";
        }

        if (/Enter (?:PIN code|passkey)/i.test(cleaned)) {
            pairingMode = "input";
            pairingMessage = "Enter the PIN or passkey shown by the device.";
            pairingOutputBuffer = "";
            Qt.callLater(() => pairingInput.forceActiveFocus());
        }

        if (/Pairing successful/i.test(cleaned)) {
            pairingMode = "waiting";
            pairingMessage = "Pairing complete. Connecting…";
            pairingOutputBuffer = "";
        }

        const failure = cleaned.match(/Failed to pair:\s*(.+)/i) || cleaned.match(/AuthenticationFailed/i) || cleaned.match(/AuthenticationCanceled/i) || cleaned.match(/ConnectionAttemptFailed/i);
        if (failure) {
            pairingMode = "failed";
            pairingError = failure[1] || "The device rejected the pairing request.";
            pairingOutputBuffer = "";
        }
    }

    function answerPairing(answer: string): void {
        if (!pairingRunner.running)
            return;
        pairingRunner.write(answer + "\n");
        pairingOutputBuffer = "";
        pairingMode = "waiting";
        pairingMessage = "Waiting for the device to finish pairing…";
        pairingInput.text = "";
        takeFocus();
    }

    function submitPairingInput(): void {
        const answer = pairingInput.text.trim();
        if (answer !== "")
            answerPairing(answer);
    }

    function requestUnpair(device): void {
        if (!device || BluetoothState.deviceBusy(device))
            return;

        if (unpairCandidate === device) {
            unpairCandidate = null;
            unpairReset.stop();
            BluetoothState.forgetDevice(device);
            return;
        }

        unpairCandidate = device;
        unpairReset.restart();
    }

    IpcHandler {
        target: "bluetoothConfig"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            if (root.shown)
                root.close();
            else
                root.open();
        }
    }

    Process {
        id: pairingRunner

        stdinEnabled: true

        stdout: StdioCollector {
            waitForEnd: false
            onDataChanged: {
                const chunk = text.slice(root.pairingStdoutLength);
                root.pairingStdoutLength = text.length;
                root.handlePairingOutput(chunk);
            }
        }

        stderr: StdioCollector {
            waitForEnd: false
            onDataChanged: {
                const chunk = text.slice(root.pairingStderrLength);
                root.pairingStderrLength = text.length;
                root.handlePairingOutput(chunk);
            }
        }

        onExited: exitCode => {
            if (!root.selectedDevice)
                return;

            if (exitCode === 0) {
                root.selectedDevice.trusted = true;
                root.selectedDevice.connect();
                root.showDeviceList();
            } else if (!root.pairingError && root.shown) {
                root.pairingMode = "failed";
                root.pairingError = "Pairing was cancelled or could not be completed.";
            }
        }
    }

    Timer {
        id: unpairReset

        interval: 4000
        onTriggered: root.unpairCandidate = null
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Item {
            width: parent.width
            height: 50

            Column {
                anchors.left: parent.left
                anchors.right: headerActions.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                AppText {
                    width: parent.width
                    text: "\uf293  Bluetooth configuration"
                    color: Colors.palette.m3onSurface
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                AppText {
                    width: parent.width
                    text: {
                        if (!BluetoothState.available)
                            return "󰂲  No Bluetooth adapter";
                        if (!BluetoothState.enabled)
                            return "󰂲  Bluetooth is off";
                        if (BluetoothState.connectedCount === 0)
                            return "\uf293  No connected devices";
                        return BluetoothState.connectedCount === 1 ? "\uf00c  1 connected device" : `\uf00c  ${BluetoothState.connectedCount} connected devices`;
                    }
                    color: Colors.palette.m3onSurfaceVariant
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            Row {
                id: headerActions

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                ActionCapsule {
                    id: scanButton

                    actionEnabled: BluetoothState.enabled
                    anchors.verticalCenter: undefined
                    width: 82
                    height: 30
                    radius: height * 0.2
                    content.text: BluetoothState.discovering ? "\uf110  Scan" : "\uf2f1  Scan"
                    color: BluetoothState.discovering ? Colors.palette.m3secondary : Colors.palette.m3surfaceVariant
                    content.color: BluetoothState.discovering ? Colors.palette.m3onSecondary : Colors.palette.m3onSurface
                    onClicked: {
                        if (BluetoothState.discovering)
                            BluetoothState.stopDiscovery();
                        else
                            BluetoothState.startDiscovery();
                    }
                }

                ActionCapsule {
                    id: closeButton

                    anchors.verticalCenter: undefined
                    width: 30
                    height: 30
                    radius: height * 0.2
                    content.text: "\uf00d"
                    color: Colors.palette.m3surfaceVariant
                    onClicked: root.close()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Colors.palette.m3outlineVariant
            opacity: 0.35
        }

        ListView {
            id: deviceList

            width: parent.width
            height: 405
            spacing: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: BluetoothState.enabled ? BluetoothState.displayItems : []
            visible: root.selectedDevice === null

            delegate: Item {
                id: itemDelegate

                required property var modelData

                width: deviceList.width
                height: modelData.kind === "header" ? 24 : 52

                AppText {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: itemDelegate.modelData.kind === "header"
                    text: itemDelegate.modelData.kind === "header" ? `${itemDelegate.modelData.icon}  ${itemDelegate.modelData.title}` : ""
                    color: Colors.palette.m3onSurface
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                AppText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: itemDelegate.modelData.kind === "header"
                    text: itemDelegate.modelData.kind === "header" ? itemDelegate.modelData.count : ""
                    color: Colors.palette.m3onSurfaceVariant
                    font.pixelSize: 9
                }

                ActionCapsule {
                    id: deviceRow

                    readonly property var device: itemDelegate.modelData.kind === "device" ? itemDelegate.modelData.device : null

                    actionEnabled: !BluetoothState.deviceBusy(device)
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 50
                    radius: height * 0.16
                    visible: itemDelegate.modelData.kind === "device"
                    content.text: ""
                    color: device?.connected ? Colors.palette.m3secondary : Colors.palette.m3surfaceVariant
                    onClicked: {
                        root.unpairCandidate = null;
                        if (BluetoothState.isKnown(device))
                            BluetoothState.toggleDevice(device);
                        else
                            root.beginPairing(device);
                    }

                    AppText {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: BluetoothState.deviceIcon(deviceRow.device)
                        color: deviceRow.device?.connected ? Colors.palette.m3onSecondary : Colors.palette.m3onSurface
                        font.pixelSize: 16
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 42
                        anchors.right: deviceActions.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        AppText {
                            width: parent.width
                            text: BluetoothState.deviceName(deviceRow.device)
                            color: deviceRow.device?.connected ? Colors.palette.m3onSecondary : Colors.palette.m3onSurface
                            font.pixelSize: 11
                            font.weight: deviceRow.device?.connected ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }

                        AppText {
                            width: parent.width
                            text: {
                                if (root.unpairCandidate === deviceRow.device)
                                    return "Click the check to unpair";
                                const status = BluetoothState.deviceStatus(deviceRow.device);
                                if (deviceRow.device?.batteryAvailable)
                                    return `${status}  ·  \uf240 ${Math.round(deviceRow.device.battery * 100)}%`;
                                return status;
                            }
                            color: deviceRow.device?.connected ? Colors.palette.m3onSecondary : Colors.palette.m3onSurfaceVariant
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    Row {
                        id: deviceActions

                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        height: 28
                        spacing: 4

                        ActionCapsule {
                            id: connectionButton

                            actionEnabled: !BluetoothState.deviceBusy(deviceRow.device)
                            anchors.verticalCenter: undefined
                            width: 28
                            height: 28
                            radius: height * 0.22
                            content.text: {
                                if (BluetoothState.deviceBusy(deviceRow.device))
                                    return "\uf110";
                                if (deviceRow.device?.connected)
                                    return "\uf127";
                                return "\uf0c1";
                            }
                            color: "transparent"
                            content.color: deviceRow.device?.connected ? Colors.palette.m3onSecondary : Colors.palette.m3onSurfaceVariant
                            onClicked: {
                                root.unpairCandidate = null;
                                if (BluetoothState.isKnown(deviceRow.device))
                                    BluetoothState.toggleDevice(deviceRow.device);
                                else
                                    root.beginPairing(deviceRow.device);
                            }
                        }

                        ActionCapsule {
                            id: unpairButton

                            readonly property bool confirming: root.unpairCandidate === deviceRow.device

                            actionEnabled: !BluetoothState.deviceBusy(deviceRow.device)
                            anchors.verticalCenter: undefined
                            width: visible ? 28 : 0
                            height: 28
                            visible: BluetoothState.isKnown(deviceRow.device)
                            radius: height * 0.22
                            content.text: confirming ? "\uf00c" : "\uf1f8"
                            color: confirming ? Colors.palette.m3error : "transparent"
                            content.color: confirming ? Colors.palette.m3onError : (deviceRow.device?.connected ? Colors.palette.m3onSecondary : Colors.palette.m3onSurfaceVariant)
                            onClicked: root.requestUnpair(deviceRow.device)
                        }
                    }
                }
            }

            AppText {
                anchors.centerIn: parent
                width: parent.width - 40
                visible: deviceList.count === 0
                text: {
                    if (!BluetoothState.available)
                        return "󰂲  No Bluetooth adapter detected";
                    if (!BluetoothState.enabled)
                        return "\uf293  Turn on Bluetooth from the status panel";
                    if (BluetoothState.discovering)
                        return "\uf110  Looking for nearby devices…";
                    return "\uf293  No Bluetooth devices found";
                }
                color: Colors.palette.m3onSurfaceVariant
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }

        Item {
            width: parent.width
            height: 405
            visible: root.selectedDevice !== null

            Column {
                anchors.centerIn: parent
                width: 360
                spacing: 10

                AppText {
                    width: parent.width
                    text: BluetoothState.deviceIcon(root.selectedDevice)
                    color: Colors.palette.m3onSurface
                    font.pixelSize: 30
                    horizontalAlignment: Text.AlignHCenter
                }

                AppText {
                    width: parent.width
                    text: root.selectedDevice ? `Pair with ${BluetoothState.deviceName(root.selectedDevice)}` : ""
                    color: Colors.palette.m3onSurface
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                AppText {
                    width: parent.width
                    text: root.pairingError || root.pairingMessage
                    color: root.pairingError ? Colors.palette.m3error : Colors.palette.m3onSurfaceVariant
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                AppText {
                    width: parent.width
                    height: root.pairingCode ? 52 : 0
                    visible: root.pairingCode !== ""
                    text: root.pairingCode
                    color: Colors.palette.m3onSurface
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                    font.letterSpacing: 3
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: parent.width
                    height: root.pairingMode === "input" ? 42 : 0
                    visible: root.pairingMode === "input"
                    radius: 8
                    color: Colors.palette.m3surfaceVariant
                    border.width: 1
                    border.color: pairingInput.activeFocus ? Colors.palette.m3outline : "transparent"

                    TextInput {
                        id: pairingInput

                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.palette.m3onSurface
                        selectionColor: Colors.palette.m3secondary
                        selectedTextColor: Colors.palette.m3onSecondary
                        font.family: Typography.fontFamily
                        font.pixelSize: 11
                        inputMethodHints: Qt.ImhDigitsOnly
                        selectByMouse: true
                        clip: true
                        onAccepted: root.submitPairingInput()
                    }
                }

                Item {
                    width: 1
                    height: 8
                }

                Row {
                    width: parent.width
                    height: 34
                    spacing: 8

                    ActionCapsule {
                        id: pairingBackButton

                        anchors.verticalCenter: undefined
                        width: root.pairingMode === "confirm" ? (parent.width - parent.spacing * 2) / 3 : root.pairingMode === "input" ? (parent.width - parent.spacing) / 2 : parent.width
                        height: parent.height
                        radius: height * 0.2
                        content.text: "\uf060  Back"
                        color: Colors.palette.m3surfaceVariant
                        onClicked: root.showDeviceList()
                    }

                    ActionCapsule {
                        id: rejectPairingButton

                        anchors.verticalCenter: undefined
                        width: (parent.width - parent.spacing * 2) / 3
                        height: parent.height
                        visible: root.pairingMode === "confirm"
                        radius: height * 0.2
                        content.text: "\uf00d  No"
                        color: Colors.palette.m3surfaceVariant
                        onClicked: {
                            root.answerPairing("no");
                            root.showDeviceList();
                        }
                    }

                    ActionCapsule {
                        id: acceptPairingButton

                        readonly property bool acceptable: root.pairingMode === "confirm" || (root.pairingMode === "input" && pairingInput.text.trim() !== "")

                        actionEnabled: acceptable
                        anchors.verticalCenter: undefined
                        width: root.pairingMode === "confirm" ? (parent.width - parent.spacing * 2) / 3 : (parent.width - parent.spacing) / 2
                        height: parent.height
                        visible: root.pairingMode === "confirm" || root.pairingMode === "input"
                        radius: height * 0.2
                        content.text: root.pairingMode === "confirm" ? "\uf00c  Yes" : "\uf00c  Pair"
                        color: acceptable ? Colors.palette.m3secondary : Colors.palette.m3surfaceVariant
                        content.color: acceptable ? Colors.palette.m3onSecondary : Colors.palette.m3onSurfaceVariant
                        onClicked: {
                            if (root.pairingMode === "confirm")
                                root.answerPairing("yes");
                            else
                                root.submitPairingInput();
                        }
                    }
                }
            }
        }
    }
}
