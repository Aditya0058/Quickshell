// ii/modules/ii/bar/StopwatchWidgetPopup.qml

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    signal startRequested()
    signal pauseRequested()
    signal resetRequested()

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8

        StyledPopupHeaderRow {
            icon: "timer"
            label: Translation.tr("Stopwatch")
        }

        StyledPopupValueRow {
            icon: "timelapse"
            label: Translation.tr("Status:")
            value: TimerService.stopwatchRunning
                   ? Translation.tr("Running")
                   : Translation.tr("Stopped")
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            RippleButton {
                buttonText: TimerService.stopwatchRunning ? Translation.tr("Pause") : Translation.tr("Start")
                onClicked: TimerService.toggleStopwatch()
            }

            RippleButton {
                buttonText: Translation.tr("Reset")
                onClicked: TimerService.stopwatchReset()
            }
        }
    }
}