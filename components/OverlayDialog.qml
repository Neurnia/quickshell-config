pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

PanelWindow {
    id: root

    property bool shown: false
    property string layerNamespace: "quickshell:dialog"
    property int cardWidth: 440
    property int cardHeight: 500
    default property alias content: contentContainer.data

    signal dismissRequested
    signal escapePressed
    signal keyPressed(var event)
    signal keyReleased(var event)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    visible: shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: layerNamespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onShownChanged: {
        if (shown)
            Qt.callLater(() => focusScope.forceActiveFocus());
    }

    function takeFocus(): void {
        focusScope.forceActiveFocus();
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: root.shown

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.escapePressed();
                event.accepted = true;
                return;
            }
            root.keyPressed(event);
        }

        Keys.onReleased: event => root.keyReleased(event)

        Rectangle {
            anchors.fill: parent
            color: "#B8000000"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: root.dismissRequested()
            }
        }

        Capsule {
            anchors.centerIn: parent
            width: root.cardWidth
            height: root.cardHeight
            radius: 16
            color: Colors.palette.surfaceContainerLowest
            border.color: Colors.palette.outlineVariant
            content.text: ""

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
            }

            Item {
                id: contentContainer
                anchors.fill: parent
            }
        }
    }
}
