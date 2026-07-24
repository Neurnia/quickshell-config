import QtQuick
import qs.components

ActionCapsule {
    id: root

    signal menuRequested

    width: height
    content.text: "\uf011"
    onClicked: root.menuRequested()
}
