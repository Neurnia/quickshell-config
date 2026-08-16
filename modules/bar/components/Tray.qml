pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.components
import qs.services

Capsule {
    id: root

    property alias panel: panelWindow
    readonly property bool menuOpen: panelWindow.visible

    visible: TrayState.inputMethod !== null || trayRepeater.count > 0
    width: capsuleItems.implicitWidth + 8
    clip: true
    content.text: ""
    border.color: menuOpen ? Colors.palette.outline : "transparent"

    Row {
        id: capsuleItems

        anchors.centerIn: parent
        height: parent.height - 4
        spacing: 2

        Item {
            visible: trayRepeater.count > 0
            width: 20
            height: parent.height

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: arrowMouse.containsMouse || root.menuOpen
                    ? Colors.palette.surfaceContainerHigh
                    : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            AppText {
                anchors.centerIn: parent
                text: root.menuOpen ? "\uf077" : "\uf078"
                font.pixelSize: 9
            }

            MouseArea {
                id: arrowMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panelWindow.visible = !panelWindow.visible
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: TrayState.inputMethod !== null && trayRepeater.count > 0
            width: 1
            height: 12
            color: Colors.palette.outlineVariant
            opacity: 0.7
        }

        TrayItemButton {
            visible: TrayState.inputMethod !== null
            height: parent.height
            trayEntry: TrayState.inputMethod
        }
    }

    PopupWindow {
        id: panelWindow

        readonly property int panelWidth: trayItems.implicitWidth + 16
        readonly property int panelHeight: 38

        implicitWidth: panelWidth
        implicitHeight: panelHeight
        visible: false
        grabFocus: true
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 8
            antialiasing: true
            color: Colors.palette.surfaceContainerLowest
            border.color: Colors.palette.outline
            border.width: 1

            Row {
                id: trayItems

                anchors.centerIn: parent
                height: parent.height - 10
                spacing: 3

                Repeater {
                    id: trayRepeater

                    model: TrayState.items
                    onCountChanged: {
                        if (count === 0)
                            panelWindow.visible = false;
                    }

                    delegate: TrayItemButton {
                        required property SystemTrayItem modelData

                        height: trayItems.height
                        trayEntry: modelData
                    }
                }
            }
        }
    }

    component TrayItemButton: Item {
        id: trayItem

        required property SystemTrayItem trayEntry

        width: 24

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: itemMouse.containsMouse || menuAnchor.visible
                ? Colors.palette.surfaceContainerHigh
                : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }

        Image {
            anchors.centerIn: parent
            width: 18
            height: 18
            source: trayItem.trayEntry?.icon ?? ""
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        MouseArea {
            id: itemMouse

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: event => {
                if (event.button === Qt.RightButton || (event.button === Qt.LeftButton && trayItem.trayEntry.onlyMenu)) {
                    if (trayItem.trayEntry.hasMenu)
                        menuAnchor.open();
                    return;
                }

                if (event.button === Qt.MiddleButton) {
                    TrayState.secondaryActivate(trayItem.trayEntry);
                    return;
                }

                TrayState.activate(trayItem.trayEntry);
            }

            onWheel: event => {
                const horizontal = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y);
                const delta = horizontal ? event.angleDelta.x : event.angleDelta.y;
                TrayState.scroll(trayItem.trayEntry, delta, horizontal);
                event.accepted = true;
            }
        }

        QsMenuAnchor {
            id: menuAnchor

            menu: trayItem.trayEntry?.menu ?? null
            anchor.item: trayItem
            anchor.edges: Edges.Bottom
            anchor.gravity: Edges.Bottom
            anchor.adjustment: PopupAdjustment.FlipX | PopupAdjustment.SlideX | PopupAdjustment.SlideY
        }
    }
}
