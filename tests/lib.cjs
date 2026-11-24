// Locates the plugin's sources for the tests in this directory. Nothing here
// needs Cybex OS: the helpers are plain JS and the QML is read as text.
const path = require("node:path");

const root = path.resolve(__dirname, "..");

// require() a pure-JS helper out of js/ by name.
function load(name) {
    return require(path.join(root, "js", name));
}

// QML source as its English text reads: I18n.tr("Text") becomes "Text".
function untranslated(source) {
    return String(source).replace(/I18n\.tr\(("(?:[^"\\]|\\.)*")\)/g, "$1");
}

module.exports = { root, load, untranslated };
