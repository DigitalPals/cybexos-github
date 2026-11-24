// The widget's settings as the service reads them: every value sanitised to
// what the old built-in accepted (Cybex OS SettingsHelpers `modOpts.gh`), so a
// hand-edited plugins.json or a raw-JSON edit in the settings dialog cannot
// turn one poll into hundreds of API calls. Pure; testable under Node.

var DEFAULTS = {
    badge: "dot",
    repos: 8,
    pollMins: 5,
    ciActivity: true,
    toasts: true,
    watch: []
};

var BADGES = ["dot", "count", "off"];
var MAX_WATCHED_REPOS = 20;
var REPO_SLUG = /^[A-Za-z0-9][A-Za-z0-9-]*\/[A-Za-z0-9._-]+$/;

function isList(value) {
    return Array.isArray(value) || value instanceof Array;
}

function enumIn(value, allowed, fallback) {
    return allowed.indexOf(value) >= 0 ? value : fallback;
}

function intIn(value, low, high, step, fallback) {
    if (typeof value !== "number" || !isFinite(value))
        return fallback;
    var rounded = Math.round(value / step) * step;
    return Math.min(high, Math.max(low, rounded));
}

function boolIn(value, fallback) {
    return typeof value === "boolean" ? value : fallback;
}

// Canonical "owner/repo" only, deduped case-insensitively and capped. A pasted
// URL is canonicalised where it is typed (GitHubHelpers.repoSlug); anything
// else reaching this store came from a hand edit.
function repoListIn(value, fallback) {
    if (!isList(value))
        return fallback;
    var out = [];
    var seen = {};
    for (var i = 0; i < value.length && out.length < MAX_WATCHED_REPOS; i++) {
        if (typeof value[i] !== "string")
            continue;
        var slug = value[i].trim();
        var name = slug.split("/")[1];
        if (slug.length > 120 || !REPO_SLUG.test(slug) || name === "." || name === "..")
            continue;
        var key = slug.toLowerCase();
        if (seen[key])
            continue;
        seen[key] = true;
        out.push(slug);
    }
    return out;
}

function normalize(raw) {
    var value = raw && typeof raw === "object" && !isList(raw) ? raw : {};
    return {
        badge: enumIn(value.badge, BADGES, DEFAULTS.badge),
        repos: intIn(value.repos, 3, 15, 1, DEFAULTS.repos),
        pollMins: intIn(value.pollMins, 1, 30, 1, DEFAULTS.pollMins),
        ciActivity: boolIn(value.ciActivity, DEFAULTS.ciActivity),
        toasts: boolIn(value.toasts, DEFAULTS.toasts),
        watch: repoListIn(value.watch, DEFAULTS.watch.slice())
    };
}

function sameValue(a, b) {
    return JSON.stringify(a) === JSON.stringify(b);
}

// The old built-in kept these options in ~/.config/cybexos/shell.json under
// modOpts.gh. Returns the settings worth carrying over, once: only options the
// user had changed there, and only when the plugin's own settings are still
// all at their defaults (so an explicit plugin choice always wins). An empty
// object means there is nothing to import.
function importFromShell(shellText, current) {
    var parsed;
    try {
        parsed = JSON.parse(String(shellText || ""));
    } catch (error) {
        return {};
    }
    var old = parsed && parsed.modOpts && parsed.modOpts.gh;
    if (!old || typeof old !== "object" || isList(old))
        return {};
    var mine = normalize(current);
    for (var key in DEFAULTS) {
        if (!sameValue(mine[key], DEFAULTS[key]))
            return {};
    }
    var theirs = normalize(old);
    var out = {};
    for (var name in DEFAULTS) {
        if (!sameValue(theirs[name], DEFAULTS[name]))
            out[name] = theirs[name];
    }
    return out;
}

var exported = {
    DEFAULTS: DEFAULTS,
    BADGES: BADGES,
    MAX_WATCHED_REPOS: MAX_WATCHED_REPOS,
    repoListIn: repoListIn,
    normalize: normalize,
    importFromShell: importFromShell
};

if (typeof module !== "undefined" && module.exports)
    module.exports = exported;
