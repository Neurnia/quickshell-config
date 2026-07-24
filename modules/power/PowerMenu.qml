pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.components
import qs.services

OverlayDialog {
    id: root

    property int selectedIndex: 0
    property int holdingIndex: -1
    property int completingIndex: -1
    property real holdProgress: 0
    property double holdStartedAt: 0
    property bool showHoldHint: false
    property var pendingCompletion: null

    readonly property int holdDuration: 1200

    signal holdFeedbackRequested(int index, string kind)

    layerNamespace: "quickshell:power-menu"
    cardWidth: 400
    cardHeight: 300
    onDismissRequested: root.close()
    onEscapePressed: root.close()
    onKeyPressed: event => {
        if (event.isAutoRepeat) {
            event.accepted = true;
            return;
        }

        switch (event.key) {
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
    onKeyReleased: event => {
        if (event.isAutoRepeat)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (root.holdingIndex >= 0)
                root.cancelHold(true);
            event.accepted = true;
        }
    }

    function open(): void {
        cancelHold(false);
        completionTimer.stop();
        completingIndex = -1;
        pendingCompletion = null;
        selectedIndex = 0;
        showHoldHint = false;
        shown = true;
    }

    function close(): void {
        cancelHold(false);
        completionTimer.stop();
        completingIndex = -1;
        pendingCompletion = null;
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
        const previousIndex = holdingIndex;
        const wasHolding = holdingIndex >= 0 && holdProgress > 0 && holdProgress < 1;
        holdTimer.stop();
        holdingIndex = -1;
        holdProgress = 0;

        if (showHint && wasHolding) {
            showHoldHint = true;
            holdFeedbackRequested(previousIndex, "cancel");
            hintTimer.restart();
        }
    }

    function completeHold(): void {
        if (holdingIndex < 0 || holdProgress < 1)
            return;

        const completedIndex = holdingIndex;
        holdTimer.stop();
        holdingIndex = -1;
        completingIndex = completedIndex;
        pendingCompletion = SessionActions.actions[completedIndex];
        holdProgress = 1;
        holdFeedbackRequested(completedIndex, "complete");
        completionTimer.restart();
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

    Timer {
        id: completionTimer

        interval: 180
        onTriggered: {
            const action = root.pendingCompletion;
            root.pendingCompletion = null;
            root.completingIndex = -1;
            root.holdProgress = 0;
            root.shown = false;
            SessionActions.execute(action);
        }
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

                AppText {
                    text: "\uf011  Session"
                    color: Colors.palette.surfaceText
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                AppText {
                    text: "Arrow keys to navigate  ·  Esc to cancel"
                    color: Colors.palette.surfaceVariantText
                    font.pixelSize: 9
                }
            }

            ActionCapsule {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: height * 0.2
                content.text: "\uf00d"
                color: Colors.palette.surfaceVariant
                onClicked: root.close()
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Colors.palette.outlineVariant
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

                ActionCapsule {
                    id: actionButton

                    required property var modelData
                    required property int index

                    readonly property bool selected: root.selectedIndex === index
                    readonly property bool holding: root.holdingIndex === index || root.completingIndex === index
                    readonly property bool activelyHolding: root.holdingIndex === index
                    property real holdOffset: activelyHolding ? 1 : 0
                    property real holdScale: activelyHolding ? 0.985 : 1
                    property real feedbackOffset: 0
                    property real feedbackScale: 1
                    readonly property color actionColor: modelData.id === "shutdown" ? Colors.palette.errorContainer : Colors.palette.tertiaryContainer

                    anchors.verticalCenter: undefined
                    width: (actionGrid.width - actionGrid.spacing) / 2
                    height: 82
                    radius: 10
                    clip: true
                    content.text: ""
                    color: Colors.palette.surfaceVariant
                    border.width: selected ? 2 : 1
                    border.color: selected ? Colors.palette.outline : "transparent"
                    onHoveredChanged: {
                        if (hovered)
                            root.selectedIndex = actionButton.index;
                    }
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
                    transform: [
                        Translate {
                            y: actionButton.holdOffset + actionButton.feedbackOffset
                        },
                        Scale {
                            origin.x: actionButton.width / 2
                            origin.y: actionButton.height / 2
                            xScale: actionButton.holdScale * actionButton.feedbackScale
                            yScale: actionButton.holdScale * actionButton.feedbackScale
                        }
                    ]

                    Behavior on holdOffset {
                        NumberAnimation {
                            duration: 90
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on holdScale {
                        NumberAnimation {
                            duration: 90
                            easing.type: Easing.OutCubic
                        }
                    }

                    Item {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: actionButton.holding ? parent.width * root.holdProgress : 0
                        clip: true

                        Rectangle {
                            id: progressFill

                            width: actionButton.width
                            height: actionButton.height
                            radius: actionButton.radius
                            color: actionButton.actionColor
                            opacity: 0.82
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        AppText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: actionButton.modelData.icon
                            color: actionButton.modelData.id === "shutdown" && (actionButton.selected || actionButton.holding) ? Colors.palette.error : Colors.palette.surfaceText
                            font.pixelSize: 22
                        }

                        AppText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: actionButton.modelData.label
                            color: Colors.palette.surfaceText
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        AppText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: actionButton.modelData.dangerous ? "Hold to confirm" : actionButton.modelData.description
                            color: Colors.palette.surfaceVariantText
                            font.pixelSize: 8
                        }
                    }

                    Connections {
                        target: root

                        function onHoldFeedbackRequested(targetIndex: int, kind: string): void {
                            if (targetIndex !== actionButton.index)
                                return;

                            cancelFeedback.stop();
                            completeFeedback.stop();
                            actionButton.feedbackOffset = 0;
                            actionButton.feedbackScale = 1;

                            if (kind === "cancel")
                                cancelFeedback.restart();
                            else if (kind === "complete")
                                completeFeedback.restart();
                        }
                    }

                    SequentialAnimation {
                        id: cancelFeedback

                        NumberAnimation {
                            target: actionButton
                            property: "feedbackOffset"
                            to: -2.5
                            duration: 65
                            easing.type: Easing.OutCubic
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: actionButton
                                property: "feedbackOffset"
                                to: 0
                                duration: 150
                                easing.type: Easing.OutBack
                            }
                            SequentialAnimation {
                                NumberAnimation {
                                    target: actionButton
                                    property: "feedbackScale"
                                    to: 1.012
                                    duration: 80
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: actionButton
                                    property: "feedbackScale"
                                    to: 1
                                    duration: 70
                                    easing.type: Easing.InOutCubic
                                }
                            }
                        }
                    }

                    SequentialAnimation {
                        id: completeFeedback

                        ParallelAnimation {
                            NumberAnimation {
                                target: actionButton
                                property: "feedbackOffset"
                                to: -1
                                duration: 80
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: actionButton
                                property: "feedbackScale"
                                to: 1.018
                                duration: 80
                                easing.type: Easing.OutCubic
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: actionButton
                                property: "feedbackOffset"
                                to: 0
                                duration: 85
                                easing.type: Easing.InOutCubic
                            }
                            NumberAnimation {
                                target: actionButton
                                property: "feedbackScale"
                                to: 1
                                duration: 85
                                easing.type: Easing.InOutCubic
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 22

            AppText {
                anchors.centerIn: parent
                text: {
                    if (root.showHoldHint)
                        return "\uf071  Hold longer to confirm";
                    if (root.completingIndex >= 0)
                        return "\uf00c  Confirmed";
                    if (root.holdingIndex >= 0) {
                        const remaining = Math.max(0, root.holdDuration * (1 - root.holdProgress));
                        return `\uf25a  Keep holding  ${Math.ceil(remaining / 100) / 10}s`;
                    }
                    return "\uf25a  Hold Restart or Shut down for 1.2 seconds";
                }
                color: root.showHoldHint ? Colors.palette.error : Colors.palette.surfaceVariantText
                font.pixelSize: 9
            }
        }
    }
}
