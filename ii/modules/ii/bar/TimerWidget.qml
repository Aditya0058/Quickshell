// ii/modules/ii/bar/TimerWidget.qml

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool showTimer: Config.options.bar.verbose

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    function formatTime(seconds) {
        var secs = Math.max(0, seconds)
        var m = Math.floor(secs / 60)
        var s = secs % 60

        function pad(v) {
            return v < 10 ? "0" + v : "" + v
        }

        return pad(m) + ":" + pad(s)
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            animateChange: true
            text: root.formatTime(TimerService.pomodoroSecondsLeft)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            TimerService.togglePomodoro()
        }

        TimerWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}