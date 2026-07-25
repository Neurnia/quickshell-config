pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.components
import qs.services

OverlayDialog {
    id: root

    property string currentPage: "wifi"
    property string query: ""
    property var selectedNetwork: null
    readonly property var selectedDevice: BluetoothPairing.device
    property string passwordText: ""
    property bool passwordVisible: false
    property string errorMessage: ""
    readonly property bool inDetail: selectedNetwork !== null || selectedDevice !== null
    readonly property bool refreshing: currentPage === "wifi"
        ? Network.busy && Network.actionPurpose === "scan"
        : BluetoothState.discovering

    layerNamespace: "quickshell:connectivity-config"
    cardWidth: 440
    cardHeight: 500
    onDismissRequested: close()
    onEscapePressed: {
        if (query !== "" && !inDetail) {
            query = "";
            searchInput.text = "";
        } else if (inDetail) {
            showList();
        } else {
            close();
        }
    }
    onKeyPressed: event => {
        if (event.key === Qt.Key_Slash && !inDetail) {
            searchInput.forceActiveFocus();
            event.accepted = true;
        }
    }

    function open(page: string): void {
        switchPage(page === "bluetooth" ? "bluetooth" : "wifi");
        shown = true;
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function close(): void {
        shown = false;
        showList();
        BluetoothState.stopDiscovery();
        if (Network.actionPurpose === "credentials")
            Network.cancelCredentialConnection();
    }

    function switchPage(page: string): void {
        if (currentPage === "bluetooth" && page !== "bluetooth")
            BluetoothState.stopDiscovery();
        currentPage = page;
        query = "";
        searchInput.text = "";
        showList();
        if (shown)
            Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function showList(): void {
        BluetoothPairing.cancel();
        selectedNetwork = null;
        passwordText = "";
        passwordVisible = false;
        errorMessage = "";
        if (shown)
            takeFocus();
    }

    function refreshCurrentPage(): void {
        if (currentPage === "wifi") {
            Network.rescan();
        } else if (!BluetoothState.discovering) {
            BluetoothState.startDiscovery();
        }
    }

    function pageStatus(): string {
        if (currentPage === "bluetooth") {
            if (!BluetoothState.available)
                return "No adapter detected";
            if (!BluetoothState.enabled)
                return "Bluetooth is off";
            if (BluetoothState.connectedCount === 0)
                return "No connected devices";
            return BluetoothState.connectedCount === 1
                ? "1 connected device"
                : `${BluetoothState.connectedCount} connected devices`;
        }

        if (!Network.wifiEnabled)
            return "Wi-Fi is off";
        if (Network.connectionType === "wifi")
            return `Connected to ${Network.connectionName || "Wi-Fi"}`;
        if (Network.connectionType === "ethernet")
            return "Ethernet connected · Wi-Fi is on";
        return "Wi-Fi is on";
    }

    function filteredNetworks(): var {
        if (!Network.wifiEnabled)
            return [];
        const needle = query.trim().toLowerCase();
        if (!needle)
            return Network.networks;
        return Network.networks.filter(network => network.name.toLowerCase().indexOf(needle) !== -1);
    }

    function filteredDevices(): var {
        if (!BluetoothState.enabled)
            return [];
        const devices = [
            ...BluetoothState.connectedDevices,
            ...BluetoothState.pairedDevices,
            ...BluetoothState.availableDevices
        ];
        const needle = query.trim().toLowerCase();
        if (!needle)
            return devices;
        return devices.filter(device => {
            const name = BluetoothState.deviceName(device).toLowerCase();
            const address = (device.address || "").toLowerCase();
            return name.indexOf(needle) !== -1 || address.indexOf(needle) !== -1;
        });
    }

    function chooseNetwork(network): void {
        if (!network || network.active || Network.busy)
            return;
        errorMessage = "";
        if (network.enterprise) {
            errorMessage = "Enterprise Wi-Fi is not supported here.";
            return;
        }
        if (network.saved || !network.secured) {
            Network.connectNetwork(network);
            return;
        }
        selectedNetwork = network;
        passwordText = "";
        Qt.callLater(() => contentLoader.item?.focusInput());
    }

    function submitPassword(): void {
        if (!selectedNetwork || passwordText.length < 8 || Network.busy)
            return;
        errorMessage = "";
        Network.connectWithPassword(selectedNetwork, passwordText);
        passwordText = "";
    }

    function chooseDevice(device): void {
        if (!device || BluetoothState.deviceBusy(device))
            return;
        if (BluetoothState.isKnown(device)) {
            BluetoothState.toggleDevice(device);
            return;
        }
        BluetoothPairing.begin(device);
    }

    IpcHandler {
        target: "connectivity"
        function open(page: string): void { root.open(page); }
        function close(): void { root.close(); }
        function toggle(page: string): void {
            if (root.shown)
                root.close();
            else
                root.open(page);
        }
    }

    IpcHandler {
        target: "wifiConfig"
        function open(): void { root.open("wifi"); }
        function close(): void { root.close(); }
        function toggle(): void {
            if (root.shown)
                root.close();
            else
                root.open("wifi");
        }
    }

    IpcHandler {
        target: "bluetoothConfig"
        function open(): void { root.open("bluetooth"); }
        function close(): void { root.close(); }
        function toggle(): void {
            if (root.shown)
                root.close();
            else
                root.open("bluetooth");
        }
    }

    Connections {
        target: Network

        function onConnectionSucceeded(name: string): void {
            if (root.shown)
                root.showList();
        }

        function onConnectionFailed(name: string, message: string): void {
            if (!root.shown)
                return;
            root.errorMessage = message;
            if (root.selectedNetwork)
                Qt.callLater(() => contentLoader.item?.focusInput());
        }
    }

    Connections {
        target: BluetoothPairing

        function onCompleted(): void {
            if (root.shown)
                root.showList();
        }

        function onModeChanged(): void {
            if (root.shown && BluetoothPairing.mode === "input")
                Qt.callLater(() => contentLoader.item?.focusInput());
        }
    }

    Timer {
        interval: 15000
        running: root.shown
            && root.currentPage === "bluetooth"
            && BluetoothState.discovering
        onTriggered: BluetoothState.stopDiscovery()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Item {
            width: parent.width
            height: 38

            AppText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Connectivity"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            ActionCapsule {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                content.text: "\uf00d"
                color: Colors.palette.surfaceVariant
                onClicked: root.close()
            }
        }

        Rectangle {
            width: parent.width
            height: 38
            radius: 8
            color: Colors.palette.surfaceVariant
            border.width: 1
            border.color: Colors.palette.outlineVariant

            Rectangle {
                width: parent.width / 2
                height: parent.height
                x: root.currentPage === "bluetooth" ? 0 : width
                radius: parent.radius
                color: Colors.palette.secondary

                Behavior on x {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Item {
                width: parent.width / 2
                height: parent.height

                AppText {
                    anchors.centerIn: parent
                    text: "\uf293  Bluetooth"
                    color: root.currentPage === "bluetooth"
                        ? Colors.palette.secondaryText
                        : Colors.palette.surfaceVariantText
                    font.pixelSize: 10
                    font.weight: root.currentPage === "bluetooth"
                        ? Font.DemiBold
                        : Font.Normal
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.switchPage("bluetooth")
                }
            }

            Item {
                x: parent.width / 2
                width: parent.width / 2
                height: parent.height

                AppText {
                    anchors.centerIn: parent
                    text: `${Network.icon}  Network`
                    color: root.currentPage === "wifi"
                        ? Colors.palette.secondaryText
                        : Colors.palette.surfaceVariantText
                    font.pixelSize: 10
                    font.weight: root.currentPage === "wifi"
                        ? Font.DemiBold
                        : Font.Normal
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.switchPage("wifi")
                }
            }
        }

        Item {
            width: parent.width
            height: root.inDetail ? 0 : 42
            visible: !root.inDetail

            Column {
                anchors.left: parent.left
                anchors.right: stateSwitch.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                AppText {
                    width: parent.width
                    text: root.currentPage === "wifi" ? "Wi-Fi" : "Bluetooth"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                AppText {
                    width: parent.width
                    text: root.pageStatus()
                    color: Colors.palette.surfaceVariantText
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            ToggleSwitch {
                id: stateSwitch
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: root.currentPage === "wifi"
                    ? Network.wifiEnabled
                    : BluetoothState.enabled
                actionEnabled: root.currentPage === "wifi"
                    ? Network.available && !Network.busy
                    : BluetoothState.available
                onToggled: {
                    if (root.currentPage === "wifi")
                        Network.toggleWifi();
                    else
                        BluetoothState.toggleEnabled();
                }
            }
        }

        Row {
            width: parent.width
            height: root.inDetail ? 0 : 36
            visible: !root.inDetail
            spacing: 6

            Rectangle {
                width: parent.width - refreshButton.width - parent.spacing
                height: parent.height
                radius: 8
                color: Colors.palette.surfaceVariant
                border.width: 1
                border.color: searchInput.activeFocus
                    ? Colors.palette.outline
                    : "transparent"

                AppText {
                    anchors.left: parent.left
                    anchors.leftMargin: 11
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf002"
                    color: Colors.palette.surfaceVariantText
                    font.pixelSize: 10
                }

                TextInput {
                    id: searchInput
                    anchors.left: parent.left
                    anchors.leftMargin: 34
                    anchors.right: clearSearch.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colors.palette.surfaceText
                    selectionColor: Colors.palette.secondary
                    selectedTextColor: Colors.palette.secondaryText
                    font.family: Typography.fontFamily
                    font.pixelSize: 11
                    selectByMouse: true
                    clip: true
                    onTextChanged: root.query = text
                }

                AppText {
                    anchors.left: searchInput.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchInput.text === ""
                    text: root.currentPage === "wifi" ? "Search networks" : "Search devices"
                    color: Colors.palette.surfaceVariantText
                    font.pixelSize: 10
                }

                ActionCapsule {
                    id: clearSearch
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    visible: searchInput.text !== ""
                    content.text: "\uf00d"
                    color: "transparent"
                    onClicked: {
                        searchInput.text = "";
                        searchInput.forceActiveFocus();
                    }
                }
            }

            ActionCapsule {
                id: refreshButton
                anchors.verticalCenter: undefined
                width: 36
                height: 36
                actionEnabled: root.currentPage === "wifi"
                    ? Network.wifiEnabled && !Network.busy
                    : BluetoothState.enabled && !BluetoothState.discovering
                content.text: "\uf2f1"
                color: root.refreshing
                    ? Colors.palette.secondary
                    : Colors.palette.surfaceVariant
                content.color: root.refreshing
                    ? Colors.palette.secondaryText
                    : Colors.palette.surfaceText
                onClicked: root.refreshCurrentPage()

                RotationAnimator {
                    target: refreshButton.content
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                    running: root.refreshing
                }
            }
        }

        AppText {
            width: parent.width
            height: visible ? 28 : 0
            visible: root.errorMessage !== "" && !root.inDetail
            text: `\uf071  ${root.errorMessage}`
            color: Colors.palette.error
            font.pixelSize: 9
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
        }

        Loader {
            id: contentLoader
            width: parent.width
            height: parent.height - y
            active: root.shown
            sourceComponent: {
                if (root.selectedNetwork)
                    return wifiAuthentication;
                if (root.selectedDevice)
                    return bluetoothPairing;
                return root.currentPage === "wifi" ? wifiList : bluetoothList;
            }
        }
    }

    Component {
        id: wifiList

        Item {
            ListView {
            id: networkList
            anchors.fill: parent
            spacing: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.filteredNetworks()

            delegate: ActionCapsule {
                id: networkRow
                required property var modelData
                actionEnabled: !modelData.active && !Network.busy
                anchors.verticalCenter: undefined
                width: networkList.width
                height: 50
                content.text: ""
                color: modelData.active
                    ? Colors.palette.secondary
                    : Colors.palette.surfaceVariant
                onClicked: root.chooseNetwork(modelData)

                AppText {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: Network.signalIcon(networkRow.modelData.signal)
                    color: networkRow.modelData.active
                        ? Colors.palette.secondaryText
                        : Colors.palette.surfaceText
                    font.pixelSize: 15
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.right: signalLabel.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    AppText {
                        width: parent.width
                        text: networkRow.modelData.name
                        color: networkRow.modelData.active
                            ? Colors.palette.secondaryText
                            : Colors.palette.surfaceText
                        font.pixelSize: 11
                        font.weight: networkRow.modelData.active ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }

                    AppText {
                        width: parent.width
                        text: {
                            if (Network.connectingName === networkRow.modelData.name)
                                return "\uf110  Connecting…";
                            if (networkRow.modelData.active)
                                return "\uf00c  Connected";
                            if (networkRow.modelData.saved)
                                return "\uf084  Saved";
                            if (networkRow.modelData.enterprise)
                                return "\uf071  Enterprise";
                            return networkRow.modelData.secured ? "\uf023  Secured" : "\uf09c  Open";
                        }
                        color: networkRow.modelData.active
                            ? Colors.palette.secondaryText
                            : Colors.palette.surfaceVariantText
                        font.pixelSize: 9
                    }
                }

                AppText {
                    id: signalLabel
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${networkRow.modelData.signal}%`
                    color: networkRow.modelData.active
                        ? Colors.palette.secondaryText
                        : Colors.palette.surfaceVariantText
                    font.pixelSize: 9
                }
            }

            AppText {
                anchors.centerIn: parent
                width: parent.width - 40
                visible: networkList.count === 0
                text: {
                    if (!Network.wifiEnabled)
                        return "\uf1eb  Wi-Fi is off";
                    if (root.query)
                        return "\uf002  No matching networks";
                    if (Network.busy)
                        return "\uf110  Scanning for networks…";
                    return "󰤭  No networks found";
                }
                color: Colors.palette.surfaceVariantText
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }
            }
        }
    }

    Component {
        id: bluetoothList

        Item {
            ListView {
            id: deviceList
            anchors.fill: parent
            spacing: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.filteredDevices()

            delegate: ActionCapsule {
                id: deviceRow
                required property var modelData
                readonly property var device: modelData
                actionEnabled: !BluetoothState.deviceBusy(device)
                anchors.verticalCenter: undefined
                width: deviceList.width
                height: 50
                content.text: ""
                color: device?.connected
                    ? Colors.palette.secondary
                    : Colors.palette.surfaceVariant
                onClicked: root.chooseDevice(device)

                AppText {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: BluetoothState.deviceIcon(deviceRow.device)
                    color: deviceRow.device?.connected
                        ? Colors.palette.secondaryText
                        : Colors.palette.surfaceText
                    font.pixelSize: 15
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.right: stateIcon.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    AppText {
                        width: parent.width
                        text: BluetoothState.deviceName(deviceRow.device)
                        color: deviceRow.device?.connected
                            ? Colors.palette.secondaryText
                            : Colors.palette.surfaceText
                        font.pixelSize: 11
                        font.weight: deviceRow.device?.connected ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }

                    AppText {
                        width: parent.width
                        text: {
                            const status = BluetoothState.deviceStatus(deviceRow.device);
                            if (deviceRow.device?.batteryAvailable)
                                return `${status}  ·  \uf240 ${Math.round(deviceRow.device.battery * 100)}%`;
                            return status;
                        }
                        color: deviceRow.device?.connected
                            ? Colors.palette.secondaryText
                            : Colors.palette.surfaceVariantText
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                AppText {
                    id: stateIcon
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: BluetoothState.deviceBusy(deviceRow.device)
                        ? "\uf110"
                        : deviceRow.device?.connected
                            ? "\uf127"
                            : "\uf0c1"
                    color: deviceRow.device?.connected
                        ? Colors.palette.secondaryText
                        : Colors.palette.surfaceVariantText
                    font.pixelSize: 10
                }
            }

            AppText {
                anchors.centerIn: parent
                width: parent.width - 40
                visible: deviceList.count === 0
                text: {
                    if (!BluetoothState.available)
                        return "󰂲  No Bluetooth adapter";
                    if (!BluetoothState.enabled)
                        return "\uf293  Bluetooth is off";
                    if (root.query)
                        return "\uf002  No matching devices";
                    if (BluetoothState.discovering)
                        return "\uf110  Looking for nearby devices…";
                    return "\uf293  No devices found";
                }
                color: Colors.palette.surfaceVariantText
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }
            }
        }
    }

    Component {
        id: wifiAuthentication

        Item {
            function focusInput(): void {
                passwordInput.forceActiveFocus();
            }

            Column {
                anchors.centerIn: parent
                width: 360
                spacing: 10

                AppText {
                    width: parent.width
                    text: "\uf023"
                    font.pixelSize: 28
                    horizontalAlignment: Text.AlignHCenter
                }

                AppText {
                    width: parent.width
                    text: root.selectedNetwork ? `Connect to ${root.selectedNetwork.name}` : ""
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: parent.width
                    height: 42
                    radius: 8
                    color: Colors.palette.surfaceVariant
                    border.width: 1
                    border.color: passwordInput.activeFocus
                        ? Colors.palette.outline
                        : "transparent"

                    TextInput {
                        id: passwordInput
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: revealButton.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: !Network.busy
                        color: Colors.palette.surfaceText
                        selectionColor: Colors.palette.secondary
                        selectedTextColor: Colors.palette.secondaryText
                        font.family: Typography.fontFamily
                        font.pixelSize: 11
                        echoMode: root.passwordVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        selectByMouse: true
                        clip: true
                        onTextChanged: root.passwordText = text
                        onAccepted: root.submitPassword()
                    }

                    ActionCapsule {
                        id: revealButton
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30
                        content.text: root.passwordVisible ? "\uf070" : "\uf06e"
                        color: "transparent"
                        onClicked: {
                            root.passwordVisible = !root.passwordVisible;
                            passwordInput.forceActiveFocus();
                        }
                    }
                }

                AppText {
                    width: parent.width
                    height: 34
                    text: root.errorMessage
                        ? `\uf071  ${root.errorMessage}`
                        : "Use at least 8 characters for WPA/WPA2/WPA3."
                    color: root.errorMessage
                        ? Colors.palette.error
                        : Colors.palette.surfaceVariantText
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width
                    height: 34
                    spacing: 8

                    ActionCapsule {
                        anchors.verticalCenter: undefined
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        content.text: "\uf060"
                        color: Colors.palette.surfaceVariant
                        onClicked: root.showList()
                    }

                    ActionCapsule {
                        anchors.verticalCenter: undefined
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        actionEnabled: root.passwordText.length >= 8 && !Network.busy
                        content.text: Network.busy ? "\uf110" : "\uf00c"
                        color: actionEnabled
                            ? Colors.palette.secondary
                            : Colors.palette.surfaceVariant
                        content.color: actionEnabled
                            ? Colors.palette.secondaryText
                            : Colors.palette.surfaceVariantText
                        onClicked: root.submitPassword()
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothPairing

        Item {
            function focusInput(): void {
                pairingInput.forceActiveFocus();
            }

            Column {
                anchors.centerIn: parent
                width: 360
                spacing: 10

                AppText {
                    width: parent.width
                    text: BluetoothState.deviceIcon(root.selectedDevice)
                    font.pixelSize: 28
                    horizontalAlignment: Text.AlignHCenter
                }

                AppText {
                    width: parent.width
                    text: root.selectedDevice
                        ? `Pair with ${BluetoothState.deviceName(root.selectedDevice)}`
                        : ""
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                AppText {
                    width: parent.width
                text: BluetoothPairing.errorMessage || BluetoothPairing.message
                color: BluetoothPairing.errorMessage
                        ? Colors.palette.error
                        : Colors.palette.surfaceVariantText
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                AppText {
                    width: parent.width
                height: BluetoothPairing.code ? 52 : 0
                visible: BluetoothPairing.code !== ""
                text: BluetoothPairing.code
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                    font.letterSpacing: 3
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: parent.width
                height: BluetoothPairing.mode === "input" ? 42 : 0
                visible: BluetoothPairing.mode === "input"
                    radius: 8
                    color: Colors.palette.surfaceVariant

                    TextInput {
                        id: pairingInput
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.palette.surfaceText
                        selectionColor: Colors.palette.secondary
                        selectedTextColor: Colors.palette.secondaryText
                        font.family: Typography.fontFamily
                        font.pixelSize: 11
                        inputMethodHints: Qt.ImhDigitsOnly
                        selectByMouse: true
                        clip: true
                    onAccepted: BluetoothPairing.answer(text)
                    }
                }

                Row {
                    width: parent.width
                    height: 34
                    spacing: 8

                    ActionCapsule {
                        anchors.verticalCenter: undefined
                    width: BluetoothPairing.mode === "confirm"
                        ? (parent.width - parent.spacing * 2) / 3
                        : BluetoothPairing.mode === "input"
                                ? (parent.width - parent.spacing) / 2
                                : parent.width
                        height: parent.height
                        content.text: "\uf060"
                        color: Colors.palette.surfaceVariant
                        onClicked: root.showList()
                    }

                    ActionCapsule {
                        anchors.verticalCenter: undefined
                        width: (parent.width - parent.spacing * 2) / 3
                        height: parent.height
                    visible: BluetoothPairing.mode === "confirm"
                        content.text: "\uf00d"
                        color: Colors.palette.surfaceVariant
                        onClicked: {
                        BluetoothPairing.answer("no");
                            root.showList();
                        }
                    }

                    ActionCapsule {
                    readonly property bool acceptable: BluetoothPairing.mode === "confirm"
                        || (BluetoothPairing.mode === "input" && pairingInput.text.trim() !== "")
                        anchors.verticalCenter: undefined
                    width: BluetoothPairing.mode === "confirm"
                            ? (parent.width - parent.spacing * 2) / 3
                            : (parent.width - parent.spacing) / 2
                        height: parent.height
                    visible: BluetoothPairing.mode === "confirm" || BluetoothPairing.mode === "input"
                        actionEnabled: acceptable
                        content.text: "\uf00c"
                        color: acceptable
                            ? Colors.palette.secondary
                            : Colors.palette.surfaceVariant
                        content.color: acceptable
                            ? Colors.palette.secondaryText
                            : Colors.palette.surfaceVariantText
                        onClicked: {
                        if (BluetoothPairing.mode === "confirm")
                            BluetoothPairing.answer("yes");
                        else
                            BluetoothPairing.answer(pairingInput.text);
                        }
                    }
                }
            }
        }
    }
}
