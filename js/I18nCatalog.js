// The widget's own text in the session's language, keyed by the English text.
// Dutch entries are the ones Cybex OS's shell catalog used for the built-in
// widget, plus translations of this plugin's new strings. Untranslated text
// stays English.

var LANGUAGES = ["en", "nl"];

var NL = {
    "ACCOUNT": "ACCOUNT",
    "Account and watched repositories": "Account en gevolgde repository's",
    "Add": "Toevoegen",
    "Checking…": "Controleren…",
    "Commits unavailable": "Commits niet beschikbaar",
    "Connected": "Verbonden",
    "Copied": "Gekopieerd",
    "Copy SHA": "SHA kopiëren",
    "Expand commit": "Commit uitvouwen",
    "GitHub": "GitHub",
    "GitHub unavailable": "GitHub niet beschikbaar",
    "Inbox": "Inbox",
    "Inbox is clear": "Inbox is leeg",
    "is already watched": "wordt al gevolgd",
    "Latest commits": "Recente commits",
    "Loading commits…": "Commits laden…",
    "Loading repositories…": "Repository's laden…",
    "New since last visit": "Nieuw sinds laatste bezoek",
    "No commits on this branch yet": "Nog geen commits op deze branch",
    "No repositories this account can see": "Geen repository's zichtbaar voor dit account",
    "Not a repository — use owner/repo, or paste its GitHub URL": "Geen repository — gebruik eigenaar/repo, of plak de GitHub-URL",
    "Not signed in": "Niet aangemeld",
    "Open on GitHub": "Openen op GitHub",
    "Reading the gh CLI's login…": "Aanmelding van de gh CLI lezen…",
    "Recent account and org repositories follow the count in the widget's settings. Every watched repository is added to that list and, when enabled, to the workflow-report scope. Repositories refresh on the interval in the widget's settings; the Inbox checks repository events and GitHub notifications every minute. Other options: Settings → Bar & Control Center → GitHub.":
        "Het aantal recente account- en organisatierepository's volgt de instellingen van de widget. Elke gevolgde repository komt daar bij en, als dat aanstaat, ook bij de workflowrapporten. Repository's verversen volgens de interval in de instellingen van de widget; de Inbox controleert repository-gebeurtenissen en GitHub-meldingen elke minuut. Overige opties: Instellingen → Balk en bedieningspaneel → GitHub.",
    "Repositories": "Repository's",
    "Repository to watch": "Te volgen repository",
    "Retry": "Opnieuw proberen",
    "Search repositories": "Repository's zoeken",
    "Settle all": "Alles afhandelen",
    "Show commits": "Commits tonen",
    "Statistics unavailable": "Statistieken niet beschikbaar",
    "Unavailable": "Niet beschikbaar",
    "WATCHED REPOS": "GEVOLGDE REPO'S",
    "counting…": "tellen…"
};

// The language a POSIX locale value names; the first of LC_ALL, LC_MESSAGES,
// LANG that names one decides, as gettext does. CYBEXOS_LANG overrides.
function languageFor(values) {
    var list = (Array.isArray(values) || values instanceof Array) ? values : [values];
    for (var i = 0; i < list.length; i++) {
        var value = String(list[i] || "").trim();
        if (value === "" || value === "C" || value === "POSIX" || value.indexOf("C.") === 0)
            continue;
        var language = value.split(/[_.@-]/)[0].toLowerCase();
        return LANGUAGES.indexOf(language) === -1 ? "en" : language;
    }
    return "en";
}

function catalogFor(language) {
    return language === "nl" ? NL : {};
}

function translate(catalog, text) {
    var key = text === undefined || text === null ? "" : String(text);
    if (key === "" || !catalog)
        return key;
    var value = catalog[key];
    return typeof value === "string" && value !== "" ? value : key;
}

var exported = { LANGUAGES: LANGUAGES, NL: NL, languageFor: languageFor,
    catalogFor: catalogFor, translate: translate };

if (typeof module !== "undefined" && module.exports)
    module.exports = exported;
