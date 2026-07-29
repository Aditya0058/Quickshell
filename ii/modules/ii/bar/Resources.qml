import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        // Day remaining with 2 decimal places - custom display
        Item {
            implicitWidth: dayRemainingRow.implicitWidth
            implicitHeight: Appearance.sizes.barHeight
            Layout.leftMargin: -8

            RowLayout {
                id: dayRemainingRow
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                ClippedFilledCircularProgress {
                    id: dayCircProg
                    Layout.alignment: Qt.AlignVCenter
                    lineWidth: Appearance.rounding.unsharpen
                    value: ResourceUsage.dayRemainingPercentage
                    implicitSize: 20
                    colPrimary: ResourceUsage.dayRemainingPercentage < 0.1 ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
                    accountForLightBleeding: ResourceUsage.dayRemainingPercentage >= 0.1
                    enableAnimation: false

                    Item {
                        anchors.centerIn: parent
                        width: dayCircProg.implicitSize
                        height: dayCircProg.implicitSize

                        MaterialSymbol {
                            anchors.centerIn: parent
                            font.weight: Font.DemiBold
                            fill: 1
                            text: "schedule"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.m3colors.m3onSecondaryContainer
                        }
                    }
                }

                Item {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: dayPercentTextMetrics.width
                    implicitHeight: dayPercentText.implicitHeight

                    TextMetrics {
                        id: dayPercentTextMetrics
                        text: "100.00"
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                    StyledText {
                        id: dayPercentText
                        anchors.centerIn: parent
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: `${(ResourceUsage.dayRemainingPercentage * 100).toFixed(2)}`
                    }
                }
            }
        }

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options.bar.resources.alwaysShowSwap && percentage > 0) ||
                (MprisController.activePlayer?.trackTitle == null) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu ||
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            iconName: "thermostat"
            percentage: ResourceUsage.temperature / 100 // Normalize to 0-1 range for display (0-100°C -> 0-1)
            shown: true
            Layout.leftMargin: 6
            warningThreshold: 70 // Warning at 70°C
        }

        Resource {
            iconName: "air"
            percentage: ResourceUsage.fanLevel / 7 // Normalize to 0-1 range (0-7 levels -> 0-1)
            shown: true
            Layout.leftMargin: 6
            warningThreshold: 5 // Warning at level 5+
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
