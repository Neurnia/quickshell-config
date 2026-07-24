import QtQuick
import qs.components
import qs.services

ActionCapsule {
    id: root

    signal menuRequested

    width: height
    content.text: "\uf011"
    onClicked: root.menuRequested()
}
