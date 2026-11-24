pragma Singleton
import QtQuick
import Quickshell
import "../js/I18nCatalog.js" as Catalog

// The widget's text in the session's language, following the same rule as
// Cybex OS's shell: the login session's locale, overridable by CYBEXOS_LANG.
QtObject {
    readonly property string language: Catalog.languageFor([
        Quickshell.env("CYBEXOS_LANG"), Quickshell.env("LC_ALL"),
        Quickshell.env("LC_MESSAGES"), Quickshell.env("LANG")])
    readonly property var catalog: Catalog.catalogFor(language)

    function tr(text: string): string {
        return Catalog.translate(catalog, text);
    }
}
