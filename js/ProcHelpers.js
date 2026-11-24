// Pure helpers for turning a finished `gh` process into widget state. Trimmed
// from Cybex OS's shell helpers; keep this file free of Qt APIs so the same
// logic stays testable under Node.
//
// The QML side of the contract (Quickshell 0.2): for one run,
// StdioCollector.streamFinished fires for stdout and stderr before
// Process.exited, and Process.runningChanged(false) fires last. When the
// binary cannot be launched at all, only that falling edge arrives: there is
// no exited() and no stream, so callers pass NOT_STARTED as the exit code.

// No exited() was seen: the command never ran (missing binary, permissions).
var NOT_STARTED = -1;

// Last non-empty line of a command's stderr, clipped so one runaway message
// cannot take over the popover.
function lastLine(text, limit) {
    if (typeof text !== "string")
        return "";
    var lines = text.split("\n");
    for (var i = lines.length - 1; i >= 0; i--) {
        var line = lines[i].trim();
        if (line === "")
            continue;
        var max = limit === undefined ? 160 : limit;
        return line.length > max ? line.slice(0, max - 1) + "…" : line;
    }
    return "";
}

var GH_MISSING = "GitHub CLI (gh) is not installed or not on PATH";
var GH_SIGNED_OUT = "GitHub CLI is not signed in; run gh auth login";

// The two failures a fresh install meets first get one plain sentence each,
// whatever command hit them: no `gh` at all, and a `gh` with no account.
function ghSetupProblem(exitCode, stderrText) {
    if (exitCode === NOT_STARTED)
        return GH_MISSING;
    var text = typeof stderrText === "string" ? stderrText : "";
    if (/gh auth login|not logged in|no oauth token|authentication required|HTTP 401|Bad credentials/i.test(text))
        return GH_SIGNED_OUT;
    return "";
}

// One sentence for why `label` failed. A missing or signed-out gh wins; then
// what the command said on stderr; then the raw status.
function commandError(label, exitCode, stderrText) {
    var setup = ghSetupProblem(exitCode, stderrText);
    if (setup !== "")
        return setup;
    var said = lastLine(stderrText);
    if (said !== "")
        return said;
    return label + " exited with status " + exitCode;
}

var exported = {
    NOT_STARTED: NOT_STARTED,
    GH_MISSING: GH_MISSING,
    GH_SIGNED_OUT: GH_SIGNED_OUT,
    lastLine: lastLine,
    ghSetupProblem: ghSetupProblem,
    commandError: commandError
};

if (typeof module !== "undefined" && module.exports)
    module.exports = exported;
