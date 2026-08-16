pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.components
import qs.services

Item {
    id: root

    property alias panel: panelWindow
    property bool menuOpen: false

    anchors.verticalCenter: parent.verticalCenter
    visible: trayRepeater.count > 0
    width: 30
    height: parent.height - 2

    ActionCapsule {
        id: statusButton

        anchors.fill: parent
        anchors.verticalCenter: undefined
        content.text: "\uf187"
        content.font.pixelSize: 11
        border.color: root.menuOpen || hovered ? Colors.palette.outline : "transparent"
        onClicked: root.menuOpen = !root.menuOpen
    }

    PopupWindow {
        id: panelWindow

        readonly property int panelWidth: trayItems.implicitWidth + 16
        readonly property int panelHeight: 38

        implicitWidth: panelWidth
        implicitHeight: panelHeight
        visible: root.menuOpen && trayRepeater.count > 0
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

                    delegate: Item {
                        id: trayItem

                        required property SystemTrayItem modelData

                        width: 24
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
                            width: 18
                            height: 18
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
    }
}
