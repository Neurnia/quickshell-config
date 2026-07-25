pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

ActionCapsule {
    id: root

    property var action: null
    property int actionIndex: -1
    property bool selected: false
    property bool holding: false
    property bool activelyHolding: false
    property real holdProgress: 0
    property var feedbackSource: null
    property real holdOffset: activelyHolding ? 1 : 0
    property real holdScale: activelyHolding ? 0.985 : 1
    property real feedbackOffset: 0
    property real feedbackScale: 1
    readonly property color progressColor: action?.id === "shutdown"
        ? Colors.palette.error
        : Colors.palette.primary

    signal selectionRequested(int index)
    signal actionPressed(int index)
    signal actionClicked(int index)
    signal actionReleased(int index)
    signal actionCanceled(int index)

    radius: 10
    clip: true
    content.text: ""
    color: Colors.palette.surfaceVariant
    border.width: selected ? 2 : 1
    border.color: selected ? Colors.palette.outline : "transparent"
    onHoveredChanged: {
        if (hovered)
            selectionRequested(actionIndex);
    }
    onPressed: actionPressed(actionIndex)
    onClicked: actionClicked(actionIndex)
    onReleased: actionReleased(actionIndex)
    onCanceled: actionCanceled(actionIndex)
    transform: [
        Translate {
            y: root.holdOffset + root.feedbackOffset
        },
        Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: root.holdScale * root.feedbackScale
            yScale: root.holdScale * root.feedbackScale
        }
    ]

    function playFeedback(kind: string): void {
        cancelFeedback.stop();
        completeFeedback.stop();
        feedbackOffset = 0;
        feedbackScale = 1;

        if (kind === "cancel")
            cancelFeedback.restart();
        else if (kind === "complete")
            completeFeedback.restart();
    }

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
        width: root.holding ? parent.width * root.holdProgress : 0
        clip: true

        Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
            color: root.progressColor
            opacity: 0.38
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 5

        AppText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.action?.icon || ""
            color: root.action?.id === "shutdown" && (root.selected || root.holding)
                ? Colors.palette.error
                : Colors.palette.surfaceText
            font.pixelSize: 22
        }

        AppText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.action?.label || ""
            color: Colors.palette.surfaceText
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        AppText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.action?.dangerous ? "Hold to confirm" : root.action?.description || ""
            color: Colors.palette.surfaceVariantText
            font.pixelSize: 8
        }
    }

    Connections {
        target: root.feedbackSource

        function onHoldFeedbackRequested(targetIndex: int, kind: string): void {
            if (targetIndex === root.actionIndex)
                root.playFeedback(kind);
        }
    }

    SequentialAnimation {
        id: cancelFeedback

        NumberAnimation {
            target: root
            property: "feedbackOffset"
            to: -2.5
            duration: 65
            easing.type: Easing.OutCubic
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "feedbackOffset"
                to: 0
                duration: 150
                easing.type: Easing.OutBack
            }
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "feedbackScale"
                    to: 1.012
                    duration: 80
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: root
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
                target: root
                property: "feedbackOffset"
                to: -1
                duration: 80
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "feedbackScale"
                to: 1.018
                duration: 80
                easing.type: Easing.OutCubic
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "feedbackOffset"
                to: 0
                duration: 85
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: root
                property: "feedbackScale"
                to: 1
                duration: 85
                easing.type: Easing.InOutCubic
            }
        }
    }
}
