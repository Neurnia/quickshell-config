pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.components
import qs.services

Capsule {
    id: root

    visible: trayRepeater.count > 0
    width: trayItems.implicitWidth + 8
    clip: true
    content.text: ""

    Row {
        id: trayItems

        anchors.centerIn: parent
        height: parent.height - 4
        spacing: 2

        Repeater {
            id: trayRepeater

            model: TrayState.items

            delegate: Item {
                id: trayItem

                required property SystemTrayItem modelData

                width: 20
                height: trayItems.height

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: mouseArea.containsMouse || menuAnchor.visible
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
                    width: 15
                    height: 15
                    source: trayItem.modelData.icon
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: event => {
                        if (event.button === Qt.RightButton || (event.button === Qt.LeftButton && trayItem.modelData.onlyMenu)) {
                            if (trayItem.modelData.hasMenu)
                                menuAnchor.open();
                            return;
                        }

                        if (event.button === Qt.MiddleButton) {
                            TrayState.secondaryActivate(trayItem.modelData);
                            return;
                        }

                        TrayState.activate(trayItem.modelData);
                    }

                    onWheel: event => {
                        const horizontal = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y);
                        const delta = horizontal ? event.angleDelta.x : event.angleDelta.y;
                        TrayState.scroll(trayItem.modelData, delta, horizontal);
                        event.accepted = true;
                    }
                }

                QsMenuAnchor {
                    id: menuAnchor

                    menu: trayItem.modelData.menu
                    anchor.item: trayItem
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom
                    anchor.adjustment: PopupAdjustment.FlipX | PopupAdjustment.SlideX | PopupAdjustment.SlideY
                }
            }
        }
    }
}
