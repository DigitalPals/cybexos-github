pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "Common"
import "Bar"

// Real-engine check for the GitHub plugin, run inside a copy of Cybex OS's
// Quickshell tree by tests/engine/run.py. A bar per output hosts the plugin
// area the native bar uses; the plugin is installed and enabled through
// Cybex OS's own helper. Prints GITHUB_PLUGIN pass|fail.
ShellRoot {
    id: root

    readonly property string pluginId: "digitalpals.github-inbox"
    readonly property string mode: Quickshell.env("GITHUB_CHECK_MODE")
    readonly property string shots: Quickshell.env("GITHUB_CHECK_SHOTS")
    property int ticks: 0
    property string stage: "load"
    property bool finished: false
    property var widget: null
    property var service: null
    property var queuedShots: []
    property string nextStage: ""

    function done(ok, detail) {
        if (finished)
            return;
        finished = true;
        console.warn("GITHUB_PLUGIN " + (ok ? "pass " : "fail ") + detail);
        Quickshell.execDetached(["bash", "-c", 'sleep 0.3; kill -TERM -- "$1"', "bash", String(Quickshell.processId)]);
    }

    function check(value, detail) {
        if (!value)
            done(false, detail);
        return value;
    }

    // Take a screenshot (when asked for) and then continue at `then`.
    property string lastShot: ""
    function shoot(name, then) {
        nextStage = then;
        lastShot = name;
        if (shots === "") {
            stage = then;
            return;
        }
        stage = "shooting";
        shotDelay.restart();
    }

    Timer {
        id: shotDelay
        interval: 500
        onTriggered: root.capture()
    }

    function capture() {
        const name = root.lastShot;
        grim.command = ["grim", "-o", "HEADLESS-1", root.shots + "/" + root.mode + "-" + name + ".png"];
        grim.running = true;
    }

    Process {
        id: grim
        onExited: root.stage = root.nextStage
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 40
            color: "#16151c"
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                UserWidgets { section: "right"; screenName: bar.modelData.name; availableWidth: 640 }
            }
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: !root.finished
        onTriggered: {
            if (++root.ticks > 250) {
                root.done(false, "timeout at " + root.stage + " errors=" + JSON.stringify(OmarchyPlugins.errors)
                    + " registry=" + UserPlugins.error
                    + (root.service ? " svc.error=" + root.service.error + " inbox=" + root.service.inboxError
                        + " repos=" + root.service.repos.length + " items=" + root.service.inboxItems.length : ""));
                return;
            }
            const errors = Object.keys(OmarchyPlugins.errors).filter(key => key.startsWith(root.pluginId)
                && OmarchyPlugins.errors[key] !== "");
            if (!root.check(errors.length === 0, "plugin errors " + JSON.stringify(OmarchyPlugins.errors)))
                return;
            const svc = OmarchyPlugins.serviceFor(root.pluginId);
            const hosts = UserPlugins.widgetHosts.filter(host => host.descriptor.id === root.pluginId);
            switch (root.stage) {
            case "load":
                if (!svc || hosts.length !== Quickshell.screens.length || hosts.some(host => !host.widget))
                    return;
                if (!root.check(hosts.every(host => host.error === ""), "host error " + hosts.map(h => h.error)))
                    return;
                root.service = svc;
                // The screenshots show HEADLESS-1; drive the widget there.
                root.widget = (hosts.find(host => host.screenName === "HEADLESS-1") || hosts[0]).widget;
                if (!root.check(root.widget.gh === svc, "widget does not see the shared service"))
                    return;
                if (!root.check(root.widget.width > 0 && root.widget.height > 0, "widget has no size"))
                    return;
                root.stage = "feed";
                return;
            case "feed":
                if (root.mode === "missing") {
                    if (svc.error === "")
                        return;
                    if (!root.check(svc.error === "GitHub CLI (gh) is not installed or not on PATH",
                            "missing gh message: " + svc.error))
                        return;
                } else if (root.mode === "signed-out") {
                    if (svc.error === "")
                        return;
                    if (!root.check(svc.error === "GitHub CLI is not signed in; run gh auth login",
                            "signed-out message: " + svc.error))
                        return;
                } else {
                    if (!(svc.ready && svc.inboxReady && svc.inboxItems.length > 0 && svc.runningCount > 0))
                        return;
                    if (!root.check(svc.login === "octocat" && svc.repos.length === 2, "feed " + svc.login))
                        return;
                    // shell.json's modOpts.gh was imported into plugins.json once.
                    if (svc.opts.badge !== "count")
                        return;
                }
                root.shoot("bar", "open");
                return;
            case "open":
                root.widget.open();
                root.stage = "opened";
                return;
            case "opened":
                if (!root.widget.opened || !root.widget.inboxView || root.widget.inboxView.implicitHeight <= 0)
                    return;
                if (!root.check(root.widget.inboxView.page === "inbox", "popover opens on Inbox"))
                    return;
                root.shoot("inbox", root.mode === "data" ? "repos" : "settings");
                return;
            case "repos":
                root.widget.inboxView.showRepos();
                root.shoot("repos", "commits");
                return;
            case "commits":
                root.widget.inboxView.showCommits("octocat/hello-world");
                root.stage = "commitsLoaded";
                return;
            case "commitsLoaded": {
                const entry = svc.commitCache["octocat/hello-world"];
                if (!entry || entry.loading)
                    return;
                if (!root.check(entry.rows.length === 2, "commits " + JSON.stringify(entry)))
                    return;
                root.widget.inboxView.toggleCommit(entry.rows[0].sha);
                root.stage = "statsLoaded";
                return;
            }
            case "statsLoaded":
                if (!svc.statsCache["a1b2c3d4e5f6"])
                    return;
                root.shoot("commits", "settings");
                return;
            case "settings":
                root.widget.inboxView.showSettings();
                root.shoot("settings", root.mode === "data" ? "watch" : "close");
                return;
            case "watch":
                // What the gear page's Add does: the list goes to plugins.json
                // through the host and comes back as the service's settings.
                root.widget.saveWatch(svc.watch.concat(["octocat/missing"]));
                root.stage = "watched";
                return;
            case "watched":
                if (svc.watch.indexOf("octocat/missing") < 0 || svc.watchError("octocat/missing") === "")
                    return;
                root.shoot("watch", "close");
                return;
            case "close":
                root.widget.close();
                root.stage = "closed";
                return;
            case "closed":
                if (root.widget.opened)
                    return;
                if (root.mode === "data" && !root.check(svc.seenAt !== "" && svc.activitySeenAt !== "",
                        "closing marks the feed seen"))
                    return;
                root.done(true, root.mode);
                return;
            }
        }
    }
}
