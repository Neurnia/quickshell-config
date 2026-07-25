import QtQuick
import qs.components
import qs.services

Item {
    id: root

    signal backRequested

    function focusInput(): void {
        pairingInput.forceActiveFocus();
    }

    function answer(value: string): void {
        BluetoothPairing.answer(value);
        pairingInput.text = "";
    }

    Column {
        anchors.centerIn: parent
        width: 360
        spacing: 10

        AppText {
            width: parent.width
            text: BluetoothState.deviceIcon(BluetoothPairing.device)
            font.pixelSize: 28
            horizontalAlignment: Text.AlignHCenter
        }

        AppText {
            width: parent.width
            text: BluetoothPairing.device
                ? `Pair with ${BluetoothState.deviceName(BluetoothPairing.device)}`
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
                onAccepted: root.answer(text)
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
                onClicked: root.backRequested()
            }

            ActionCapsule {
                anchors.verticalCenter: undefined
                width: (parent.width - parent.spacing * 2) / 3
                height: parent.height
                visible: BluetoothPairing.mode === "confirm"
                content.text: "\uf00d"
                color: Colors.palette.surfaceVariant
                onClicked: {
                    root.answer("no");
                    root.backRequested();
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
                        root.answer("yes");
                    else
                        root.answer(pairingInput.text);
                }
            }
        }
    }
}
