const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { root, load } = require("./lib.cjs");

const Options = load("Options.js");
const Helpers = load("GitHubHelpers.js");
const Proc = load("ProcHelpers.js");
const ThemeMath = load("ThemeMath.js");
const Catalog = load("I18nCatalog.js");
const Tabler = load("TablerGlyphs.js");

const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"));
const qmlFiles = ["Widget.qml", "Service.qml",
    ...fs.readdirSync(path.join(root, "ui")).filter(name => name.endsWith(".qml")).map(name => "ui/" + name)];
const read = file => fs.readFileSync(path.join(root, file), "utf8");

test("the manifest is an Omarchy schema 1 service plus bar widget", () => {
    assert.equal(manifest.schemaVersion, 1);
    assert.equal(manifest.id, "digitalpals.github-inbox");
    assert.match(manifest.version, /^\d+\.\d+\.\d+$/);
    assert.deepEqual(manifest.kinds, ["service", "bar-widget"]);
    assert.deepEqual(Object.keys(manifest.entryPoints).sort(), ["barWidget", "service"]);
    for (const entry of Object.values(manifest.entryPoints))
        assert.ok(fs.statSync(path.join(root, entry)).isFile(), entry);
    assert.equal(manifest.barWidget.allowMultiple, false);
    assert.equal(manifest.barWidget.defaultSection, "right");
});

test("the declared settings match the built-in's defaults and bounds", () => {
    assert.deepEqual(manifest.barWidget.defaults, Options.DEFAULTS);
    const rows = Object.fromEntries(manifest.barWidget.schema.map(row => [row.key, row]));
    for (const [key, row] of Object.entries(rows))
        assert.deepEqual(row.defaultValue, Options.DEFAULTS[key], key);
    assert.deepEqual(rows.badge.options.map(option => option.value), Options.BADGES);
    assert.deepEqual(Options.BADGES, Helpers.BADGE_MODES);
    assert.deepEqual([rows.repos.min, rows.repos.max], [Helpers.REPOS_MIN, Helpers.REPOS_MAX]);
    assert.deepEqual([rows.pollMins.min, rows.pollMins.max], [Helpers.POLL_MIN, Helpers.POLL_MAX]);
    // The watch list has no schema row; the popover edits it, and the raw
    // JSON editor in the settings dialog still shows it.
    assert.equal(rows.watch, undefined);
    assert.equal(Options.MAX_WATCHED_REPOS, Helpers.MAX_WATCH);
});

test("settings are sanitised to what the built-in accepted", () => {
    assert.deepEqual(Options.normalize(undefined), Options.DEFAULTS);
    assert.deepEqual(Options.normalize({ badge: "loud", repos: 99, pollMins: 0.2,
        ciActivity: "yes", toasts: false, watch: "cli/cli" }),
    { badge: "dot", repos: 15, pollMins: 1, ciActivity: true, toasts: false, watch: [] });
    const many = Array.from({ length: 30 }, (_, i) => "owner/repo" + i);
    assert.equal(Options.normalize({ watch: many }).watch.length, 20);
    assert.deepEqual(Options.normalize({ watch: ["cli/cli", "CLI/CLI", " a/b ", "bad", "x/..",
        "https://github.com/c/d", 7] }).watch, ["cli/cli", "a/b"]);
});

test("the built-in's shell.json options are imported once, only when unset here", () => {
    const shell = JSON.stringify({ modOpts: { gh: { badge: "count", repos: 8, pollMins: 10,
        watch: ["cli/cli"], toasts: true } } });
    assert.deepEqual(Options.importFromShell(shell, Options.DEFAULTS),
        { badge: "count", pollMins: 10, watch: ["cli/cli"] });
    assert.deepEqual(Options.importFromShell(shell, Object.assign({}, Options.DEFAULTS, { repos: 4 })), {},
        "an explicit plugin choice wins");
    assert.deepEqual(Options.importFromShell("{", Options.DEFAULTS), {});
    assert.deepEqual(Options.importFromShell("", Options.DEFAULTS), {});
    assert.deepEqual(Options.importFromShell('{"modOpts":{}}', Options.DEFAULTS), {});
    assert.deepEqual(Options.importFromShell('{"modOpts":{"gh":{"badge":"dot"}}}', Options.DEFAULTS), {});
});

test("a missing or signed-out gh gets one plain sentence", () => {
    assert.equal(Proc.commandError("gh api /user", Proc.NOT_STARTED, ""), Proc.GH_MISSING);
    assert.equal(Proc.commandError("gh api /user", 4,
        "To get started with GitHub CLI, please run:  gh auth login\n"), Proc.GH_SIGNED_OUT);
    assert.equal(Proc.commandError("gh api /user", 1, "gh: Bad credentials (HTTP 401)"), Proc.GH_SIGNED_OUT);
    assert.equal(Proc.commandError("gh api /user", 1, "gh: Not Found (HTTP 404)\n"), "gh: Not Found (HTTP 404)");
    assert.equal(Proc.commandError("gh api /user", 3, ""), "gh api /user exited with status 3");
    assert.equal(Proc.lastLine("x".repeat(400)).length, 160);
});

