pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.components
import qs.services

OverlayDialog {
    id: root

    property var selectedNetwork: null
    property string errorMessage: ""
    property bool passwordVisible: false
    property bool passwordAcceptable: false

    layerNamespace: "quickshell:wifi-config"
    onDismissRequested: root.close()
    onEscapePressed: {
        if (root.selectedNetwork)
            root.showNetworkList();
        else
            root.close();
    }

    function open(): void {
        resetAuthentication();
        shown = true;
        if (Network.wifiEnabled)
            Network.rescan();
    }

    function close(): void {
        shown = false;
        resetAuthentication();
        if (Network.actionPurpose === "credentials")
            Network.cancelCredentialConnection();
    }

    function resetAuthentication(): void {
        selectedNetwork = null;
        errorMessage = "";
        passwordVisible = false;
        passwordAcceptable = false;
        passwordInput.text = "";
    }

    function showNetworkList(): void {
        if (Network.actionPurpose === "credentials")
            Network.cancelCredentialConnection();
        resetAuthentication();
        takeFocus();
    }

    function chooseNetwork(network): void {
        if (!network || network.active || Network.busy)
            return;

        errorMessage = "";
        if (network.enterprise) {
            errorMessage = `${network.name} uses enterprise authentication, which is not supported by this simple password form.`;
            return;
        }

        if (network.saved || !network.secured) {
            Network.connectNetwork(network);
            return;
        }

        selectedNetwork = network;
        passwordVisible = false;
        passwordInput.text = "";
        Qt.callLater(() => passwordInput.forceActiveFocus());
    }

    function submitPassword(): void {
        if (!selectedNetwork || !passwordAcceptable || Network.busy)
            return;

        const password = passwordInput.text;
        passwordInput.text = "";
        errorMessage = "";
        Network.connectWithPassword(selectedNetwork, password);
    }

    IpcHandler {
        target: "wifiConfig"

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

    Connections {
        target: Network

        function onConnectionSucceeded(name: string): void {
            if (root.shown)
                root.close();
        }

        function onConnectionFailed(name: string, message: string): void {
            if (!root.shown)
                return;

            root.errorMessage = message;
            if (root.selectedNetwork && root.selectedNetwork.name === name)
                Qt.callLater(() => passwordInput.forceActiveFocus());
        }
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
                    text: "\uf1eb  Wi-Fi configuration"
                    color: Colors.palette.surfaceText
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                AppText {
                    width: parent.width
                    text: Network.wifiEnabled ? `${Network.icon}  ${Network.label}` : "󰤭  Wi-Fi is off"
                    color: Colors.palette.surfaceVariantText
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

                    actionEnabled: Network.wifiEnabled && !Network.busy
                    anchors.verticalCenter: undefined
                    width: 82
                    height: 30
                    radius: height * 0.2
                    content.text: Network.busy ? "\uf110  Wait" : "\uf2f1  Scan"
                    color: Colors.palette.surfaceVariant
                    onClicked: Network.rescan()
                }

                ActionCapsule {
                    id: closeButton

                    anchors.verticalCenter: undefined
                    width: 30
                    height: 30
                    radius: height * 0.2
                    content.text: "\uf00d"
                    color: Colors.palette.surfaceVariant
                    onClicked: root.close()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Colors.palette.outlineVariant
            opacity: 0.35
        }

        Item {
            width: parent.width
            height: 405

            Column {
                id: listContent

                anchors.fill: parent
                spacing: 6
                visible: root.selectedNetwork === null

                Item {
                    id: listHeader

                    width: parent.width
                    height: 24

                    AppText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Network.wifiEnabled ? "Available networks" : "Wireless networking disabled"
                        color: Colors.palette.surfaceText
                        font.pixelSize: 11
                    }

                    AppText {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Network.wifiEnabled
                        text: `${Network.networks.length} found`
                        color: Colors.palette.surfaceVariantText
                        font.pixelSize: 9
                    }
                }

                AppText {
                    id: listError

                    width: parent.width
                    height: visible ? 34 : 0
                    visible: root.errorMessage !== ""
                    text: `\uf071  ${root.errorMessage}`
                    color: Colors.palette.error
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }

                ListView {
                    id: networkList

                    width: parent.width
                    height: parent.height - listHeader.height - listError.height - (listError.visible ? 12 : 6)
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: Network.wifiEnabled ? Network.networks : []

                    delegate: ActionCapsule {
                        id: networkRow

                        required property var modelData

                        actionEnabled: !modelData.active && !Network.busy
                        anchors.verticalCenter: undefined
                        width: networkList.width
                        height: 50
                        radius: height * 0.16
                        content.text: ""
                        color: modelData.active ? Colors.palette.secondary : Colors.palette.surfaceVariant

                        AppText {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: Network.signalIcon(networkRow.modelData.signal)
                            color: networkRow.modelData.active ? Colors.palette.secondaryText : Colors.palette.surfaceText
                            font.pixelSize: 16
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
                                color: networkRow.modelData.active ? Colors.palette.secondaryText : Colors.palette.surfaceText
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
                                    if (networkRow.modelData.secured)
                                        return "\uf023  Secured";
                                    return "\uf09c  Open network";
                                }
                                color: networkRow.modelData.active ? Colors.palette.secondaryText : Colors.palette.surfaceVariantText
                                font.pixelSize: 9
                            }
                        }

                        AppText {
                            id: signalLabel

                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: `${networkRow.modelData.signal}%`
                            color: networkRow.modelData.active ? Colors.palette.secondaryText : Colors.palette.surfaceVariantText
                            font.pixelSize: 10
                        }

                        onClicked: root.chooseNetwork(networkRow.modelData)
                    }

                    AppText {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        visible: networkList.count === 0
                        text: Network.wifiEnabled ? (Network.busy ? "\uf110  Scanning for networks…" : "󰤭  No networks found") : "\uf1eb  Turn on Wi-Fi from the status panel"
                        color: Colors.palette.surfaceVariantText
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Column {
                id: authenticationContent

                anchors.centerIn: parent
                width: 360
                spacing: 10
                visible: root.selectedNetwork !== null

                AppText {
                    width: parent.width
                    text: "\uf023"
                    color: Colors.palette.surfaceText
                    font.pixelSize: 30
                    horizontalAlignment: Text.AlignHCenter
                }

                AppText {
                    width: parent.width
                    text: root.selectedNetwork ? `Connect to ${root.selectedNetwork.name}` : ""
                    color: Colors.palette.surfaceText
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                AppText {
                    width: parent.width
                    text: "Enter the network password"
                    color: Colors.palette.surfaceVariantText
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                }

                Item {
                    width: 1
                    height: 6
                }

                AppText {
                    width: parent.width
                    text: "Password"
                    color: Colors.palette.surfaceText
                    font.pixelSize: 10
                }

                Rectangle {
                    width: parent.width
                    height: 42
                    radius: 8
                    color: Colors.palette.surfaceVariant
                    border.width: 1
                    border.color: passwordInput.activeFocus ? Colors.palette.outline : "transparent"

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
                        onTextChanged: root.passwordAcceptable = text.length >= 8
                        onAccepted: root.submitPassword()
                    }

                    AppText {
                        id: revealButton

                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.passwordVisible ? "\uf070" : "\uf06e"
                        color: Colors.palette.surfaceVariantText
                        font.pixelSize: 12

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.passwordVisible = !root.passwordVisible;
                                passwordInput.forceActiveFocus();
                            }
                        }
                    }
                }

                AppText {
                    width: parent.width
                    height: 36
                    text: {
                        if (Network.busy && Network.connectingName === (root.selectedNetwork?.name || ""))
                            return "\uf110  Connecting…";
                        if (root.errorMessage)
                            return `\uf071  ${root.errorMessage}`;
                        return "Use at least 8 characters for WPA/WPA2/WPA3.";
                    }
                    color: root.errorMessage ? Colors.palette.error : Colors.palette.surfaceVariantText
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }

                Row {
                    width: parent.width
                    height: 34
                    spacing: 8

                    ActionCapsule {
                        id: backButton

                        anchors.verticalCenter: undefined
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        radius: height * 0.2
                        content.text: "\uf060  Back"
                        color: Colors.palette.surfaceVariant
                        onClicked: root.showNetworkList()
                    }

                    ActionCapsule {
                        id: connectButton

                        actionEnabled: root.passwordAcceptable && !Network.busy
                        anchors.verticalCenter: undefined
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        radius: height * 0.2
                        content.text: Network.busy ? "\uf110  Connecting" : "\uf00c  Connect"
                        color: root.passwordAcceptable && !Network.busy ? Colors.palette.secondary : Colors.palette.surfaceVariant
                        content.color: root.passwordAcceptable && !Network.busy ? Colors.palette.secondaryText : Colors.palette.surfaceVariantText
                        onClicked: root.submitPassword()
                    }
                }
            }
        }
    }
}
