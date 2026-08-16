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
    property int openMenuCount: 0
    readonly property bool hovered: statusButton.hovered || panelWindow.hovered || openMenuCount > 0

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
        border.color: root.menuOpen || root.hovered ? Colors.palette.outline : "transparent"
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
        readonly property int panelWidth: trayItems.implicitWidth + 12
        readonly property int panelHeight: 40

        implicitWidth: panelWidth
        implicitHeight: panelHeight
        visible: root.menuOpen && trayRepeater.count > 0
        color: "transparent"

        Capsule {
            anchors.fill: parent
            radius: height / 2
            color: Colors.palette.surfaceContainerLowest

            HoverHandler {
                id: panelHover
            }

            Row {
                id: trayItems

                anchors.centerIn: parent
                height: parent.height - 8
                spacing: 2

                Repeater {
                    id: trayRepeater

                    model: TrayState.items

                    delegate: Item {
                        id: trayItem

                        required property SystemTrayItem modelData

                        width: 28
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
                            width: 20
                            height: 20
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
                            onOpened: root.openMenuCount += 1
                            onClosed: root.openMenuCount = Math.max(0, root.openMenuCount - 1)
                        }
                    }
                }
            }
        }
    }
}
