pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.services

PanelWindow {
    id: root

    property bool shown: false
    property var selectedDevice: null
    property string pairingMode: "waiting"
    property string pairingMessage: ""
    property string pairingCode: ""
    property string pairingError: ""
    property string pairingOutputBuffer: ""
    property int pairingStdoutLength: 0
    property int pairingStderrLength: 0
    property var unpairCandidate: null

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    visible: shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell:bluetooth-config"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function open(): void {
        shown = true;
        focusScope.forceActiveFocus();
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
        Qt.callLater(() => focusScope.forceActiveFocus());
    }

    function showDeviceList(): void {
        cancelPairing();
        selectedDevice = null;
        pairingMode = "waiting";
        pairingMessage = "";
        pairingCode = "";
        pairingError = "";
        pairingInput.text = "";
        focusScope.forceActiveFocus();
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

        const failure = cleaned.match(/Failed to pair:\s*(.+)/i)
            || cleaned.match(/AuthenticationFailed/i)
            || cleaned.match(/AuthenticationCanceled/i)
            || cleaned.match(/ConnectionAttemptFailed/i);
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
        focusScope.forceActiveFocus();
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

        onExited: (exitCode, exitStatus) => {
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

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: root.shown

        Keys.onEscapePressed: event => {
            if (root.selectedDevice)
                root.showDeviceList();
            else
                root.close();
            event.accepted = true;
        }

        Rectangle {
            anchors.fill: parent
            color: "#B8000000"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: root.close()
            }
        }

        Capsule {
            id: card

            anchors.centerIn: parent
            width: 440
            height: 500
            radius: 16
            color: Colors.palette.m3surfaceContainerLowest
            border.color: Colors.palette.m3outlineVariant
            content.text: ""

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
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

                        Capsule {
                            id: scanButton

                            anchors.verticalCenter: undefined
                            width: 82
                            height: 30
                            radius: height * 0.2
                            content.text: BluetoothState.discovering ? "\uf110  Scan" : "\uf2f1  Scan"
                            color: BluetoothState.discovering ? Colors.palette.m3secondary : Colors.palette.m3surfaceVariant
                            content.color: BluetoothState.discovering ? Colors.palette.m3onSecondary : Colors.palette.m3onSurface
                            border.color: scanHover.hovered && BluetoothState.enabled ? Colors.palette.m3outline : "transparent"

                            HoverHandler {
                                id: scanHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: BluetoothState.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (BluetoothState.discovering)
                                        BluetoothState.stopDiscovery();
                                    else
                                        BluetoothState.startDiscovery();
                                }
                            }
                        }

                        Capsule {
                            id: closeButton

                            anchors.verticalCenter: undefined
                            width: 30
                            height: 30
                            radius: height * 0.2
                            content.text: "\uf00d"
                            color: Colors.palette.m3surfaceVariant
                            border.color: closeHover.hovered ? Colors.palette.m3outline : "transparent"

                            HoverHandler {
                                id: closeHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.close()
                            }
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

                        Capsule {
                            id: deviceRow

                            readonly property var device: itemDelegate.modelData.kind === "device" ? itemDelegate.modelData.device : null

                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 50
                            radius: height * 0.16
                            visible: itemDelegate.modelData.kind === "device"
                            content.text: ""
                            color: device?.connected ? Colors.palette.m3secondary : Colors.palette.m3surfaceVariant
                            border.color: deviceHover.hovered && !BluetoothState.deviceBusy(device) ? Colors.palette.m3outline : "transparent"

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

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: !BluetoothState.deviceBusy(deviceRow.device) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    root.unpairCandidate = null;
                                    if (BluetoothState.isKnown(deviceRow.device))
                                        BluetoothState.toggleDevice(deviceRow.device);
                                    else
                                        root.beginPairing(deviceRow.device);
                                }
                            }

                            Row {
                                id: deviceActions

                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                height: 28
                                spacing: 4

                                Capsule {
                                    id: connectionButton

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
                                    border.color: connectionHover.hovered && !BluetoothState.deviceBusy(deviceRow.device) ? Colors.palette.m3outline : "transparent"

                                    HoverHandler {
                                        id: connectionHover
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton
                                        cursorShape: !BluetoothState.deviceBusy(deviceRow.device) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            root.unpairCandidate = null;
                                            if (BluetoothState.isKnown(deviceRow.device))
                                                BluetoothState.toggleDevice(deviceRow.device);
                                            else
                                                root.beginPairing(deviceRow.device);
                                        }
                                    }
                                }

                                Capsule {
                                    id: unpairButton

                                    readonly property bool confirming: root.unpairCandidate === deviceRow.device

                                    anchors.verticalCenter: undefined
                                    width: visible ? 28 : 0
                                    height: 28
                                    visible: BluetoothState.isKnown(deviceRow.device)
                                    radius: height * 0.22
                                    content.text: confirming ? "\uf00c" : "\uf1f8"
                                    color: confirming ? Colors.palette.m3error : "transparent"
                                    content.color: confirming ? Colors.palette.m3onError : (deviceRow.device?.connected ? Colors.palette.m3onSecondary : Colors.palette.m3onSurfaceVariant)
                                    border.color: unpairHover.hovered && !BluetoothState.deviceBusy(deviceRow.device) ? Colors.palette.m3outline : "transparent"

                                    HoverHandler {
                                        id: unpairHover
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton
                                        cursorShape: !BluetoothState.deviceBusy(deviceRow.device) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.requestUnpair(deviceRow.device)
                                    }
                                }
                            }

                            HoverHandler {
                                id: deviceHover
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

                            Capsule {
                                id: pairingBackButton

                                anchors.verticalCenter: undefined
                                width: root.pairingMode === "confirm" ? (parent.width - parent.spacing * 2) / 3 : root.pairingMode === "input" ? (parent.width - parent.spacing) / 2 : parent.width
                                height: parent.height
                                radius: height * 0.2
                                content.text: "\uf060  Back"
                                color: Colors.palette.m3surfaceVariant
                                border.color: pairingBackHover.hovered ? Colors.palette.m3outline : "transparent"

                                HoverHandler {
                                    id: pairingBackHover
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showDeviceList()
                                }
                            }

                            Capsule {
                                id: rejectPairingButton

                                anchors.verticalCenter: undefined
                                width: (parent.width - parent.spacing * 2) / 3
                                height: parent.height
                                visible: root.pairingMode === "confirm"
                                radius: height * 0.2
                                content.text: "\uf00d  No"
                                color: Colors.palette.m3surfaceVariant
                                border.color: rejectPairingHover.hovered ? Colors.palette.m3outline : "transparent"

                                HoverHandler {
                                    id: rejectPairingHover
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.answerPairing("no");
                                        root.showDeviceList();
                                    }
                                }
                            }

                            Capsule {
                                id: acceptPairingButton

                                readonly property bool acceptable: root.pairingMode === "confirm" || (root.pairingMode === "input" && pairingInput.text.trim() !== "")

                                anchors.verticalCenter: undefined
                                width: root.pairingMode === "confirm" ? (parent.width - parent.spacing * 2) / 3 : (parent.width - parent.spacing) / 2
                                height: parent.height
                                visible: root.pairingMode === "confirm" || root.pairingMode === "input"
                                radius: height * 0.2
                                content.text: root.pairingMode === "confirm" ? "\uf00c  Yes" : "\uf00c  Pair"
                                color: acceptable ? Colors.palette.m3secondary : Colors.palette.m3surfaceVariant
                                content.color: acceptable ? Colors.palette.m3onSecondary : Colors.palette.m3onSurfaceVariant
                                border.color: acceptPairingHover.hovered && acceptable ? Colors.palette.m3outline : "transparent"

                                HoverHandler {
                                    id: acceptPairingHover
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: acceptPairingButton.acceptable ? Qt.PointingHandCursor : Qt.ArrowCursor
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
        }
    }
}
