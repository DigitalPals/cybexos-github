// Colour arithmetic for the plugin's theme roles, trimmed from Cybex OS's
// SettingsHelpers: contrast ratios, mixing and the "lift a semantic colour
// until it reads" rule the built-in widget's palette used. Pure; accepts
// QML colour strings (#rgb, #rrggbb, #aarrggbb).

function hex6(value, fallback) {
    var text = String(value === undefined || value === null ? "" : value).trim().toLowerCase();
    var short = /^#([0-9a-f])([0-9a-f])([0-9a-f])$/.exec(text);
    if (short)
        return "#" + short[1] + short[1] + short[2] + short[2] + short[3] + short[3];
    if (/^#[0-9a-f]{8}$/.test(text))
        return "#" + text.slice(3);
    if (/^#[0-9a-f]{6}$/.test(text))
        return text;
    return fallback === undefined ? "#000000" : fallback;
}

function rgb(value) {
    var valid = hex6(value);
    return [1, 3, 5].map(function(offset) {
        return parseInt(valid.slice(offset, offset + 2), 16) / 255;
    });
}

function channelHex(channel) {
    var n = Math.round(Math.min(1, Math.max(0, channel)) * 255);
    return (n < 16 ? "0" : "") + n.toString(16);
}

function luminance(value) {
    var linear = rgb(value).map(function(channel) {
        return channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2];
}

function contrastRatio(a, b) {
    var first = luminance(a);
    var second = luminance(b);
    return (Math.max(first, second) + 0.05) / (Math.min(first, second) + 0.05);
}

function mixHex(from, to, amount) {
    var start = rgb(from);
    var end = rgb(to);
    var t = Math.min(1, Math.max(0, amount));
    return "#" + start.map(function(channel, index) {
        return channelHex(channel + (end[index] - channel) * t);
    }).join("");
}

function foregroundFor(background) {
    return contrastRatio("#ffffff", background) >= contrastRatio("#000000", background)
        ? "#ffffff" : "#000000";
}

// Preserve a semantic colour when it already reads; otherwise pull it toward
// the background's foreground until it reaches the target contrast.
function ensureContrast(value, background, target) {
    var source = hex6(value, foregroundFor(background));
    if (contrastRatio(source, background) >= target)
        return source;
    var foreground = foregroundFor(background);
    var low = 0;
    var high = 1;
    for (var i = 0; i < 16; i++) {
        var mid = (low + high) / 2;
        if (contrastRatio(mixHex(source, foreground, mid), background) >= target)
            high = mid;
        else
            low = mid;
    }
    return mixHex(source, foreground, high);
}

// A step of the text ladder: the ink mixed toward the surface, but never
// below the requested contrast.
function textTone(surface, ink, amount, target) {
    return ensureContrast(mixHex(surface, ink, amount), surface, target);
}

var exported = {
    hex6: hex6,
    luminance: luminance,
    contrastRatio: contrastRatio,
    mixHex: mixHex,
    foregroundFor: foregroundFor,
    ensureContrast: ensureContrast,
    textTone: textTone
};

if (typeof module !== "undefined" && module.exports)
    module.exports = exported;
