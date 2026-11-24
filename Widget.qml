pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.Commons as Commons
import qs.Ui as Ui
import "ui"
import "js/GitHubHelpers.js" as Helpers

// GitHub Inbox and repository feed in the menubar: the GitHub mark, a quiet
// lane that shows while workflows run, the pending-Inbox badge, and the
// popover with Inbox, Repositories, Commits and the watch list.
//
// Every output draws its own widget; all of them read the one shared
// service (Service.qml), so polling and state exist once.
Ui.Panel {
    id: root
    moduleName: "digitalpals.github-inbox"
    ipcTarget: "digitalpals.github-inbox"
    manageIpc: false

    readonly property var gh: bar && bar.shell && typeof bar.shell.serviceFor === "function"
        ? bar.shell.serviceFor(moduleName) : null
    readonly property bool ready: gh !== null
    // The popover's view once loaded; also what the real-engine check drives.
    readonly property Item inboxView: viewLoader.item

    readonly property color ink: bar ? bar.foreground : Commons.Color.foreground
    readonly property string fontFamily: bar ? bar.fontFamily : Commons.Style.font.family
    readonly property bool horizontal: !(bar && bar.vertical)

    readonly property int pending: ready ? gh.pendingInboxCount : 0
    readonly property int running: ready ? gh.runningCount : 0
    readonly property string badgeMode: ready ? gh.badgeMode : "dot"
    readonly property color badgeTone: !ready ? Theme.accentText
        : gh.badgeTone === "red" ? Theme.redText
        : gh.badgeTone === "amber" ? Theme.amber : Theme.accentText
    readonly property bool countShown: pending > 0 && badgeMode === "count" && horizontal
    readonly property bool dotShown: pending > 0 && badgeMode === "dot"

    function tooltip() {
        if (!ready)
            return "GitHub";
        let summary = Helpers.githubTooltip(gh.runningCount, gh.pendingInboxCount,
            gh.unreadRepoCount);
        if (gh.error !== "")
            summary += " · " + gh.error;
        else if (gh.inboxError !== "")
            summary += " · Inbox paused";
        return summary;
    }

    function saveWatch(list) {
        if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function")
            bar.shell.updateEntryInline(moduleName, { watch: list });
    }

    implicitWidth: chip.implicitWidth
    implicitHeight: chip.implicitHeight

    // The host bar's motion preference reaches the plugin's shared tokens.
    Binding {
        target: Theme
        property: "reducedMotion"
        value: !!root.bar && !root.bar.foregroundAnimationEnabled
    }

    // The IPC target lives once, in the service (one widget per output):
    // it reaches the widgets through this registration.
    onGhChanged: if (gh && typeof gh.registerWidget === "function") gh.registerWidget(root)
    Component.onCompleted: if (gh && typeof gh.registerWidget === "function") gh.registerWidget(root)
    Component.onDestruction: if (gh && typeof gh.unregisterWidget === "function") gh.unregisterWidget(root)

    Ui.WidgetButton {
        id: chip

        anchors.centerIn: parent
        bar: root.bar
        text: ""
        labelVisible: false
        hasVisualContent: true
        horizontalMargin: 0
        fixedWidth: content.implicitWidth + 18
        fixedHeight: Math.min(root.height > 0 ? root.height : Theme.chipHeight, Theme.chipHeight)
        tooltipText: root.tooltip()
        onPressed: function(button) {
            if (button === Qt.MiddleButton) {
                if (root.ready)
                    root.gh.refreshAll();
                return;
            }
            root.toggle();
        }

        // The chip the built-in widget sat on: the bar's own chip colour,
        // a step stronger while hovered or open.
        Rectangle {
            anchors.fill: parent
            z: -1
            radius: Theme.chipRadius
            color: root.bar ? root.bar.background : "transparent"

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: root.ink
                opacity: chip.tooltipHovered || root.opened ? 0.08 : 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.chipFadeDuration }
                }
            }
        }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 6

            // Keep the mark pristine; live work gets its own narrow lane and
            // pending activity the badge beside it.
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.barIconSize
                height: Theme.barIconSize

                BrandIcon {
                    anchors.fill: parent
                    colorized: true
                    tint: root.ink
                }

                // Badge "dot": the pending Inbox's tone on the mark's corner.
                Rectangle {
                    visible: root.dotShown
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: -2
                    anchors.topMargin: -2
                    width: 7
                    height: 7
                    radius: 3.5
                    color: root.badgeTone
                    border.width: 1
                    border.color: root.bar ? root.bar.background : "transparent"
                }
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: root.running > 0 ? 5 : 0
                height: 5
                opacity: root.running > 0 ? 1 : 0

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.expandDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.springCurve
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: Theme.chipFadeDuration }
                }

                // Static by design: a permanent workflow marker should not pulse.
                Rectangle {
                    anchors.centerIn: parent
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Theme.accentText
                }
            }

            // Badge "count": how many Inbox entities wait, capped at 99+.
            Text {
                visible: root.countShown
                anchors.verticalCenter: parent.verticalCenter
                text: (root.pending > 99 ? "99+" : String(root.pending)) + " pending"
                font.family: root.fontFamily
                font.pixelSize: Theme.typography.bar
                font.weight: Theme.weightMedium
                font.features: Theme.tabularNumberFeatures
                color: root.badgeTone
            }
        }
    }

    Ui.KeyboardPanel {
        id: panel

        readonly property real sideInset: padding * 2
            + Commons.Border.left(borderSpec) + Commons.Border.right(borderSpec)

        anchorItem: chip
        owner: root
        bar: root.bar
        open: root.opened
        padding: T3Theme.pagePadding
        focusTarget: viewLoader.item
        contentWidth: fittedContentWidth((viewLoader.item ? viewLoader.item.implicitWidth : 300) + sideInset)
        contentHeight: fittedContentHeight(viewLoader.item ? viewLoader.item.implicitHeight : 120)

        Loader {
            id: viewLoader
            anchors.fill: parent
            active: root.ready
            sourceComponent: InboxView {
                gh: root.gh
                shown: root.opened
                padding: panel.padding
                availableWidth: panel.availableCardWidth > 0
                    ? panel.availableCardWidth : 484
                availableHeight: (panel.availableCardHeight > 0
                    ? panel.availableCardHeight : 800) - panel.verticalContentInset
                onCloseRequested: root.close()
                onWatchEdited: watch => root.saveWatch(watch)
            }
        }

        // Before the service has loaded (or when the plugin is reloading)
        // the popover says so instead of opening empty.
        Text {
            visible: !root.ready
            anchors.centerIn: parent
            text: "GitHub is starting…"
            font.family: T3Theme.fontUi
            font.pixelSize: Theme.typography.secondary
            color: Theme.textFaint
        }
    }
}
