pragma Singleton
import QtQuick

// The roles the built-in GitHub popover shared with Cybex OS's T3 Code
// workspace: canvas, flat rows, compact controls. Derived from Theme.
QtObject {
    readonly property color canvas: Theme.background
    readonly property color surface: Theme.popBg
    readonly property color surfaceRaised: Theme.dark ? Qt.lighter(Theme.copyReferenceBg, 1.18) : Theme.popBg

    readonly property color textPrimary: Theme.textHi
    readonly property color textSecondary: Theme.textMid
    readonly property color textMuted: Theme.textLow
    readonly property color textFaint: Theme.textFaint

    readonly property color border: Theme.hairlineSoft
    readonly property color hover: Theme.hoverFill
    readonly property color hoverStrong: Theme.hoverFillStrong

    readonly property color accent: Theme.accentText
    readonly property color accentSoft: Theme.accentBg
    readonly property color accentSubtle: Theme.accentBgSoft
    readonly property color focus: Theme.accentGlow

    readonly property color amber: Theme.amber
    readonly property color amberBorder: Theme.amberBorder
    readonly property color red: Theme.redText
    readonly property color redSoft: Theme.redBgSoft
    readonly property color redBorder: Theme.redBorder
    readonly property color success: Theme.ok

    readonly property string fontUi: Theme.fontMenu
    readonly property string fontMono: Theme.fontMono
    readonly property var tabularNumberFeatures: Theme.tabularNumberFeatures

    readonly property int rowRadius: Theme.chipRadius
    readonly property int controlRadius: Theme.chipRadius
    readonly property int pagePadding: Theme.panelPadding
    readonly property int headerHeight: Theme.panelHeaderHeight
    readonly property int footerHeight: Theme.panelFooterHeight
    readonly property int quietRowHeight: Theme.listRowHeight
    readonly property int iconButtonSize: Theme.chipHeight

    readonly property int fastDuration: Theme.reducedMotion ? 0 : 140
    readonly property int normalDuration: Theme.reducedMotion ? 0 : 180
}
