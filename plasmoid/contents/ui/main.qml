import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property string ancState: "unknown"
    property var battery: ({ left: -1, right: -1, caseLevel: -1 })
    property bool speechDetection: false
    property bool ohd: false
    property bool connected: false
    property int failCount: 0
    readonly property int maxFails: 3

    Plasmoid.icon: "audio-headphones"
    Plasmoid.title: "Pixel Buds Pro"

    function ancStateLabel(state) {
        switch (state) {
            case "off":       return "ANC: Off";
            case "active":    return "ANC: Active";
            case "aware":     return "Aware (Transparency)";
            case "adaptive":  return "ANC: Adaptive";
            default:          return "ANC: Unknown";
        }
    }

    // Single DataSource runs all queries sequentially in one shell command
    P5Support.DataSource {
        id: dsRefresh
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            var stdout = data["stdout"] || "";
            var stderr = data["stderr"] || "";

            if (stderr !== "" || stdout === "") {
                failCount += 1;
                if (failCount >= maxFails) connected = false;
            } else {
                failCount = 0;
                connected = true;

                // ANC: line "ANC=aware"
                var anc = stdout.match(/^ANC=(.+)$/m);
                if (anc) ancState = anc[1].trim().toLowerCase();

                // Battery
                var left  = stdout.match(/left\s+bud\s*:\s*(\d+)/i);
                var right = stdout.match(/right\s+bud\s*:\s*(\d+)/i);
                var cas   = stdout.match(/case\s*:\s*(\d+)/i);
                battery = {
                    left:      left  ? parseInt(left[1])  : -1,
                    right:     right ? parseInt(right[1]) : -1,
                    caseLevel: cas   ? parseInt(cas[1])   : -1
                };

                // Toggles
                var speech = stdout.match(/^SPEECH=(.+)$/m);
                if (speech) speechDetection = speech[1].trim().toLowerCase() === "true";

                var ohdMatch = stdout.match(/^OHD=(.+)$/m);
                if (ohdMatch) ohd = ohdMatch[1].trim().toLowerCase() === "true";
            }

            disconnectSource(source);
        }
    }

    // Separate DataSource for fire-and-forget set commands
    P5Support.DataSource {
        id: dsSet
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source);
            // Re-query ANC state after a set command
            Qt.callLater(refresh);
        }
    }

    function runSet(args) {
        dsSet.connectSource("pbpctrl " + args);
    }

    readonly property string refreshCmd:
        "sh -c 'echo ANC=$(pbpctrl get anc); pbpctrl show battery; " +
        "echo SPEECH=$(pbpctrl get speech-detection); echo OHD=$(pbpctrl get ohd)'"

    function refresh() {
        dsRefresh.connectSource(refreshCmd);
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: refresh()
    }

    Component.onCompleted: refresh()

    fullRepresentation: FullRepresentation {}
}
