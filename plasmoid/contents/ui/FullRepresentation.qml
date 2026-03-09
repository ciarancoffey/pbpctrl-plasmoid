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
        PlasmaComponents.Label { text: root.battery.caseLevel >= 0 ? root.battery.caseLevel + "%" : "—" }
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
                        root.runSet("set anc " + modelData.value, function() {
                            root.ancState = modelData.value;
                        });
                    }
                }
            }
        }
    }

    Kirigami.Separator { Layout.fillWidth: true; visible: root.connected }

    // Audio profile toggle (A2DP vs Headset)
    RowLayout {
        Layout.fillWidth: true
        visible: root.btCard !== ""

        Kirigami.Icon {
            source: root.isHeadsetMode ? "mic-on" : "audio-headphones"
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
        }

        PlasmaComponents.Label {
            text: root.isHeadsetMode ? "Headset (with mic)" : "Playback (high quality)"
            Layout.fillWidth: true
        }

        PlasmaComponents.Button {
            text: root.isHeadsetMode ? "Switch to Playback" : "Switch to Headset"
            icon.name: root.isHeadsetMode ? "audio-headphones" : "mic-on"
            onClicked: root.toggleProfile()
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
                    root.runSet("set speech-detection " + (checked ? "true" : "false"), null);
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
                    root.runSet("set ohd " + (checked ? "true" : "false"), null);
                    root.ohd = checked;
                }
            }
        }
    }

    Kirigami.Separator { Layout.fillWidth: true; visible: root.connected }

    // EQ
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.connected
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label { text: "Equalizer"; font.bold: true; Layout.fillWidth: true }
            PlasmaComponents.Label {
                text: "Volume EQ"
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7
            }
            PlasmaComponents.Switch {
                checked: root.volumeEq
                onToggled: {
                    root.runSet("set volume-eq " + (checked ? "true" : "false"));
                    root.volumeEq = checked;
                }
            }
        }

        Repeater {
            model: [
                { label: "Low Bass",     index: 0 },
                { label: "Bass",         index: 1 },
                { label: "Mid",          index: 2 },
                { label: "Treble",       index: 3 },
                { label: "Upper Treble", index: 4 },
            ]

            RowLayout {
                required property var modelData
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    text: modelData.label
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                }

                PlasmaComponents.Slider {
                    id: eqSlider
                    Layout.fillWidth: true
                    from: -6.0
                    to: 6.0
                    stepSize: 0.5
                    value: root.eq[modelData.index] ?? 0.0
                    onMoved: eqDebounce.restart()

                    Timer {
                        id: eqDebounce
                        interval: 600
                        onTriggered: {
                            var bands = root.eq.slice();
                            bands[modelData.index] = eqSlider.value;
                            root.setEq(bands);
                        }
                    }
                }

                PlasmaComponents.Label {
                    text: (eqSlider.value >= 0 ? "+" : "") + eqSlider.value.toFixed(1)
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
