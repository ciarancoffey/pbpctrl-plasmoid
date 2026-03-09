import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    Kirigami.Icon {
        anchors.fill: parent
        source: "audio-headphones"
        active: mouseArea.containsMouse
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
    }
}
