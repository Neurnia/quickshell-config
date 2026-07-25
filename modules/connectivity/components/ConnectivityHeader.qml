import QtQuick
import qs.components
import qs.services

Item {
    id: root

    property string currentPage: "wifi"
    property bool inDetail: false
    property alias query: searchInput.text
    readonly property bool refreshing: currentPage === "wifi"
        ? Network.busy && Network.actionPurpose === "scan"
        : BluetoothState.discovering

    signal pageRequested(string page)
    signal closeRequested
    signal toggleRequested
    signal refreshRequested

    implicitHeight: inDetail ? 84 : 178

    function focusSearch(): void {
        searchInput.forceActiveFocus();
    }

    function clearSearch(): void {
        searchInput.text = "";
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

    Column {
        anchors.fill: parent
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
                onClicked: root.closeRequested()
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
                    onClicked: root.pageRequested("bluetooth")
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
                    onClicked: root.pageRequested("wifi")
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
                onToggled: root.toggleRequested()
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
                        root.clearSearch();
                        root.focusSearch();
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
                onClicked: root.refreshRequested()

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
    }
}
