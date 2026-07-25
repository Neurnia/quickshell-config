import QtQuick
import qs.components
import qs.services

Item {
    id: root

    property var network: null
    property string errorMessage: ""
    property bool passwordVisible: false

    signal backRequested
    signal passwordSubmitted(string password)

    function focusInput(): void {
        passwordInput.forceActiveFocus();
    }

    function submit(): void {
        if (passwordInput.text.length < 8 || Network.busy)
            return;
        const password = passwordInput.text;
        passwordInput.text = "";
        passwordSubmitted(password);
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
            text: root.network ? `Connect to ${root.network.name}` : ""
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
                onAccepted: root.submit()
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
                onClicked: root.backRequested()
            }

            ActionCapsule {
                anchors.verticalCenter: undefined
                width: (parent.width - parent.spacing) / 2
                height: parent.height
                actionEnabled: passwordInput.text.length >= 8 && !Network.busy
                content.text: Network.busy ? "\uf110" : "\uf00c"
                color: actionEnabled
                    ? Colors.palette.secondary
                    : Colors.palette.surfaceVariant
                content.color: actionEnabled
                    ? Colors.palette.secondaryText
                    : Colors.palette.surfaceVariantText
                onClicked: root.submit()
            }
        }
    }
}
