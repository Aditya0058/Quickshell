// ii/modules/ii/bar/StopwatchWidget.qml

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool showStopwatch: Config.options.bar.verbose

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    function formatTime(tenMs) {
        var seconds = Math.floor(tenMs / 100)
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        var s = seconds % 60

        function pad(v) {
            return v < 10 ? "0" + v : "" + v
        }

        if (h > 0)
            return pad(h) + ":" + pad(m) + ":" + pad(s)

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
            text: root.formatTime(TimerService.stopwatchTime)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            TimerService.toggleStopwatch()
        }

        StopwatchWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}