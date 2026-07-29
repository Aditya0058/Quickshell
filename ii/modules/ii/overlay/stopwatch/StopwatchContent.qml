import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

OverlayBackground {
    id: root

    property bool isClickthrough: false

    // ---- Timing state ----
    // elapsedMs is the authoritative "time on the clock".
    // runStartEpoch is Date.now() at the moment we last pressed Start/Resume.
    // While running, displayed time = elapsedMs + (Date.now() - runStartEpoch).
    // This avoids drift from relying on tick-count * interval.
    property bool isRunning: false
    property real elapsedMs: 0
    property real runStartEpoch: 0

    readonly property real currentElapsedMs: isRunning ? (elapsedMs + (nowTick - runStartEpoch)) : elapsedMs
    property real nowTick: Date.now()

    // Scale factor for responsive sizing
    readonly property real compactScale: Math.max(0.6, Math.min(1, Math.min(root.width / root.implicitWidth, root.height / root.implicitHeight)))

    implicitWidth: 280
    implicitHeight: 180

    function start() {
        if (isRunning)
            return;
        runStartEpoch = Date.now();
        isRunning = true;
        tickTimer.start();
    }

    function pause() {
        if (!isRunning)
            return;
        elapsedMs += Date.now() - runStartEpoch;
        isRunning = false;
        tickTimer.stop();
        nowTick = Date.now();
    }

    function reset() {
        tickTimer.stop();
        isRunning = false;
        elapsedMs = 0;
        runStartEpoch = 0;
        nowTick = Date.now();
    }

    function formatTime(ms) {
        const totalMs = Math.max(0, Math.floor(ms));
        const totalSeconds = Math.floor(totalMs / 1000);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = totalSeconds % 60;
        const centis = Math.floor((totalMs % 1000) / 10);

        const pad2 = n => n < 10 ? "0" + n : "" + n;

        if (hours > 0) {
            return pad2(hours) + ":" + pad2(minutes) + ":" + pad2(seconds) + "." + pad2(centis);
        }
        return pad2(minutes) + ":" + pad2(seconds) + "." + pad2(centis);
    }

    Timer {
        id: tickTimer
        interval: 31 // ~32fps repaint; time math itself is epoch-based, not tick-based
        repeat: true
        running: false
        onTriggered: root.nowTick = Date.now()
    }

    ColumnLayout {
        id: contentItem
        anchors.fill: parent
        anchors.margins: Math.round(24 * root.compactScale)
        spacing: Math.round(16 * root.compactScale)

        // ---- Big time readout ----
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(70 * root.compactScale)

            StyledText {
                anchors.centerIn: parent
                text: root.formatTime(root.currentElapsedMs)
                font.pixelSize: Math.round(46 * root.compactScale)
                font.weight: Font.DemiBold
                font.family: Appearance.font.family?.monospace ?? Appearance.font.family.main
                color: Appearance.colors.colOnLayer1
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // ---- Controls row ----
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(4 * root.compactScale)
            spacing: Math.round(12 * root.compactScale)

            RippleButton {
                id: resetButton
                Layout.fillWidth: true
                implicitHeight: Math.round(40 * root.compactScale)
                buttonRadius: Math.round(10 * root.compactScale)
                enabled: root.elapsedMs > 0 || root.isRunning

                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("Reset")
                    font.pixelSize: Math.round(Appearance.font.pixelSize.normal * root.compactScale)
                    color: resetButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                }

                onClicked: root.reset()
            }

            RippleButton {
                id: startPauseButton
                Layout.fillWidth: true
                implicitHeight: Math.round(40 * root.compactScale)
                buttonRadius: Math.round(10 * root.compactScale)

                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: root.isRunning ? Translation.tr("Pause") : Translation.tr("Start")
                    font.pixelSize: Math.round(Appearance.font.pixelSize.normal * root.compactScale)
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                onClicked: root.isRunning ? root.pause() : root.start()
            }
        }
    }
}