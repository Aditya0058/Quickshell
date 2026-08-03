import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "monthlyGoals"

    implicitWidth: 420
    implicitHeight: root.expanded ? 520 : 170

    // ----- state -----
    readonly property bool expandedCard: root.expanded
    readonly property bool editMode: editToggle.checked
    readonly property bool addMode: addToggle.checked
    readonly property bool allDone: MonthlyGoals.totalCount > 0 && MonthlyGoals.progress >= 1.0
    readonly property bool isEmpty: MonthlyGoals.totalCount === 0

    // Header icon: 🏆 at 100%, 🔥 above 70%, 🎯 otherwise.
    function headerIconName() {
        if (root.allDone) return "emoji_events";
        if (MonthlyGoals.progress >= 0.7) return "local_fire_department";
        return "track_changes";
    }

    readonly property string monthLabel: {
        const d = new Date();
        return d.toLocaleString(Qt.locale(), "MMMM yyyy");
    }

    // Subtitle: "3 of 8 Completed" / "All Goals Completed" / "Tap to add your first goal"
    readonly property string subtitle: {
        if (root.allDone) return Translation.tr("All Goals Completed");
        if (root.isEmpty) return Translation.tr("Tap below to add your first goal");
        return Translation.tr("%1 of %2 Completed")
            .arg(MonthlyGoals.completedCount)
            .arg(MonthlyGoals.totalCount);
    }

    // ----- celebration trigger -----
    // We pulse the progress bar / show a "🏆 All Done" overlay for ~2 seconds
    // each time MonthlyGoals.justCompleted transitions false → true.
    property bool celebrationShown: false
    Connections {
        target: MonthlyGoals
        function onJustCompletedChanged() {
            if (MonthlyGoals.justCompleted && !root.celebrationShown) {
                root.celebrationShown = true;
                celebrationHideTimer.restart();
            }
        }
    }
    Timer {
        id: celebrationHideTimer
        interval: 2200
        onTriggered: {
            root.celebrationShown = false;
            MonthlyGoals.acknowledgeCompletion();
        }
    }

    // ----- root card -----
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 28
        color: Appearance.colors.colPrimaryContainer
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.85)
        opacity: 0.96
        clip: true

        // Spring expand. Easing.OutBack gives a subtle bounce.
        Behavior on implicitHeight {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutBack
                easing.overshoot: 1.05
            }
        }

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // ============= HEADER =============
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Small circular progress ring beside the title.
                Item {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36

                    CircularProgress {
                        anchors.fill: parent
                        implicitSize: 36
                        value: MonthlyGoals.progress
                        lineWidth: 3
                        colPrimary: Appearance.colors.colPrimary
                        colSecondary: ColorUtils.transparentize(
                            Appearance.colors.colOnPrimaryContainer, 0.85)
                        animationDuration: 600
                        easingType: Easing.OutCubic
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.headerIconName()
                        iconSize: 16
                        color: Appearance.colors.colPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText {
                        text: Translation.tr("🎯 %1").arg(root.monthLabel)
                        color: Appearance.colors.colOnPrimaryContainer
                        font {
                            pixelSize: Appearance.font.pixelSize.large
                            weight: Font.Medium
                            family: Appearance.font.family.expressive
                        }
                    }
                    StyledText {
                        text: root.subtitle
                        color: ColorUtils.transparentize(
                            Appearance.colors.colOnPrimaryContainer, 0.4)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }

                // Edit mode toggle (only when expanded).
                Item {
                    id: editToggle
                    property bool checked: false
                    visible: false
                }
                Rectangle {
                    visible: root.expandedCard
                    width: 36; height: 36; radius: 18
                    color: editToggle.checked
                        ? Appearance.colors.colPrimary
                        : ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.85)
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "edit"
                        iconSize: Appearance.font.pixelSize.normal
                        color: editToggle.checked
                            ? Appearance.colors.colOnPrimary
                            : Appearance.colors.colOnPrimaryContainer
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: editToggle.checked = !editToggle.checked
                    }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                // Expand/collapse toggle.
                Item {
                    id: addToggle
                    property bool checked: false
                    visible: false
                }
                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.85)
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.expandedCard ? "expand_less" : "expand_more"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setExpanded(!root.expanded)
                    }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            // ============= PROGRESS BAR =============
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 8

                Rectangle {
                    id: progressTrack
                    anchors.fill: parent
                    radius: 4
                    color: ColorUtils.transparentize(
                        Appearance.colors.colOnPrimaryContainer, 0.85)
                }

                Rectangle {
                    id: progressFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * MonthlyGoals.progress
                    radius: 4
                    color: root.celebrationShown
                        ? ColorUtils.mix(Appearance.colors.colPrimary,
                            Appearance.colors.colOnPrimary, 0.3)
                        : Appearance.colors.colPrimary

                    // Glow halo on completion.
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: "transparent"
                        border.width: 2
                        border.color: Appearance.colors.colPrimary
                        opacity: root.celebrationShown ? 0.6 : 0
                        scale: root.celebrationShown ? 1.4 : 1
                        Behavior on opacity { NumberAnimation { duration: 400 } }
                        Behavior on scale { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }
                    }

                    Behavior on width {
                        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                    }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            // ============= GOAL LIST =============
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.expandedCard ? 320 : 0
                Layout.topMargin: root.expandedCard ? 4 : 0
                clip: true
                opacity: root.expandedCard ? 1 : 0

                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                // Empty state.
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.isEmpty
                    spacing: 8
                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "track_changes"
                        iconSize: 48
                        color: ColorUtils.transparentize(
                            Appearance.colors.colOnPrimaryContainer, 0.5)
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("No Monthly Goals Yet")
                        color: Appearance.colors.colOnPrimaryContainer
                        font {
                            pixelSize: Appearance.font.pixelSize.normal
                            weight: Font.Medium
                        }
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Click below to add your first goal.")
                        color: ColorUtils.transparentize(
                            Appearance.colors.colOnPrimaryContainer, 0.5)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }

                ListView {
                    id: goalList
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 6
                    clip: true
                    interactive: MonthlyGoals.goals.length > 5
                    model: MonthlyGoals.goals
                    visible: !root.isEmpty
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: -1

                    // Smooth add / remove / move transitions.
                    add: Transition {
                        NumberAnimation { properties: "opacity,y"; duration: 250; easing.type: Easing.OutCubic }
                    }
                    remove: Transition {
                        NumberAnimation { properties: "opacity,y"; duration: 220; easing.type: Easing.InCubic }
                    }
                    move: Transition {
                        NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutCubic }
                    }

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        width: ListView.view ? ListView.view.width : 0
                        height: 44
                        radius: 14
                        color: row.hovered
                            ? ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.9)
                            : "transparent"

                        property bool hovered: rowHover.containsMouse
                        property bool justChanged: false

                        Behavior on color { ColorAnimation { duration: 200 } }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 10

                            // ----- Animated checkmark -----
                            Item {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28

                                Rectangle {
                                    id: checkBg
                                    anchors.fill: parent
                                    radius: 14
                                    color: modelData.done
                                        ? Appearance.colors.colPrimary
                                        : "transparent"
                                    border.width: 2
                                    border.color: Appearance.colors.colPrimary
                                    Behavior on color { ColorAnimation { duration: 220 } }
                                }

                                MaterialSymbol {
                                    id: checkMark
                                    anchors.centerIn: parent
                                    visible: modelData.done
                                    text: "check"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnPrimary
                                    opacity: modelData.done ? 1 : 0
                                    scale: modelData.done ? 1 : 0.3
                                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    Behavior on scale {
                                        NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MonthlyGoals.toggleGoal(modelData.id)
                                }

                                // Whole control pops on press.
                                scale: pressArea.pressed ? 0.85 : 1
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                MouseArea {
                                    id: pressArea
                                    anchors.fill: parent
                                    visible: false
                                }
                            }

                            // ----- Goal text -----
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.text
                                color: modelData.done
                                    ? ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.55)
                                    : Appearance.colors.colOnPrimaryContainer
                                font {
                                    pixelSize: Appearance.font.pixelSize.normal
                                    strikeout: modelData.done
                                }
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            // ----- Delete (edit mode only) -----
                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 14
                                visible: root.editMode
                                opacity: root.editMode ? 1 : 0
                                color: delHover.containsMouse
                                    ? ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                                    : "transparent"
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "delete"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colError
                                }
                                MouseArea {
                                    id: delHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MonthlyGoals.removeGoal(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // ============= ADD GOAL AREA =============
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.expandedCard ? 44 : 0
                opacity: root.expandedCard ? 1 : 0
                clip: true
                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    // Idle: pill button.
                    Rectangle {
                        id: addPill
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 22
                        visible: !addToggle.checked
                        color: addHover.containsMouse
                            ? ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.9)
                            : "transparent"
                        border.width: 1
                        border.color: ColorUtils.transparentize(
                            Appearance.colors.colOnPrimaryContainer, 0.7)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                text: "add"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                            StyledText {
                                text: Translation.tr("Add Monthly Goal")
                                color: Appearance.colors.colOnPrimaryContainer
                                font.pixelSize: Appearance.font.pixelSize.normal
                            }
                        }

                        MouseArea {
                            id: addHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                addToggle.checked = true;
                                addField.text = "";
                                // Defer the focus call until after QML has
                                // processed the visibility change for addField.
                                Qt.callLater(() => { addField.forceActiveFocus(); });
                            }
                        }
                    }

                    // Active: text field.
                    // Using a plain TextField (not MaterialTextField) because
                    // MaterialTextField wraps its own MouseArea inside a parent
                    // AbstractWidget MouseArea, and the two fight over focus.
                    TextField {
                        id: addField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: addToggle.checked
                        focus: visible
                        color: Appearance.colors.colOnPrimaryContainer
                        placeholderText: Translation.tr("New goal… (Enter to add, Esc to cancel)")
                        placeholderTextColor: ColorUtils.transparentize(
                            Appearance.colors.colOnPrimaryContainer, 0.5)
                        selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                        selectionColor: Appearance.colors.colSecondaryContainer
                        background: Rectangle {
                            radius: 22
                            color: ColorUtils.transparentize(
                                Appearance.colors.colOnPrimaryContainer, 0.9)
                            border.width: 1
                            border.color: ColorUtils.transparentize(
                                Appearance.colors.colOnPrimaryContainer, 0.7)
                        }
                        font {
                            family: Appearance.font.family.main
                            pixelSize: Appearance.font.pixelSize.normal
                        }
                        // Submit on Enter; cancel on Escape.
                        onAccepted: {
                            MonthlyGoals.addGoal(text);
                            text = "";
                            addToggle.checked = false;
                        }
                        Keys.onEscapePressed: {
                            text = "";
                            addToggle.checked = false;
                        }
                        // Re-acquire focus after becoming visible (animations
                        // can transiently blur the field on expand).
                        onVisibleChanged: {
                            if (visible) {
                                Qt.callLater(() => { addField.forceActiveFocus(); });
                            }
                        }
                    }
                }
            }
        }

        // ============= CELEBRATION OVERLAY =============
        // A semi-transparent banner that briefly overlays the card when 100% is hit.
        Rectangle {
            id: celebrationOverlay
            anchors.fill: parent
            radius: parent.radius
            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
            visible: root.celebrationShown
            opacity: root.celebrationShown ? 1 : 0
            scale: root.celebrationShown ? 1 : 0.95
            z: 10
            Behavior on opacity { NumberAnimation { duration: 350 } }
            Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "emoji_events"
                    iconSize: 64
                    color: Appearance.colors.colOnPrimary
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("🏆 All Goals Completed!")
                    color: Appearance.colors.colOnPrimary
                    font {
                        pixelSize: Appearance.font.pixelSize.larger
                        weight: Font.Medium
                        family: Appearance.font.family.expressive
                    }
                }
            }
        }
    }
}