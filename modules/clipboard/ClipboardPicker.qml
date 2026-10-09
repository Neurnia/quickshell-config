pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.components
import qs.services
import "./components"

OverlayDialog {
    id: root

    property var matches: []
    property int selectedIndex: 0
    readonly property var selectedEntry: matches[selectedIndex] || null

    layerNamespace: "quickshell:clipboard"
    cardWidth: Math.min(1100, width - 48)
    cardHeight: Math.min(680, height - 64)
    onDismissRequested: close()
    onEscapePressed: close()
    onKeyPressed: event => handleKey(event)
    onSelectedEntryChanged: ClipboardHistory.preview(selectedEntry)

    function open(): void {
        search.text = "";
        selectedIndex = 0;
        ClipboardHistory.open();
        shown = true;
        Qt.callLater(() => search.forceActiveFocus());
    }

    function close(): void {
        shown = false;
        ClipboardHistory.close();
    }

    function filter(): void {
        // Ordered subsequence matching keeps the familiar fzf typing workflow.
        const query = search.text.toLowerCase();
        matches = ClipboardHistory.entries.filter(entry => {
            const text = entry.label.toLowerCase();
            let offset = 0;
            for (const character of query) {
                const index = text.indexOf(character, offset);
                if (index < 0)
                    return false;
                offset = index + 1;
            }
            return true;
        });
        selectedIndex = 0;
        history.positionViewAtBeginning();
    }

    function moveSelection(delta: int): void {
        if (matches.length === 0)
            return;
        selectedIndex = Math.max(0, Math.min(matches.length - 1, selectedIndex + delta));
        history.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function handleKey(event): void {
        const control = (event.modifiers & Qt.ControlModifier) !== 0;
        if (event.key === Qt.Key_Down || (control && (event.key === Qt.Key_J || event.key === Qt.Key_N)))
            moveSelection(1);
        else if (event.key === Qt.Key_Up || (control && (event.key === Qt.Key_K || event.key === Qt.Key_P)))
            moveSelection(-1);
        else if (event.key === Qt.Key_PageDown)
            moveSelection(Math.max(1, Math.floor(history.height / 42)));
        else if (event.key === Qt.Key_PageUp)
            moveSelection(-Math.max(1, Math.floor(history.height / 42)));
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            ClipboardHistory.restore(selectedEntry);
        else if (control && event.key === Qt.Key_R)
            ClipboardHistory.refresh();
        else if (event.key === Qt.Key_Escape)
            close();
        else
            return;
        event.accepted = true;
    }

    IpcHandler {
        target: "clipboard"
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function toggle(): void {
            if (root.shown)
                root.close();
            else
                root.open();
        }
    }

    Connections {
        target: ClipboardHistory
        function onEntriesChanged(): void { root.filter(); }
        function onRestored(): void { root.close(); }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Item {
            width: parent.width
            height: 32

            AppText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf0ea  Clipboard history"
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            ActionCapsule {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                color: Colors.palette.surfaceVariant
                content.text: "\uf00d"
                onClicked: root.close()
            }
        }

        Row {
            width: parent.width
            height: parent.height - 32 - 24 - 24
            spacing: 12

            Rectangle {
                id: listPane
                width: Math.round((parent.width - parent.spacing) * 0.42)
                height: parent.height
                radius: 10
                color: Colors.palette.surfaceContainerLow
                border.color: Colors.palette.outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 24

                        AppText {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "History"
                            color: Colors.palette.surfaceVariantText
                            font.pixelSize: 11
                        }

                        AppText {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: `${root.matches.length} / ${ClipboardHistory.entries.length}`
                            color: Colors.palette.surfaceVariantText
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: 8
                        color: Colors.palette.surfaceVariant
                        border.color: search.activeFocus ? Colors.palette.primary : Colors.palette.outlineVariant

                        AppText {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf105"
                            color: Colors.palette.primary
                            font.pixelSize: 15
                        }

                        TextInput {
                            id: search
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 12
                            anchors.leftMargin: 30
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.palette.surfaceText
                            selectionColor: Colors.palette.secondary
                            selectedTextColor: Colors.palette.secondaryText
                            font.family: Typography.fontFamily
                            font.pixelSize: 12
                            selectByMouse: true
                            clip: true
                            onTextChanged: root.filter()
                            Keys.onPressed: event => root.handleKey(event)
                        }

                        AppText {
                            anchors.left: search.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search history…"
                            visible: search.text === ""
                            color: Colors.palette.surfaceVariantText
                            font.pixelSize: 11
                        }
                    }

                    ListView {
                        id: history
                        width: parent.width
                        height: parent.height - y
                        clip: true
                        spacing: 4
                        model: root.matches
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: entryRow
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === root.selectedIndex
                            width: history.width
                            height: 38
                            radius: 6
                            color: selected ? Colors.palette.secondaryContainer : "transparent"
                            border.color: hover.hovered ? Colors.palette.outlineVariant : "transparent"

                            AppText {
                                id: entryIcon
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: entryRow.modelData.mime ? "\uf03e" : (entryRow.modelData.binary ? "\uf15b" : "\uf15c")
                                color: entryRow.selected ? Colors.palette.secondaryContainerText : Colors.palette.surfaceVariantText
                                font.pixelSize: 12
                            }

                            AppText {
                                anchors.left: entryIcon.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: entryRow.modelData.label
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: entryRow.selected ? Colors.palette.secondaryContainerText : Colors.palette.surfaceText
                                font.pixelSize: 11
                            }

                            HoverHandler { id: hover }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.selectedIndex = entryRow.index;
                                    search.forceActiveFocus();
                                }
                                onDoubleClicked: ClipboardHistory.restore(entryRow.modelData)
                            }
                        }

                        AppText {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            visible: root.matches.length === 0
                            text: ClipboardHistory.loading ? "Loading history…"
                                : ClipboardHistory.listError || (ClipboardHistory.entries.length === 0 ? "Your clipboard history is empty" : "No matches")
                            textFormat: Text.PlainText
                            color: ClipboardHistory.listError ? Colors.palette.error : Colors.palette.surfaceVariantText
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            ClipboardPreview {
                width: parent.width - listPane.width - parent.spacing
                height: parent.height
                entry: root.selectedEntry
            }
        }

        AppText {
            width: parent.width
            height: 24
            text: ClipboardHistory.restoring ? "Restoring clipboard…" : "↑ ↓ / Ctrl J K  navigate    Enter  copy to clipboard    Ctrl R  refresh    Esc  close"
            color: Colors.palette.surfaceVariantText
            font.pixelSize: 10
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