test("theme roles hold their contrast floors", () => {
    assert.equal(ThemeMath.hex6("#80112233"), "#112233");
    assert.equal(ThemeMath.hex6("#abc"), "#aabbcc");
    for (const surface of ["#1c1b22", "#f6f5f0", "#7f7f7f"]) {
        for (const seed of ["#ffc26e", "#b5761e", "#3b82f6", "#ff6b6b"]) {
            const lifted = ThemeMath.ensureContrast(seed, surface, 4.5);
            assert.ok(ThemeMath.contrastRatio(lifted, surface) >= 4.5, seed + " on " + surface);
        }
        const faint = ThemeMath.textTone(surface, ThemeMath.foregroundFor(surface), 0.66, 4.5);
        assert.ok(ThemeMath.contrastRatio(faint, surface) >= 4.5);
    }
});

test("every translated string has a Dutch entry", () => {
    const strings = new Set();
    for (const file of qmlFiles) {
        for (const match of read(file).matchAll(/I18n\.tr\(("(?:[^"\\]|\\.)*")\)/g))
            strings.add(JSON.parse(match[1]));
    }
    assert.ok(strings.size > 20);
    for (const text of strings)
        assert.ok(Catalog.NL[text], "no Dutch for " + JSON.stringify(text));
    assert.equal(Catalog.languageFor(["", "nl_NL.UTF-8"]), "nl");
    assert.equal(Catalog.languageFor(["C.UTF-8", "de_DE"]), "en");
    assert.equal(Catalog.translate(Catalog.catalogFor("en"), "Inbox"), "Inbox");
});

test("every icon the views name exists in the bundled glyph table", () => {
    const names = new Set();
    for (const file of qmlFiles) {
        const source = read(file);
        for (const match of source.matchAll(/(?:symbol|glyph|name):\s*([^\n]+)/g)) {
            for (const literal of match[1].matchAll(/"([a-z][a-z0-9_-]*)"/g))
                names.add(literal[1]);
        }
        const icons = source.match(/function inboxStatusIcon[\s\S]*?\n    \}/)?.[0] ?? "";
        for (const literal of icons.matchAll(/(?:return|\?|:) "([a-z_]+)"/g))
            names.add(literal[1]);
    }
    names.delete("digitalpals");
    for (const name of names)
        assert.ok(Tabler.has(name), "missing glyph " + name);
    assert.ok(names.has("sync") && names.has("archive") && names.has("settings"));
    assert.ok(fs.statSync(path.join(root, "assets/tabler/outline.ttf")).size > 1000);
});

test("ui/qmldir lists every view type and nothing else", () => {
    const listed = read("ui/qmldir").split("\n").filter(line => line && !line.startsWith("#"))
        .map(line => line.trim().split(/\s+/).pop()).sort();
    const files = fs.readdirSync(path.join(root, "ui")).filter(name => name.endsWith(".qml")).sort();
    assert.deepEqual(listed, files);
});

test("the plugin imports only public host modules and its own files", () => {
    const allowed = /^import (QtQuick(\.\w+)*|Quickshell(\.\w+)*|qs\.Ui as Ui|qs\.Commons as Commons|"ui"|"(\.\.\/)?js\/\w+\.js" as \w+)$/;
    for (const file of qmlFiles) {
        for (const line of read(file).split("\n").filter(line => line.startsWith("import ")))
            assert.match(line, allowed, file + ": " + line);
        // Qt 6.12 has a QtQuick Color type; the palette is always qualified.
        assert.doesNotMatch(read(file), /^import qs\.Commons\s*$/m, file);
    }
});

test("the service keeps the built-in's state file and never writes GitHub", () => {
    const service = read("Service.qml");
    assert.match(service, /path: Quickshell\.env\("HOME"\) \+ "\/\.local\/state\/cybexos\/shell\/github\.json"/);
    assert.match(service, /Quickshell\.env\("HOME"\) \+ "\/\.config\/cybexos\/shell\.json"/);
    assert.doesNotMatch(service, /"--method"|"-X"|"PATCH"|"PUT"|"POST"|"DELETE"/);
    assert.match(service, /let command = \["gh", "api", path\]/);
});

test("the IPC target exists once, in the service, not in each output's widget", () => {
    const widget = fs.readFileSync(path.join(root, "Widget.qml"), "utf8");
    const service = fs.readFileSync(path.join(root, "Service.qml"), "utf8");
    assert.doesNotMatch(widget, /IpcHandler\s*\{/);
    assert.match(widget, /manageIpc: false/);
    assert.match(widget, /gh\.registerWidget\(root\)/);
    assert.match(widget, /gh\.unregisterWidget\(root\)/);
    assert.equal((service.match(/IpcHandler\s*\{/g) || []).length, 1);
    assert.match(service, /target: "digitalpals\.github-inbox"/);
});
