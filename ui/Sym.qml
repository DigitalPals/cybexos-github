pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "../js/TablerGlyphs.js" as Tabler

// One Tabler icon in a stable square slot, as Cybex OS draws them: semantic
// (Material-style) names resolve through js/TablerGlyphs.js, unknown names
// draw help-circle and empty names draw nothing.
Item {
    id: root

    property string name: ""
    property real size: 16
    property color color: Theme.icon
    property bool animateColor: true
    property int horizontalAlignment: Text.AlignHCenter
    // Accepted for call-site parity with the shell; outlines have one stroke.
    property real symWeight: 500

    readonly property var glyph: Tabler.resolve(name)
    readonly property bool isSpinner: glyph.outline === Tabler.GLYPHS["loader-2"].outline
    implicitWidth: size
    implicitHeight: size

    Behavior on color {
        enabled: root.animateColor
        ColorAnimation { duration: Theme.chipFadeDuration }
    }

    // Tabler's font starts every glyph at the left edge of a full-width box;
    // centre the drawn ink instead.
    readonly property bool centreInk: root.horizontalAlignment === Text.AlignHCenter
    TextMetrics {
        id: ink
        font.family: TablerFont.outline.name
        font.pixelSize: root.size
        font.weight: Font.Normal
        text: root.glyph.outline
    }

    Text {
        x: root.centreInk ? (root.width - ink.tightBoundingRect.width) / 2 - ink.tightBoundingRect.x : 0
        width: root.centreInk ? Math.max(implicitWidth, root.width) : root.width
        height: root.height
        visible: TablerFont.ready && !root.isSpinner
        text: root.glyph.outline
        font.family: TablerFont.outline.name
        font.pixelSize: root.size
        font.weight: Font.Normal
        color: root.color
        horizontalAlignment: root.centreInk ? Text.AlignLeft : root.horizontalAlignment
        verticalAlignment: Text.AlignVCenter
        renderType: Text.QtRendering
        Accessible.ignored: true
    }

    // Tabler loader-2 (M12 3a9 9 0 1 0 9 9), drawn around the slot's exact
    // centre so it does not orbit when the enclosing Sym rotates.
    Loader {
        anchors.fill: parent
        active: root.isSpinner
        sourceComponent: Shape {
            preferredRendererType: Shape.CurveRenderer
            Accessible.ignored: true

            ShapePath {
                strokeColor: root.color
                strokeWidth: root.size / 12
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: root.width / 2
                    centerY: root.height / 2
                    radiusX: root.size * 3 / 8
                    radiusY: radiusX
                    startAngle: -90
                    sweepAngle: -270
                }
            }
        }
    }
}
