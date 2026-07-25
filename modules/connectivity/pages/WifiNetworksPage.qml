import QtQuick
import qs.components
import qs.services

Item {
    id: root

    property string query: ""

    signal networkChosen(var network)

    function filteredNetworks(): var {
        if (!Network.wifiEnabled)
            return [];
        const needle = query.trim().toLowerCase();
        if (!needle)
            return Network.networks;
        return Network.networks.filter(network => network.name.toLowerCase().indexOf(needle) !== -1);
    }

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
            onClicked: root.networkChosen(modelData)

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
