pragma Singleton
import QtQuick

// The Tabler 3.48.0 outline subset Cybex OS bundles (MIT, assets/tabler/
// LICENSE), loaded from this package so the plugin needs no shell assets.
QtObject {
    readonly property FontLoader outline: FontLoader {
        source: "../assets/tabler/outline.ttf"
    }
    readonly property bool ready: outline.status === FontLoader.Ready
}
