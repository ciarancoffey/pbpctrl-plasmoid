import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: fullRoot
    spacing: Kirigami.Units.smallSpacing
    implicitWidth: Kirigami.Units.gridUnit * 16

    // Header
    RowLayout {
        Layout.fillWidth: true

        Kirigami.Icon {
            source: "audio-headphones"
            implicitWidth: Kirigami.Units.iconSizes.medium
            implicitHeight: Kirigami.Units.iconSizes.medium
        }

        ColumnLayout {
            spacing: 0
            PlasmaComponents.Label {
                text: "Pixel Buds Pro"
                font.bold: true
            }
            PlasmaComponents.Label {
                text: root.connected ? "Connected" : "Not connected"
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7
            }
        }

        Item { Layout.fillWidth: true }

        PlasmaComponents.ToolButton {
            icon.name: "view-refresh"
            onClicked: root.refresh()
            PlasmaComponents.ToolTip.text: "Refresh"
            PlasmaComponents.ToolTip.visible: hovered
        }
    }

    Kirigami.Separator { Layout.fillWidth: true }

    // Battery
    RowLayout {
        Layout.fillWidth: true
        visible: root.connected

        Kirigami.Icon {
            source: "battery"
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
        }

        PlasmaComponents.Label { text: "L:"; font.bold: true }
        PlasmaComponents.Label { text: root.battery.left >= 0 ? root.battery.left + "%" : "—" }
        PlasmaComponents.Label { text: "R:"; font.bold: true }
        PlasmaComponents.Label { text: root.battery.right >= 0 ? root.battery.right + "%" : "—" }
        PlasmaComponents.Label { text: "Case:"; font.bold: true }
        PlasmaComponents.Label { text: root.battery.case >= 0 ? root.battery.case + "%" : "—" }
    }

    Kirigami.Separator { Layout.fillWidth: true; visible: root.connected }

    // ANC Mode
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.connected
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            text: "Noise Control"
            font.bold: true
        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            Repeater {
                model: [
                    { label: "Off",          value: "off",      icon: "audio-volume-muted" },
                    { label: "Active ANC",   value: "active",   icon: "audio-volume-low" },
                    { label: "Aware",        value: "aware",    icon: "audio-volume-high" },
                    { label: "Adaptive",     value: "adaptive", icon: "audio-volume-medium" },
                ]

                PlasmaComponents.Button {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.label
                    icon.name: modelData.icon
                    flat: root.ancState !== modelData.value
                    highlighted: root.ancState === modelData.value
                    onClicked: {
                        root.runPbpctrl("set anc " + modelData.value, function() {
                            root.ancState = modelData.value;
                        });
                    }
                }
            }
        }
    }

    Kirigami.Separator { Layout.fillWidth: true; visible: root.connected }

    // Toggles
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.connected
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label { text: "Auto Transparency (Speech)"; Layout.fillWidth: true }
            PlasmaComponents.Switch {
                checked: root.speechDetection
                onToggled: {
                    root.runPbpctrl("set speech-detection " + (checked ? "true" : "false"), null);
                    root.speechDetection = checked;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label { text: "On-head Detection"; Layout.fillWidth: true }
            PlasmaComponents.Switch {
                checked: root.ohd
                onToggled: {
                    root.runPbpctrl("set ohd " + (checked ? "true" : "false"), null);
                    root.ohd = checked;
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
