pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

Rectangle {
    id: root
    property var entry: null

    radius: 10
    color: Colors.palette.surfaceContainerLow
    border.color: Colors.palette.outlineVariant

    AppText {
        id: heading
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 20
        text: root.entry?.mime ? "\uf03e  Image preview" : "Preview"
        color: Colors.palette.surfaceVariantText
        font.pixelSize: 11
    }

    Item {
        anchors.top: heading.bottom
        anchors.bottom: metadata.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        clip: true

        Image {
            id: image
            anchors.fill: parent
            source: ClipboardHistory.imageSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            visible: root.entry?.mime !== "" && status === Image.Ready
            onStatusChanged: {
                if (status === Image.Error)
                    ClipboardHistory.notifyError("Could not display this image.");
            }
        }

        Flickable {
            id: textScroll
            anchors.fill: parent
            visible: root.entry !== null && !root.entry.binary && !ClipboardHistory.previewLoading
            contentWidth: width
            contentHeight: textPreview.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            AppText {
                id: textPreview
                width: textScroll.width
                text: ClipboardHistory.previewText
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
                font.pixelSize: 12
                lineHeight: 1.35
                onTextChanged: textScroll.contentY = 0
            }
        }

        AppText {
            anchors.centerIn: parent
            width: parent.width - 24
            visible: !root.entry || ClipboardHistory.previewLoading || ClipboardHistory.previewError !== ""
                || (root.entry.binary && !root.entry.mime) || image.status === Image.Error
            text: {
                if (!root.entry)
                    return "Select an entry to preview";
                if (ClipboardHistory.previewLoading)
                    return "Loading preview…";
                if (ClipboardHistory.previewError)
                    return ClipboardHistory.previewError;
                if (image.status === Image.Error)
                    return "This image could not be displayed";
                return "No preview for this binary format";
            }
            color: ClipboardHistory.previewError || image.status === Image.Error
                ? Colors.palette.error : Colors.palette.surfaceVariantText
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }

    AppText {
        id: metadata
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 20
        text: {
            if (!root.entry)
                return "";
            if (root.entry.mime && image.status === Image.Ready)
                return `${root.entry.format.toUpperCase()}  ·  ${image.sourceSize.width} × ${image.sourceSize.height}`;
            if (ClipboardHistory.textTruncated)
                return "Preview truncated · the complete entry will be copied";
            return root.entry.binary ? root.entry.format.toUpperCase() : "Text";
        }
        color: Colors.palette.surfaceVariantText
        font.pixelSize: 10
        elide: Text.ElideRight
    }
}
