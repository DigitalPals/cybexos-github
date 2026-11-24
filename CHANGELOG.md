# Changelog

## 1.0.0 — 2026-11-24

First release as a plugin. Cybex OS's built-in GitHub widget moved here.

- The Inbox, Repositories and Commits views, the live-workflow marker and the
  pending badge, polling and conditional requests work as in the built-in.
- One shared service polls for every output.
- Clear messages when `gh` is missing or not signed in, in the popover and
  the bar tooltip, instead of an endless "Loading".
- The badge setting works as named: Dot, Count (99+ at most) or Off.
- Account and watched repositories moved to the popover's gear page; the
  other options are plugin settings in Settings → Bar & Control Center.
- Keeps the built-in's state file and imports its options from shell.json
  once.
