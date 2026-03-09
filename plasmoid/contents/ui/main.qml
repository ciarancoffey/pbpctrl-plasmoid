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
    property string btCard: ""
    property string btProfile: ""
    property var eq: [0.0, 0.0, 0.0, 0.0, 0.0]
    property bool volumeEq: false

    readonly property bool isHeadsetMode: btProfile.startsWith("headset")
    readonly property string preferredA2dp: "a2dp-sink-opus_g"
    readonly property string preferredHfp: "headset-head-unit"

    Plasmoid.icon: "audio-headphones"
    Plasmoid.title: "Pixel Buds Pro"
    Plasmoid.status: connected ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

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

                var eqMatch = stdout.match(/^EQ=\[([^\]]+)\]/m);
                if (eqMatch) {
                    var vals = eqMatch[1].split(",").map(function(v) { return parseFloat(v.trim()); });
                    if (vals.length === 5) eq = vals;
                }

                var veqMatch = stdout.match(/^VOLUMEEQ=(.+)$/m);
                if (veqMatch) volumeEq = veqMatch[1].trim().toLowerCase() === "true";
            }

            disconnectSource(source);
        }
    }

    // DataSource for reading BT card profile via pactl (local, no BT channel)
    P5Support.DataSource {
        id: dsProfileRead
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            var stdout = data["stdout"] || "";
            var cardMatch   = stdout.match(/Name:\s+(bluez_card\S+)/);
            var profileMatch = stdout.match(/Active Profile:\s+(\S+)/);
            if (cardMatch)   btCard    = cardMatch[1].trim();
            if (profileMatch) btProfile = profileMatch[1].trim();
            disconnectSource(source);
        }
    }

    // DataSource for setting BT card profile via pactl
    P5Support.DataSource {
        id: dsProfileSet
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source);
        }
    }

    function toggleProfile() {
        if (btCard === "") return;
        var target = isHeadsetMode ? preferredA2dp : preferredHfp;
        btProfile = target;  // optimistic update so button flips immediately
        dsProfileSet.connectSource("pactl set-card-profile " + btCard + " " + target);
    }

    // Separate DataSource for fire-and-forget set commands
    P5Support.DataSource {
        id: dsSet
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source);
        }
    }

    function runSet(args) {
        dsSet.connectSource("pbpctrl " + args);
    }

    function setEq(bands) {
        eq = bands;
        runSet("set eq " + bands[0].toFixed(1) + " " + bands[1].toFixed(1) + " " +
               bands[2].toFixed(1) + " " + bands[3].toFixed(1) + " " + bands[4].toFixed(1));
    }

    readonly property string refreshCmd:
        "sh -c 'echo ANC=$(pbpctrl get anc); pbpctrl show battery; " +
        "echo SPEECH=$(pbpctrl get speech-detection); echo OHD=$(pbpctrl get ohd); " +
        "echo EQ=$(pbpctrl get eq); echo VOLUMEEQ=$(pbpctrl get volume-eq)'"

    readonly property string profileCmd:
        "pactl list cards | grep -E 'Name: bluez_card|Active Profile:'"

    function refresh() {
        dsRefresh.disconnectSource(refreshCmd);
        dsRefresh.connectSource(refreshCmd);
        dsProfileRead.disconnectSource(profileCmd);
        dsProfileRead.connectSource(profileCmd);
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
