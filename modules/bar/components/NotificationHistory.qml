pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services

PopupWindow {
    id: root

    readonly property int panelWidth: 360
    readonly property int panelHeight: Math.min(500, Math.max(104, 50 + MakoState.history.length * 45))

    implicitWidth: panelWidth
    implicitHeight: panelHeight
    visible: false
    grabFocus: true
    color: "transparent"

    onVisibleChanged: {
        if (visible)
            MakoState.refresh();
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        antialiasing: true
        color: Colors.palette.surfaceContainerLowest
        border.color: Colors.palette.outline
        border.width: 1

        AppText {
            id: title

            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.top: parent.top
            anchors.topMargin: 10
            text: "Notification history"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        AppText {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: title.verticalCenter
            text: `${MakoState.history.length}/${MakoState.historyLimit}`
            color: Colors.palette.surfaceVariantText
            font.pixelSize: 8
        }

        Rectangle {
            id: divider

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 36
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            height: 1
            color: Colors.palette.outlineVariant
            opacity: 0.45
        }

        ListView {
            id: historyList

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: divider.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 7
            clip: true
            spacing: 2
            model: MakoState.history
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: entry

                required property var modelData
                required property int index

                width: historyList.width
                height: 43
                radius: 7
                color: index % 2 === 0
                    ? Colors.palette.surfaceContainerLow
                    : Colors.palette.surfaceContainer

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: parent.height - 12
                    radius: 1
                    color: entry.modelData.urgency >= 2
                        ? Colors.palette.error
                        : entry.modelData.urgency === 0
                            ? Colors.palette.outlineVariant
                            : Colors.palette.primary
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 13
                    anchors.right: parent.right
                    anchors.rightMargin: 9
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Row {
                        width: parent.width
                        spacing: 8

                        AppText {
                            width: parent.width - appName.width - parent.spacing
                            text: entry.modelData.summary
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        AppText {
                            id: appName

                            width: Math.min(implicitWidth, 115)
                            text: entry.modelData.appName
                            color: Colors.palette.surfaceVariantText
                            font.pixelSize: 8
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }
                    }

                    AppText {
                        width: parent.width
                        visible: text.length > 0
                        text: entry.modelData.body
                        color: Colors.palette.surfaceVariantText
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }
                }
            }

            AppText {
                anchors.centerIn: parent
                visible: historyList.count === 0
                text: "No notification history"
                color: Colors.palette.surfaceVariantText
                font.pixelSize: 9
            }
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: root.visible
        onTriggered: MakoState.refresh()
    }
}
