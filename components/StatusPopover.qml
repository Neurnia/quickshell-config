pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Item {
    id: root

    property alias panel: panelWindow
    property string statusIcon: ""
    property string statusText: ""
    property string details: ""
    property string toggleIcon: ""
    property string toggleText: ""
    property string configText: ""
    property bool toggleActive: false
    property bool toggleEnabled: true
    property bool menuOpen: false
    readonly property bool hovered: statusButton.hovered || panelWindow.hovered

    signal toggleRequested
    signal configRequested

    anchors.verticalCenter: parent.verticalCenter
    width: 130
    height: parent.height - 2

    ActionCapsule {
        id: statusButton

        anchors.fill: parent
        anchors.verticalCenter: undefined
        content {
            width: statusButton.width - 20
            text: `${root.statusIcon} ${root.statusText}`
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
        border.color: root.menuOpen || hovered ? Colors.palette.outline : "transparent"
        onHoveredChanged: {
            if (hovered)
                root.menuOpen = true;
        }
        onClicked: root.menuOpen = !root.menuOpen
    }

    Timer {
        interval: 400
        running: root.menuOpen && !root.hovered
        onTriggered: root.menuOpen = false
    }

    PopupWindow {
        id: panelWindow

        readonly property bool hovered: panelHover.hovered
        readonly property int panelWidth: 250
        readonly property int panelHeight: 92

        implicitWidth: panelWidth
        implicitHeight: panelHeight
        visible: root.menuOpen
        color: "transparent"

        Capsule {
            anchors.fill: parent
            radius: height * 0.045
            color: Colors.palette.surfaceContainerLowest

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
                    color: Colors.palette.surfaceVariant

                    AppText {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 7
                        text: `${root.statusIcon}  ${root.statusText}`
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    AppText {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 7
                        text: root.details
                        color: Colors.palette.surfaceVariantText
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                Row {
                    width: parent.width
                    height: 26
                    spacing: 4

                    ActionCapsule {
                        actionEnabled: root.toggleEnabled
                        anchors.verticalCenter: undefined
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        radius: height * 0.18
                        content.text: `${root.toggleIcon}  ${root.toggleText}`
                        content.elide: Text.ElideRight
                        color: root.toggleActive ? Colors.palette.secondary : Colors.palette.surfaceVariant
                        content.color: root.toggleActive ? Colors.palette.secondaryText : Colors.palette.surfaceText
                        onClicked: root.toggleRequested()
                    }

                    ActionCapsule {
                        anchors.verticalCenter: undefined
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        radius: height * 0.18
                        content.text: `\uf013  ${root.configText}`
                        content.elide: Text.ElideRight
                        color: Colors.palette.surfaceVariant
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
