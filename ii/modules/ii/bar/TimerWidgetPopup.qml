// ii/modules/ii/bar/TimerWidgetPopup.qml

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    signal durationSelected(int duration)

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8

        StyledPopupHeaderRow {
            icon: "timer"
            label: Translation.tr("Pomodoro Timer")
        }

        StyledPopupValueRow {
            icon: "schedule"
            label: Translation.tr("Status:")
            value: TimerService.pomodoroRunning
                   ? (TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus"))
                   : Translation.tr("Stopped")
        }

        StyledPopupValueRow {
            icon: "loop"
            label: Translation.tr("Cycle:")
            value: TimerService.pomodoroCycle + 1 + " / " + TimerService.cyclesBeforeLongBreak
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            RippleButton {
                buttonText: TimerService.pomodoroRunning ? Translation.tr("Pause") : Translation.tr("Start")
                onClicked: TimerService.togglePomodoro()
            }

            RippleButton {
                buttonText: Translation.tr("Reset")
                onClicked: TimerService.resetPomodoro()
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            RippleButton {
                buttonText: "5m"
                onClicked: {
                    // Would need to implement set duration in TimerService
                    // For now just show notification
                }
            }

            RippleButton {
                buttonText: "10m"
                onClicked: {
                }
            }

            RippleButton {
                buttonText: "25m"
                onClicked: {
                }
            }
        }
    }
}