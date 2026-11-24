pragma Singleton
import QtQuick
import qs.Commons as Commons
import "../js/ThemeMath.js" as M

// The design tokens the old built-in GitHub widget read from Cybex OS's
// private Theme, rebuilt on the public Omarchy theme (qs.Commons) that Cybex
// OS feeds from the same shell settings: font, accent, panel surface, scale.
// Status hues the public theme does not carry (amber, green) use the
// built-in's own seeds, held to the same contrast floors.
QtObject {
    id: root

    // ---- scale -------------------------------------------------------------
    // At Cybex OS's defaults (14px base, 100% plugin scale) both are 1, so
    // every size below matches the built-in; the plugin interface scale and
    // font size move them together.
    readonly property real typeScale: Math.max(0.5, Commons.Style.fontBaseSize / 14)
    readonly property real contentScale: Math.max(0.5, Commons.Style.effectiveSpacingScale * 12 / 14)

    function scaled(value, scale) {
        return Math.round(value * (scale === undefined ? contentScale : scale));
    }

    // ---- surfaces and ink -----------------------------------------------------
    readonly property color panelSurface: Commons.Color.panelBackground
    readonly property color popBg: Commons.Color.popups.background
    readonly property string referenceHex: M.hex6(panelSurface.toString(), "#1c1b22")
    readonly property bool dark: M.luminance(referenceHex) < 0.4
    readonly property color background: panelSurface
    readonly property color copyReferenceBg: referenceHex
    readonly property string inkHex: M.hex6(Commons.Color.foreground.toString(), dark ? "#f2f0ea" : "#1f1d2b")

    readonly property color textHi: M.ensureContrast(inkHex, referenceHex, 7)
    readonly property color textMid: M.textTone(referenceHex, inkHex, 0.80, 4.5)
    readonly property color textLow: M.textTone(referenceHex, inkHex, 0.74, 4.5)
    readonly property color textDim: M.textTone(referenceHex, inkHex, 0.70, 4.5)
    readonly property color textFaint: M.textTone(referenceHex, inkHex, 0.66, 4.5)
    readonly property color icon: M.textTone(referenceHex, inkHex, 0.82, 4.5)
    readonly property color dotDim: Qt.rgba(textHi.r, textHi.g, textHi.b, dark ? 0.30 : 0.26)

    readonly property color hairlineSoft: Qt.rgba(textHi.r, textHi.g, textHi.b, dark ? 0.10 : 0.12)
    readonly property color stroke: Qt.rgba(textHi.r, textHi.g, textHi.b, 0.18)
    readonly property color hoverFill: Qt.rgba(textHi.r, textHi.g, textHi.b, dark ? 0.08 : 0.07)
    readonly property color hoverFillStrong: Qt.rgba(textHi.r, textHi.g, textHi.b, dark ? 0.16 : 0.13)
    readonly property real stateHoverOpacity: 0.08
    readonly property real statePressedOpacity: 0.12

    // ---- accent and status ------------------------------------------------------
    readonly property color accent: Commons.Color.accent
    readonly property color accentText: M.ensureContrast(accent.toString(), referenceHex, 4.5)
    readonly property color accentGlow: Qt.rgba(accent.r, accent.g, accent.b, 0.50)
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.24)
    readonly property color accentBg: accentSoft
    readonly property color accentBgSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.12)

    readonly property color red: Commons.Color.urgent
    readonly property color redText: M.ensureContrast(red.toString(), referenceHex, 4.5)
    readonly property color redBgSoft: Qt.rgba(red.r, red.g, red.b, 0.10)
    readonly property color redBorder: Qt.rgba(red.r, red.g, red.b, 0.38)

    readonly property color amberSeed: dark ? "#ffc26e" : "#b5761e"
    readonly property color amber: M.ensureContrast(amberSeed.toString(), referenceHex, 4.5)
    readonly property color amberBgSoft: Qt.rgba(amberSeed.r, amberSeed.g, amberSeed.b, dark ? 0.09 : 0.08)
    readonly property color amberBorder: Qt.rgba(amberSeed.r, amberSeed.g, amberSeed.b, dark ? 0.38 : 0.35)

    readonly property color okSeed: dark ? "#63d68c" : "#1f9d57"
    readonly property color ok: M.ensureContrast(okSeed.toString(), referenceHex, 4.5)
    readonly property color connected: ok

    // ---- type -------------------------------------------------------------------
    readonly property string fontMenu: Commons.Style.font.family
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontLabel: fontMono
    readonly property var typography: Commons.Style.typography
    readonly property int fontSecondary: typography.secondary
    readonly property int fontBody: typography.primary
    readonly property real proseLineHeight: 1.35
    readonly property int weightRegular: 400
    readonly property int weightMedium: 500
    readonly property int weightSemibold: 600
    readonly property var tabularNumberFeatures: ({ "tnum": 1 })

    readonly property int iconTiny: scaled(11, typeScale)
    readonly property int iconSmall: scaled(13, typeScale)
    readonly property int iconMedium: scaled(16, typeScale)
    readonly property int iconLarge: scaled(20, typeScale)
    readonly property int iconHero: scaled(27, typeScale)
    readonly property int barIconSize: scaled(15, typeScale)

    // ---- geometry ---------------------------------------------------------------
    readonly property int chipHeight: scaled(28)
    readonly property int chipInnerHeight: scaled(24)
    readonly property int chipRadius: 7
    readonly property int panelRadius: Commons.Style.cornerRadius
    readonly property int panelPadding: scaled(14)
    readonly property int sectionHeaderHeight: scaled(22)
    readonly property int listRowHeight: scaled(34)
    readonly property int panelHeaderHeight: scaled(52)
    readonly property int panelFooterHeight: scaled(30)
    readonly property int inlineActionHeight: scaled(32)
    readonly property int settingsControlHeight: Math.max(scaled(28), fontBody + scaled(12))
    readonly property int settingsRowSpacing: scaled(4)
    readonly property int settingsContentSpacing: scaled(8)
    readonly property int settingsGroupSpacing: scaled(28)
    readonly property int controlSpacing: scaled(8)
    readonly property int iconTextSpacing: scaled(6)
    readonly property int settingsMarkInset: scaled(18)

    // ---- motion -----------------------------------------------------------------
    // Set by the widget from the host bar's motion preference.
    property bool reducedMotion: false
    readonly property var springCurve: [0.32, 1.15, 0.3, 1.0, 1.0, 1.0]
    readonly property int chipFadeDuration: reducedMotion ? 0 : 160
    readonly property int expandDuration: reducedMotion ? 0 : 280

    // ---- focus ------------------------------------------------------------------
    // The shell draws focus rings only for keyboard focus. Plugins cannot see
    // its modality tracker, so the popover records pointer presses here and a
    // control focused within a moment of one (a click) draws no ring.
    property double lastPointerAt: 0
    readonly property int focusRingWidth: 2

    function focusWidth(focused) {
        return focused && Date.now() - lastPointerAt > 300 ? focusRingWidth : 0;
    }
}
