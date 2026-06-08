pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    minimumWidth: 300
    minimumHeight: 200
    property list<var> resources: [
        {
            "icon": "planner_review",
            "name": Translation.tr("CPU"),
            "history": ResourceUsage.cpuUsageHistory,
            "maxAvailableString": ResourceUsage.maxAvailableCpuString
        },
        {
            "icon": "memory",
            "name": Translation.tr("RAM"),
            "history": ResourceUsage.memoryUsageHistory,
            "maxAvailableString": ResourceUsage.maxAvailableMemoryString
        },
        {
            "icon": "swap_horiz",
            "name": Translation.tr("Swap"),
            "history": ResourceUsage.swapUsageHistory,
            "maxAvailableString": ResourceUsage.maxAvailableSwapString
        },
        {
            "icon": "thermostat",
            "name": Translation.tr("Temperature"),
            "history": [],
            "maxAvailableString": "--",
            "isTemperature": true
        },
        {
            "icon": "air",
            "name": Translation.tr("Fan"),
            "history": [],
            "maxAvailableString": "--",
            "isFan": true
        },
    ]

    contentItem: OverlayBackground {
        id: contentItem
        radius: root.contentRadius
        property real padding: 4
        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: parent.padding
            }
            spacing: 8

            SecondaryTabBar {
                id: tabBar

                currentIndex: Persistent.states.overlay.resources.tabIndex
                onCurrentIndexChanged: {
                    Persistent.states.overlay.resources.tabIndex = tabBar.currentIndex;
                }

                Repeater {
                    model: root.resources.length
                    delegate: SecondaryTabButton {
                        required property int index
                        property var modelData: root.resources[index]
                        buttonIcon: modelData.icon
                        buttonText: modelData.name
                    }
                }
            }

            ResourceSummary {
                Layout.margins: 8
                history: root.resources[tabBar.currentIndex]?.history ?? []
                maxAvailableString: root.resources[tabBar.currentIndex]?.maxAvailableString ?? "--"
            }
        }
    }

    component ResourceSummary: RowLayout {
        id: resourceSummary
        required property list<real> history
        required property string maxAvailableString
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        ColumnLayout {
            spacing: 2
            StyledText {
                text: {
                    const currentResource = root.resources[tabBar.currentIndex]
                    if (currentResource?.isTemperature) {
                        return ResourceUsage.cpuTemperatureCelsius.toFixed(1) + "°C"
                    }
                    if (currentResource?.isFan) {
                        return "L" + ResourceUsage.fanLevel
                    }
                    return (resourceSummary.history[resourceSummary.history.length - 1] * 100).toFixed(1) + "%"
                }
                font {
                    family: Appearance.font.family.numbers
                    variableAxes: Appearance.font.variableAxes.numbers
                    pixelSize: Appearance.font.pixelSize.huge
                }
            }
            StyledText {
                text: {
                    const currentResource = root.resources[tabBar.currentIndex]
                    if (currentResource?.isTemperature) {
                        return Translation.tr("CPU Package")
                    }
                    if (currentResource?.isFan) {
                        return ResourceUsage.fanSpeed + " RPM"
                    }
                    return Translation.tr("of %1").arg(resourceSummary.maxAvailableString)
                }
                font {
                    // family: Appearance.font.family.numbers
                    // variableAxes: Appearance.font.variableAxes.numbers
                    pixelSize: Appearance.font.pixelSize.smallie
                }
                color: Appearance.colors.colSubtext
            }
            Item {
                Layout.fillHeight: true
            }
        }
        Rectangle {
            id: graphBg
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.small
            color: Appearance.colors.colSecondaryContainer
            visible: !root.resources[tabBar.currentIndex]?.isTemperature && !root.resources[tabBar.currentIndex]?.isFan
            layer.enabled: visible
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: graphBg.width
                    height: graphBg.height
                    radius: graphBg.radius
                }
            }
            Graph {
                anchors.fill: parent
                values: root.resources[tabBar.currentIndex]?.history ?? []
                points: ResourceUsage.historyLength
                alignment: Graph.Alignment.Right
            }
        }
    }
}
