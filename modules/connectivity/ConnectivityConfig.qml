pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.components
import qs.services
import "./components"
import "./pages"

OverlayDialog {
    id: root

    property string currentPage: "wifi"
    property var selectedNetwork: null
    property string errorMessage: ""
    readonly property bool inDetail: selectedNetwork !== null || BluetoothPairing.device !== null
    readonly property string query: header.query

    layerNamespace: "quickshell:connectivity-config"
    cardWidth: 440
    cardHeight: 500
    onDismissRequested: close()
    onEscapePressed: {
        if (query !== "" && !inDetail) {
            header.clearSearch();
        } else if (inDetail) {
            showList();
        } else {
            close();
        }
    }
    onKeyPressed: event => {
        if (event.key === Qt.Key_Slash && !inDetail) {
            header.focusSearch();
            event.accepted = true;
        }
    }

    function open(page: string): void {
        switchPage(page === "bluetooth" ? "bluetooth" : "wifi");
        shown = true;
        Qt.callLater(() => header.focusSearch());
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
        header.clearSearch();
        showList();
        if (shown)
            Qt.callLater(() => header.focusSearch());
    }

    function showList(): void {
        BluetoothPairing.cancel();
        selectedNetwork = null;
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

    function toggleCurrentPage(): void {
        if (currentPage === "wifi")
            Network.toggleWifi();
        else
            BluetoothState.toggleEnabled();
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
        Qt.callLater(() => contentLoader.item?.focusInput());
    }

    function submitPassword(password: string): void {
        if (!selectedNetwork || password.length < 8 || Network.busy)
            return;
        errorMessage = "";
        Network.connectWithPassword(selectedNetwork, password);
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

        ConnectivityHeader {
            id: header

            width: parent.width
            height: implicitHeight
            currentPage: root.currentPage
            inDetail: root.inDetail
            onPageRequested: page => root.switchPage(page)
            onCloseRequested: root.close()
            onToggleRequested: root.toggleCurrentPage()
            onRefreshRequested: root.refreshCurrentPage()
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
                if (BluetoothPairing.device)
                    return bluetoothPairing;
                return root.currentPage === "wifi" ? wifiNetworks : bluetoothDevices;
            }
        }
    }

    Component {
        id: wifiNetworks

        WifiNetworksPage {
            query: root.query
            onNetworkChosen: network => root.chooseNetwork(network)
        }
    }

    Component {
        id: bluetoothDevices

        BluetoothDevicesPage {
            query: root.query
            onDeviceChosen: device => root.chooseDevice(device)
        }
    }

    Component {
        id: wifiAuthentication

        WifiAuthenticationPage {
            network: root.selectedNetwork
            errorMessage: root.errorMessage
            onBackRequested: root.showList()
            onPasswordSubmitted: password => root.submitPassword(password)
        }
    }

    Component {
        id: bluetoothPairing

        BluetoothPairingPage {
            onBackRequested: root.showList()
        }
    }
}
