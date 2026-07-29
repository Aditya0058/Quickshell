import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    title: Translation.tr("Stopwatch")
    showCenterButton: false

    contentItem: StopwatchContent {
        radius: root.contentRadius
        isClickthrough: root.clickthrough
    }
}
