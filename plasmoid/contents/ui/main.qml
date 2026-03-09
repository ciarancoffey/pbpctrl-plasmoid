import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property string ancState: "unknown"
    property var battery: ({ left: -1, right: -1, case: -1 })
    property bool speechDetection: false
    property bool ohd: false
    property bool connected: false

    preferredRepresentation: compactRepresentation

    Plasmoid.icon: "audio-headphones"
    Plasmoid.title: "Pixel Buds Pro"
    Plasmoid.toolTipMainText: "Pixel Buds Pro"
    Plasmoid.toolTipSubText: connected ? ancStateLabel(ancState) : "Not connected"

    function ancStateLabel(state) {
        switch (state) {
            case "off":       return "ANC: Off";
            case "active":    return "ANC: Active";
            case "aware":     return "Aware (Transparency)";
            case "adaptive":  return "ANC: Adaptive";
            default:          return "ANC: Unknown";
        }
    }

    function runPbpctrl(args, callback) {
        var proc = Qt.createQmlObject('import QtQuick; import org.kde.plasma.core as PlasmaCore; PlasmaCore.DataSource { engine: "executable" }', root);
        proc.connectSource("pbpctrl " + args);
        proc.onNewData.connect(function(source, data) {
            if (callback) callback(data["stdout"], data["stderr"]);
            proc.disconnectSource(source);
            proc.destroy();
        });
    }

    function refresh() {
        // Get ANC state
        runPbpctrl("get anc", function(stdout, stderr) {
            if (stderr === "") {
                connected = true;
                ancState = stdout.trim().toLowerCase();
            } else {
                connected = false;
                ancState = "unknown";
            }
        });

        // Get battery
        runPbpctrl("show battery", function(stdout) {
            var left = stdout.match(/left[^\d]*(\d+)/i);
            var right = stdout.match(/right[^\d]*(\d+)/i);
            var cas = stdout.match(/case[^\d]*(\d+)/i);
            battery = {
                left:  left  ? parseInt(left[1])  : -1,
                right: right ? parseInt(right[1]) : -1,
                case:  cas   ? parseInt(cas[1])   : -1
            };
        });

        // Get speech detection
        runPbpctrl("get speech-detection", function(stdout) {
            speechDetection = stdout.trim().toLowerCase() === "true";
        });

        // Get on-head detection
        runPbpctrl("get ohd", function(stdout) {
            ohd = stdout.trim().toLowerCase() === "true";
        });
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: refresh()
    }

    Component.onCompleted: refresh()

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}
}
