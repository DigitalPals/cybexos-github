#!/usr/bin/env python3
"""Load the plugin in Cybex OS's real Quickshell host, headless.

Needs a Cybex OS checkout and its dev shell (qs, sway, grim, jq):

    cd /path/to/CybexOS && nix develop --command \\
        python3 /path/to/cybexos-github/tests/engine/run.py --cybexos . [--shots DIR]

Everything runs in a throwaway home, runtime directory, session bus and
headless Sway with two outputs; the checkout is only read. The plugin is
validated and enabled through Cybex OS's own plugin helper, then three runs
check the widget and popover: without gh on PATH, with a signed-out gh, and
with a fake gh serving canned GitHub data (tests/engine/fake-gh).
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import tempfile
import time

PLUGIN = Path(__file__).resolve().parents[2]
PLUGIN_ID = "digitalpals.github-inbox"
DBUS = ["dbus-run-session", *(["--config-file", os.environ["CYBEXOS_DBUS_SESSION_CONFIG"]]
                               if os.environ.get("CYBEXOS_DBUS_SESSION_CONFIG") else []), "--"]
ERRORS = re.compile(r"(?:Type|Reference|Range|Syntax)Error|Binding loop|Failed to load configuration"
                    r"|is not a type|is not installed|Cannot assign|Unable to assign")


def end_group(process: subprocess.Popen) -> None:
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    process.wait()


def without_gh(path: str) -> str:
    return os.pathsep.join(entry for entry in path.split(os.pathsep)
                           if entry and not (Path(entry) / "gh").exists())


def run_mode(mode: str, checkout: Path, shots: Path | None) -> None:
    shell = checkout / "desktop/quickshell"
    helper = shell / "scripts/user-plugins.py"
    with tempfile.TemporaryDirectory(prefix="ghp-", dir="/tmp") as temporary:
        base = Path(temporary)
        env = dict(os.environ, HOME=str(base / "home"), XDG_CONFIG_HOME=str(base / "config"),
                   XDG_DATA_HOME=str(base / "data"), XDG_STATE_HOME=str(base / "state"),
                   XDG_RUNTIME_DIR=str(base / "run"), QT_QUICK_BACKEND="software")
        for key in ("CYBEXOS_USER_CONFIG_ROOT", "CYBEXOS_PLUGIN_ROOT", "WAYLAND_DISPLAY", "DISPLAY"):
            env.pop(key, None)
        (base / "run").mkdir(mode=0o700)
        (base / "home").mkdir()
        bin_dir = base / "bin"
        bin_dir.mkdir()
        env["PATH"] = without_gh(env["PATH"])
        if mode != "missing":
            os.symlink(PLUGIN / "tests/engine/fake-gh", bin_dir / "gh")
            env["PATH"] = f"{bin_dir}{os.pathsep}{env['PATH']}"
            env["FAKE_GH_MODE"] = mode
        if mode == "data":
            # The old built-in's options, which the plugin imports once.
            shell_json = base / "home/.config/cybexos/shell.json"
            shell_json.parent.mkdir(parents=True)
            shell_json.write_text(json.dumps({"modOpts": {"gh": {"badge": "count", "repos": 8,
                                                                  "watch": ["octocat/hello-world"]}}}))

        package = base / "data/cybexos/plugins" / PLUGIN_ID
        shutil.copytree(PLUGIN, package, ignore=shutil.ignore_patterns(".git", "tests", "*.png"))

        def cli(*args):
            return subprocess.run(["python3", str(helper), *args], env=env, text=True,
                                  capture_output=True, check=True)

        listing = json.loads(cli("list").stdout)
        entry = next(item for item in listing["plugins"] if item["id"] == PLUGIN_ID)
        assert not entry.get("error"), entry
        assert entry["kinds"] == ["service", "bar-widget"], entry["kinds"]
        cli("enable", PLUGIN_ID, "--section", "right", "--width", "120")

        env.update(QT_QPA_PLATFORM="wayland", WLR_BACKENDS="headless", WLR_RENDERER="pixman",
                   WLR_LIBINPUT_NO_DEVICES="1", WLR_HEADLESS_OUTPUTS="2")
        (base / "sway.conf").write_text("output HEADLESS-1 mode 1280x720\n")
        sway = base / "sway"
        shutil.copyfile(os.environ.get("CYBEXOS_SWAY_BINARY") or shutil.which("sway"), sway)
        sway.chmod(0o700)
        with (base / "sway.log").open("w+") as log:
            compositor = subprocess.Popen([*DBUS, str(sway), "-c", str(base / "sway.conf")], env=env,
                                          stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            try:
                deadline = time.monotonic() + 10
                sockets = []
                while time.monotonic() < deadline and compositor.poll() is None and not sockets:
                    sockets = [p for p in (base / "run").glob("wayland-*") if p.is_socket()]
                    time.sleep(0.05)
                if not sockets:
                    log.seek(0)
                    raise RuntimeError("headless compositor did not start: " + log.read())
                env["WAYLAND_DISPLAY"] = sockets[0].name

                runtime = base / "runtime"
                shutil.copytree(shell, runtime)
                shutil.copy2(PLUGIN / "tests/engine/shell.qml", runtime / "shell.qml")
                check_env = dict(env, OMARCHY_PATH=str(runtime / "compat/omarchy"),
                                 GITHUB_CHECK_MODE=mode, GITHUB_CHECK_SHOTS=str(shots or ""))
                process = subprocess.Popen([*DBUS, "qs", "--no-color", "-p", str(runtime)], env=check_env,
                                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                                           start_new_session=True)
                try:
                    output, _ = process.communicate(timeout=45)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGTERM)
                    output, _ = process.communicate(timeout=3)
                    raise AssertionError(output) from None
                finally:
                    end_group(process)
            finally:
                end_group(compositor)

        ours = "\n".join(line for line in output.splitlines()
                         if PLUGIN_ID in line or "cybex-plugin-code" in line or "GITHUB_PLUGIN" in line)
        assert f"GITHUB_PLUGIN pass {mode}" in output, output
        assert not ERRORS.search(ours), ours
        if mode == "data":
            saved = json.loads((base / "config/cybexos/plugins.json").read_text())
            settings = saved["plugins"][PLUGIN_ID]["settings"]
            assert settings == {"badge": "count", "watch": ["octocat/hello-world", "octocat/missing"]}, settings
            state = json.loads((base / "home/.local/state/cybexos/shell/github.json").read_text())
            assert state["settingsImported"] is True and state["seenAt"], state
        print(f"real engine, {mode}: plugin loaded, widget drew, popover opened, no QML errors")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cybexos", type=Path, default=Path(os.environ.get("CYBEXOS_CHECKOUT", ".")))
    parser.add_argument("--shots", type=Path)
    parser.add_argument("--mode", choices=("missing", "signed-out", "data"), action="append")
    args = parser.parse_args()
    if args.shots:
        args.shots.mkdir(parents=True, exist_ok=True)
    for mode in args.mode or ("missing", "signed-out", "data"):
        run_mode(mode, args.cybexos.resolve(), args.shots.resolve() if args.shots else None)


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, lambda *_: (_ for _ in ()).throw(SystemExit(143)))
    main()
