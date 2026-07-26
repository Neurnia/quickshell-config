import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.services

ActionCapsule {
    property int maximumWidth: 400

    content.text: Hyprland.activeToplevel?.title ?? ""
    content.width: Math.min(content.implicitWidth, maximumWidth - horizontalPadding)
    content.elide: Text.ElideRight
    content.horizontalAlignment: Text.AlignHCenter

    onClicked: Overview.toggle()
}
