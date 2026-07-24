import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

PanelWindow {
    id: root

    anchors.bottom: true
    margins.bottom: 55
    implicitWidth: 320
    implicitHeight: 58
    color: "transparent"
    exclusiveZone: 0
    visible: hideTimer.running

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-volume-osd"

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: Colors.palette.m3surfaceContainerHigh
        border.color: Colors.palette.m3outlineVariant

        Row {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 14

            AppText {
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                text: Audio.icon
                color: Colors.palette.m3onSurface
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 188
                height: 5
                radius: height / 2
                color: Colors.palette.m3surfaceVariant

                Rectangle {
                    width: parent.width * Math.min(Audio.volume, 1)
                    height: parent.height
                    radius: parent.radius
                    color: Colors.palette.m3primary

                    Behavior on width {
                        NumberAnimation {
                            duration: 80
                        }
                    }
                }
            }

            AppText {
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                text: `${Audio.percentage}%`
                color: Colors.palette.m3onSurface
                font.pixelSize: 13
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    Connections {
        target: Audio

        function onOutputChanged(): void {
            if (startupTimer.running)
                return;

            hideTimer.restart();
        }
    }

    Timer {
        id: startupTimer
        running: true
        interval: 750
    }

    Timer {
        id: hideTimer
        interval: 1800
    }
}
