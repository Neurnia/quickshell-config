pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.services

PanelWindow {
    id: root

    property bool shown: false
    property int selectedIndex: 0
    property int holdingIndex: -1
    property real holdProgress: 0
    property double holdStartedAt: 0
    property bool showHoldHint: false

    readonly property int holdDuration: 1200

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    visible: shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell:power-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function open(): void {
        cancelHold(false);
        selectedIndex = 0;
        showHoldHint = false;
        shown = true;
        Qt.callLater(() => focusScope.forceActiveFocus());
    }

    function close(): void {
        cancelHold(false);
        shown = false;
    }

    function beginAction(index: int): void {
        const action = SessionActions.actions[index];
        if (!action || SessionActions.busy)
            return;

        selectedIndex = index;
        if (!action.dangerous) {
            close();
            SessionActions.execute(action);
            return;
        }

        holdingIndex = index;
        holdProgress = 0;
        holdStartedAt = Date.now();
        showHoldHint = false;
        holdTimer.start();
    }

    function cancelHold(showHint: bool): void {
        const wasHolding = holdingIndex >= 0 && holdProgress > 0 && holdProgress < 1;
        holdTimer.stop();
        holdingIndex = -1;
        holdProgress = 0;

        if (showHint && wasHolding) {
            showHoldHint = true;
            hintTimer.restart();
        }
    }

    function completeHold(): void {
        if (holdingIndex < 0 || holdProgress < 1)
            return;

        const action = SessionActions.actions[holdingIndex];
        holdTimer.stop();
        holdingIndex = -1;
        holdProgress = 0;
        shown = false;
        SessionActions.execute(action);
    }

    function moveSelection(delta: int): void {
        const count = SessionActions.actions.length;
        selectedIndex = (selectedIndex + delta + count) % count;
    }

    IpcHandler {
        target: "powerMenu"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            if (root.shown)
                root.close();
            else
                root.open();
        }
    }

    Timer {
        id: holdTimer

        interval: 16
        repeat: true
        onTriggered: {
            root.holdProgress = Math.min(1, (Date.now() - root.holdStartedAt) / root.holdDuration);
            if (root.holdProgress >= 1)
                root.completeHold();
        }
    }

    Timer {
        id: hintTimer

        interval: 1800
        onTriggered: root.showHoldHint = false
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: root.shown

        Keys.onPressed: event => {
            if (event.isAutoRepeat) {
                event.accepted = true;
                return;
            }

            switch (event.key) {
            case Qt.Key_Escape:
                root.close();
                event.accepted = true;
                break;
            case Qt.Key_Left:
                root.moveSelection(-1);
                event.accepted = true;
                break;
            case Qt.Key_Right:
                root.moveSelection(1);
                event.accepted = true;
                break;
            case Qt.Key_Up:
                root.moveSelection(-2);
                event.accepted = true;
                break;
            case Qt.Key_Down:
                root.moveSelection(2);
                event.accepted = true;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                root.beginAction(root.selectedIndex);
                event.accepted = true;
                break;
            }
        }

        Keys.onReleased: event => {
            if (event.isAutoRepeat)
                return;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (root.holdingIndex >= 0)
                    root.cancelHold(true);
                event.accepted = true;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#B8000000"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: root.close()
            }
        }

        Capsule {
            id: card

            anchors.centerIn: parent
            width: 400
            height: 300
            radius: 16
            color: Colors.palette.m3surfaceContainerLowest
            border.color: Colors.palette.m3outlineVariant
            content.text: ""

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Item {
                    width: parent.width
                    height: 44

                    Column {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "\uf011  Session"
                            color: Colors.palette.m3onSurface
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Arrow keys to navigate  ·  Esc to cancel"
                            color: Colors.palette.m3onSurfaceVariant
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                    }

                    Capsule {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30
                        radius: height * 0.2
                        content.text: "\uf00d"
                        color: Colors.palette.m3surfaceVariant
                        border.color: closeHover.hovered ? Colors.palette.m3outline : "transparent"

                        HoverHandler {
                            id: closeHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Colors.palette.m3outlineVariant
                    opacity: 0.35
                }

                Grid {
                    id: actionGrid

                    width: parent.width
                    height: 172
                    columns: 2
                    spacing: 8

                    Repeater {
                        model: SessionActions.actions

                        Capsule {
                            id: actionButton

                            required property var modelData
                            required property int index

                            readonly property bool selected: root.selectedIndex === index
                            readonly property bool holding: root.holdingIndex === index
                            readonly property color actionColor: modelData.id === "shutdown"
                                ? Colors.palette.m3errorContainer
                                : Colors.palette.m3tertiaryContainer

                            anchors.verticalCenter: undefined
                            width: (actionGrid.width - actionGrid.spacing) / 2
                            height: 82
                            radius: 10
                            clip: true
                            content.text: ""
                            color: Colors.palette.m3surfaceVariant
                            border.width: selected ? 2 : 1
                            border.color: selected ? Colors.palette.m3outline : "transparent"

                            Item {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: actionButton.holding ? parent.width * root.holdProgress : 0
                                clip: true

                                Rectangle {
                                    width: actionButton.width
                                    height: actionButton.height
                                    radius: actionButton.radius
                                    color: actionButton.actionColor
                                    opacity: 0.8
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: actionButton.modelData.icon
                                    color: actionButton.modelData.id === "shutdown" && (actionButton.selected || actionButton.holding)
                                        ? Colors.palette.m3error
                                        : Colors.palette.m3onSurface
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 22
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: actionButton.modelData.label
                                    color: Colors.palette.m3onSurface
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: actionButton.modelData.dangerous ? "Hold to confirm" : actionButton.modelData.description
                                    color: Colors.palette.m3onSurfaceVariant
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 8
                                }
                            }

                            HoverHandler {
                                id: actionHover
                                onHoveredChanged: {
                                    if (hovered)
                                        root.selectedIndex = actionButton.index;
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: Qt.PointingHandCursor
                                onPressed: {
                                    if (actionButton.modelData.dangerous)
                                        root.beginAction(actionButton.index);
                                }
                                onClicked: {
                                    if (!actionButton.modelData.dangerous)
                                        root.beginAction(actionButton.index);
                                }
                                onReleased: {
                                    if (root.holdingIndex === actionButton.index)
                                        root.cancelHold(true);
                                }
                                onCanceled: {
                                    if (root.holdingIndex === actionButton.index)
                                        root.cancelHold(false);
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 22

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (root.showHoldHint)
                                return "\uf071  Hold longer to confirm";
                            if (root.holdingIndex >= 0) {
                                const remaining = Math.max(0, root.holdDuration * (1 - root.holdProgress));
                                return `\uf25a  Keep holding  ${Math.ceil(remaining / 100) / 10}s`;
                            }
                            return "\uf25a  Hold Restart or Shut down for 1.2 seconds";
                        }
                        color: root.showHoldHint ? Colors.palette.m3error : Colors.palette.m3onSurfaceVariant
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
}
