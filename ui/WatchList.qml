pragma ComponentBehavior: Bound
import QtQuick
import "../js/GitHubHelpers.js" as GitHubHelpers

// The two parts of the widget's settings that are not value rows: who the
// plugin is reading GitHub as, and which repositories outside that account
// join the feed. The value options (badge, recent repositories, refresh, CI
// reports, toasts) are drawn by Cybex OS's settings dialog from the manifest.
//
// A watch entry is canonicalised here, at the point of entry, so a pasted
// browser URL or an SSH remote becomes "owner/repo" before it is stored.
// Ported from Cybex OS's built-in Settings/GitHubWatchList.qml.
Column {
    id: root

    required property var gh
    readonly property var watch: gh.watch
    readonly property int accountRepoCount: gh.repos.filter(row => row.account !== false).length
    readonly property var workflowFailedRepos: Object.keys(gh.workflowRepoErrors)
    readonly property var eventFailedRepos: Object.keys(gh.eventRepoErrors)

    property string addError: ""
    // The new list, for the widget to save into the plugin's settings.
    signal watchEdited(var watch)

    spacing: Theme.settingsContentSpacing
    topPadding: 4
    bottomPadding: 8

    function addWatch(text) {
        const slug = GitHubHelpers.repoSlug(text);
        if (slug === "") {
            addError = I18n.tr("Not a repository — use owner/repo, or paste its GitHub URL");
            return false;
        }
        if (root.watch.some(entry => entry.toLowerCase() === slug.toLowerCase())) {
            addError = slug + " " + I18n.tr("is already watched");
            return false;
        }
        if (root.watch.length >= GitHubHelpers.MAX_WATCH) {
            addError = "At most " + GitHubHelpers.MAX_WATCH + " watched repositories";
            return false;
        }
        addError = "";
        root.watchEdited(root.watch.concat([slug]));
        return true;
    }

    function removeWatch(slug) {
        addError = "";
        root.watchEdited(root.watch.filter(entry => entry !== slug));
    }

    component Hint: Text {
        property string tone: ""
        visible: text !== ""
        width: parent ? parent.width : 0
        leftPadding: Theme.settingsMarkInset
        wrapMode: Text.Wrap
        maximumLineCount: 6
        elide: Text.ElideRight
        font.family: T3Theme.fontUi
        font.pixelSize: Theme.typography.secondary
        color: tone === "error" ? Theme.redText : tone === "warning" ? Theme.amber : Theme.textDim
    }

    // ---- account ----------------------------------------------------------
    SectionLabel {
        text: I18n.tr("ACCOUNT")
    }

    Item {
        width: parent.width
        height: Math.max(Theme.settingsControlHeight, accountLines.implicitHeight)

        BrandIcon {
            id: markGlyph
            x: Theme.settingsMarkInset
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.iconMedium
            height: Theme.iconMedium
            colorized: true
            tint: Theme.icon
        }

        Row {
            id: connectionState
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.iconTextSpacing

            readonly property bool failed: root.gh.error !== ""

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: connectionState.failed ? Theme.redText
                    : root.gh.ready ? Theme.connected : Theme.amber
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: connectionState.failed ? I18n.tr("Unavailable")
                    : root.gh.ready ? I18n.tr("Connected") : I18n.tr("Checking…")
                font.family: T3Theme.fontUi
                font.pixelSize: Theme.typography.secondary
                color: Theme.textDim
            }
        }

        Column {
            id: accountLines
            anchors.left: markGlyph.right
            anchors.leftMargin: Theme.controlSpacing
            anchors.right: connectionState.left
            anchors.rightMargin: Theme.controlSpacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: root.gh.login !== "" ? "@" + root.gh.login : I18n.tr("Not signed in")
                font.family: T3Theme.fontUi
                font.pixelSize: Theme.typography.primary
                font.weight: Theme.weightMedium
                color: Theme.textHi
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (root.gh.error !== "")
                        return root.gh.error;
                    if (!root.gh.ready)
                        return I18n.tr("Reading the gh CLI's login…");
                    const orgs = root.gh.orgCount;
                    return "Authenticated via gh CLI · " + root.accountRepoCount
                        + " account repos"
                        + (orgs > 0 ? " across " + orgs + (orgs === 1 ? " org" : " orgs") : "");
                }
                font.family: T3Theme.fontUi
                font.pixelSize: Theme.typography.secondary
                color: root.gh.error !== "" ? Theme.redText : Theme.textLow
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }
    }

    Hint {
        tone: root.gh.inboxError !== "" ? "error" : "warning"
        text: {
            const parts = [];
            if (root.gh.inboxError !== "")
                parts.push("Inbox paused: " + root.gh.inboxError);
            if (root.gh.notificationError !== "")
                parts.push("Notifications unavailable: " + root.gh.notificationError);
            if (root.workflowFailedRepos.length > 0)
                parts.push("Workflows unavailable for " + root.workflowFailedRepos.join(", "));
            if (root.eventFailedRepos.length > 0)
                parts.push("Repository events unavailable for "
                    + root.eventFailedRepos.join(", "));
            return parts.join("\n");
        }
    }

    // ---- watched repositories ---------------------------------------------
    SectionLabel {
        text: I18n.tr("WATCHED REPOS")
        detail: root.watch.length > 0 ? String(root.watch.length) : ""
    }

    Item {
        width: parent.width
        height: Theme.settingsControlHeight

        Rectangle {
            id: addField
            x: Theme.settingsMarkInset
            width: Math.max(0, addAction.x - Theme.controlSpacing - x)
            height: parent.height
            radius: T3Theme.controlRadius
            color: T3Theme.surface
            border.width: addInput.activeFocus || root.addError !== "" ? 1 : 0
            border.color: root.addError !== "" ? Theme.redText : T3Theme.focus

            TextInput {
                id: addInput
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                selectByMouse: true
                font.family: T3Theme.fontUi
                font.pixelSize: Theme.typography.control
                color: T3Theme.textPrimary
                Accessible.name: I18n.tr("Repository to watch")
                onTextChanged: root.addError = ""
                onAccepted: {
                    if (root.addWatch(text))
                        text = "";
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape && text !== "") {
                        text = "";
                        event.accepted = true;
                    }
                }

                Text {
                    visible: addInput.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "owner/repo"
                    font: addInput.font
                    color: T3Theme.textFaint
                }
            }
        }

        ActionButton {
            id: addAction
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.settingsControlHeight
            label: I18n.tr("Add")
            hPadding: 24
            fontFamily: T3Theme.fontUi
            focusColor: T3Theme.focus
            buttonRadius: T3Theme.controlRadius
            tint: T3Theme.accent
            fill: T3Theme.accentSubtle
            onTriggered: {
                if (root.addWatch(addInput.text))
                    addInput.text = "";
                addInput.forceActiveFocus();
            }
        }
    }

    Hint {
        tone: "error"
        text: root.addError
    }

    // One hairline-separated row per watched repository.
    Column {
        width: parent.width
        spacing: Theme.settingsRowSpacing

        Repeater {
            model: root.watch

            delegate: Item {
                id: watchRow

                required property string modelData
                required property int index
                readonly property string errorText: root.gh.watchError(modelData)

                width: parent.width
                height: Theme.settingsControlHeight + (errorText !== "" ? errorLine.height : 0)

                Rectangle {
                    visible: watchRow.index > 0
                    x: Theme.settingsMarkInset
                    y: -Math.ceil(Theme.settingsRowSpacing / 2) - 1
                    width: Math.max(0, parent.width - x)
                    height: 1
                    color: Theme.hairlineSoft
                }

                Text {
                    x: Theme.settingsMarkInset
                    width: Math.max(0, removeAction.x - Theme.controlSpacing - x)
                    height: Theme.settingsControlHeight
                    verticalAlignment: Text.AlignVCenter
                    // The owner is dim and the name is not, the same split the
                    // popover's repository rows draw.
                    text: "<font color=\"" + Theme.textDim + "\">"
                        + watchRow.modelData.split("/")[0] + "/</font>"
                        + watchRow.modelData.split("/")[1]
                    textFormat: Text.StyledText
                    font.family: T3Theme.fontUi
                    font.pixelSize: Theme.typography.control
                    color: Theme.textMid
                    elide: Text.ElideRight
                }

                IconButton {
                    id: removeAction
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    y: (Theme.settingsControlHeight - height) / 2
                    controlSize: Theme.chipInnerHeight
                    symbol: "close"
                    accessibleName: "Stop watching " + watchRow.modelData
                    tint: T3Theme.textMuted
                    onTriggered: root.removeWatch(watchRow.modelData)
                }

                Hint {
                    id: errorLine
                    y: Theme.settingsControlHeight
                    width: removeAction.x
                    tone: "warning"
                    maximumLineCount: 2
                    text: watchRow.errorText
                }
            }
        }
    }

    Hint {
        maximumLineCount: 10
        text: I18n.tr("Recent account and org repositories follow the count in the widget's settings. Every watched repository is added to that list and, when enabled, to the workflow-report scope. Repositories refresh on the interval in the widget's settings; the Inbox checks repository events and GitHub notifications every minute. Other options: Settings → Bar & Control Center → GitHub.")
    }
}
