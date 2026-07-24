pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services

Capsule {
    id: root

    property Panel panel: Panel {}
    property bool menuOpen: false
    property bool hover: buttonHover.hovered || panel.hover

    signal configRequested

    width: 130
    border.color: menuOpen || buttonHover.hovered ? Colors.palette.m3outline : "transparent"

    content {
        width: root.width - 20
        text: `${Network.icon} ${Network.label}${Network.vpnConnected ? " \uf023" : ""}`
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }

    HoverHandler {
        id: buttonHover
        onHoveredChanged: {
            if (hovered)
                root.menuOpen = true;
        }
    }

    Timer {
        interval: 400
        running: root.menuOpen && !root.hover
        onTriggered: root.menuOpen = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.menuOpen = !root.menuOpen
    }

    component Panel: PopupWindow {
        id: panel

        property bool hover: panelHover.hovered
        readonly property int panelWidth: 250
        readonly property int panelHeight: 92

        implicitWidth: panelWidth
        implicitHeight: panelHeight
        visible: root.menuOpen
        color: "transparent"

        Capsule {
            anchors.fill: parent
            radius: height * 0.045
            color: Colors.palette.m3surfaceContainerLowest

            HoverHandler {
                id: panelHover
            }

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                Capsule {
                    anchors.verticalCenter: undefined
                    width: parent.width
                    height: 50
                    radius: height * 0.16
                    content.text: ""
                    color: Colors.palette.m3surfaceVariant

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 7
                        text: `${Network.icon}  ${Network.label}${Network.vpnConnected ? "  \uf023" : ""}`
                        color: Colors.palette.m3onSurface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 7
                        text: {
                            const quality = Network.connectionType === "wifi" ? `${Network.signalStrength}%` : Network.connectionType === "ethernet" ? "Wired connection" : "No connection";
                            const address = Network.ipAddress ? `  ·  ${Network.ipAddress}` : "";
                            return quality + address;
                        }
                        color: Colors.palette.m3onSurfaceVariant
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                Row {
                    width: parent.width
                    height: 26
                    spacing: 4

                    Capsule {
                        id: wifiButton

                        anchors.verticalCenter: undefined
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        radius: height * 0.18
                        content.text: `\uf1eb  Wi-Fi ${Network.wifiEnabled ? "on" : "off"}`
                        color: Network.wifiEnabled ? Colors.palette.m3secondary : Colors.palette.m3surfaceVariant
                        content.color: Network.wifiEnabled ? Colors.palette.m3onSecondary : Colors.palette.m3onSurface
                        border.color: wifiHover.hovered ? Colors.palette.m3outline : "transparent"

                        HoverHandler {
                            id: wifiHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Network.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: Network.toggleWifi()
                        }
                    }

                    Capsule {
                        id: configButton

                        anchors.verticalCenter: undefined
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        radius: height * 0.18
                        content.text: "\uf013  Wi-Fi config"
                        content.elide: Text.ElideRight
                        color: Colors.palette.m3surfaceVariant
                        border.color: configHover.hovered ? Colors.palette.m3outline : "transparent"

                        HoverHandler {
                            id: configHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.menuOpen = false;
                                root.configRequested();
                            }
                        }
                    }
                }
            }
        }
    }
}
