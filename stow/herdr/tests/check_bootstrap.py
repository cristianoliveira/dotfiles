#!/usr/bin/env python3
"""Bootstrap Herdr from an uninitialized child submodule in disposable homes."""
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[3]
CHILD = ROOT / "herdr-term"
CHECKER = Path(__file__).resolve()
BASH = Path("/bin/bash").resolve(strict=True)
BLOCKED = ("nix", "nix-shell", "herdr-app", "hc")
MOCKED = ("stow", *BLOCKED)
SYSTEM_TOOLS = (
    "bash", "sh", "env", "ls", "basename", "dirname", "mkdir", "cp", "mv",
    "rm", "chmod", "ln", "readlink", "uname", "tar", "gzip",
)


def executable(path):
    path = Path(path).resolve(strict=True)
    if not path.is_file() or not os.access(path, os.X_OK):
        raise RuntimeError(f"Required executable is missing or not executable: {path}")
    return path


def safe_tool(name, host_path):
    if name == "bash":
        return executable(BASH)
    if name == "git-upload-pack":
        git = shutil.which("git", path=host_path)
        candidates = [Path(git).resolve(strict=True).parent / name] if git else []
    else:
        candidates = []
    found = shutil.which(name, path=host_path if name in {"git", "node", "npm", "python3"} else os.defpath)
    if found:
        candidates.append(Path(found))
    for candidate in candidates:
        try:
            return executable(candidate)
        except (OSError, RuntimeError):
            continue
    raise RuntimeError(f"Required allowlisted tool is unavailable: {name}")


def write_executable(path, content):
    path.write_text(content)
    path.chmod(0o755)
    if path.is_symlink() or path.resolve(strict=True).parent != path.parent.resolve(strict=True):
        raise RuntimeError(f"Mock command escaped its controlled directory: {path}")


def resolve_in_path(name, search_path):
    found = shutil.which(name, path=search_path)
    if found is None:
        raise RuntimeError(f"Required controlled command is missing: {name}")
    return executable(found)


def validate_mocks(mock_bin, safe_bin, search_path, expected_tools=None):
    mock_bin = mock_bin.resolve(strict=True)
    for name in MOCKED:
        expected = mock_bin / name
        if not expected.is_file() or expected.is_symlink() or not os.access(expected, os.X_OK):
            raise RuntimeError(f"Expected executable controlled {name} mock: {expected}")
        resolved = resolve_in_path(name, search_path)
        if resolved != expected:
            raise RuntimeError(f"Expected controlled {name} mock, resolved to {resolved}")

    tools = {}
    for name in ("git", "node", "npm", "python3"):
        expected = (expected_tools or {}).get(name, safe_bin / name)
        if expected == safe_bin / name and (not expected.is_symlink() or not expected.exists()):
            raise RuntimeError(f"Expected explicit safe-tool link for {name}: {expected}")
        resolved = resolve_in_path(name, search_path)
        if resolved != Path(expected).resolve(strict=True):
            raise RuntimeError(f"Unexpected {name} resolution: {resolved}")
        tools[name] = resolved
    return tools


def controlled_environment(home, search_path, trace, extra=None):
    environment = {
        "HOME": str(home),
        "PATH": search_path,
        "HERDR_STOW_TRACE": str(trace),
        "LANG": "C.UTF-8",
        "LC_ALL": "C.UTF-8",
        "GIT_ALLOW_PROTOCOL": "file",
    }
    for key in ("HTTPS_PROXY", "HTTP_PROXY", "ALL_PROXY", "NO_PROXY", "SSL_CERT_FILE"):
        if key in os.environ:
            environment[key] = os.environ[key]
    if extra:
        environment.update(extra)
    return environment


def create_controlled_path(work, host_path):
    mock_bin = work / "mock-bin"
    safe_bin = work / "safe-bin"
    mock_bin.mkdir()
    safe_bin.mkdir()
    forbidden_trace = work / "forbidden.log"
    write_executable(
        mock_bin / "stow",
        '#!/bin/sh\nprintf "%s\\n" "$*" >> "$HERDR_STOW_TRACE"\n',
    )
    for name in BLOCKED:
        write_executable(
            mock_bin / name,
            f'#!/bin/sh\nprintf "{name}\\n" >> "{forbidden_trace}"\nexit 97\n',
        )
    for name in ("git", "node", "npm", "python3", "git-upload-pack", *SYSTEM_TOOLS):
        try:
            source = safe_tool(name, host_path)
        except RuntimeError:
            if name in {"git-upload-pack", *SYSTEM_TOOLS}:
                continue
            raise
        link = safe_bin / name
        if not link.exists():
            link.symlink_to(source)
    search_path = f"{mock_bin}:{safe_bin}"
    tools = validate_mocks(mock_bin, safe_bin, search_path)
    return mock_bin, safe_bin, search_path, tools, forbidden_trace


def guard_refusal_checks():
    """Prove invalid mock resolution fails without executing sentinel programs."""
    with tempfile.TemporaryDirectory(prefix="herdr-bootstrap-guards-") as temporary:
        work = Path(temporary)
        mock_bin = work / "mock-bin"
        safe_bin = work / "safe-bin"
        outer_bin = work / "outer-bin"
        mock_bin.mkdir()
        safe_bin.mkdir()
        outer_bin.mkdir()
        trace = work / "sentinel.log"
        write_executable(mock_bin / "stow", "#!/bin/sh\nexit 0\n")
        for name in BLOCKED:
            write_executable(
                mock_bin / name,
                f'#!/bin/sh\nprintf "ran:{name}\\n" >> "{trace}"\nexit 97\n',
            )
        for name in ("git", "node", "npm", "python3"):
            link = safe_bin / name
            link.symlink_to(safe_tool(name, os.environ.get("PATH", os.defpath)))
        base_path = f"{mock_bin}:{safe_bin}"

        # Missing, wrong-directory, and non-executable guards must all fail closed.
        for label in ("missing", "wrong", "nonexec"):
            case_path = base_path
            target = mock_bin / "hc"
            original = target.read_bytes()
            if label == "missing":
                target.unlink()
            elif label == "wrong":
                write_executable(
                    outer_bin / "hc",
                    f'#!/bin/sh\nprintf "ran:hc\\n" >> "{trace}"\nexit 97\n',
                )
                case_path = f"{outer_bin}:{mock_bin}:{safe_bin}"
            else:
                target.chmod(stat.S_IRUSR | stat.S_IWUSR)
            try:
                try:
                    validate_mocks(mock_bin, safe_bin, case_path)
                except RuntimeError:
                    pass
                else:
                    raise AssertionError(f"guard accepted {label} blocked-command resolution")
                if trace.exists():
                    raise AssertionError(f"guard executed a sentinel during {label} check")
            finally:
                if target.exists():
                    target.unlink()
                write_executable(target, original.decode())


def run_setup(root, home, search_path, trace, forbidden_trace, *, check=True, extra=None):
    mock_bin = Path(search_path.split(":", 1)[0])
    safe_bin = Path(search_path.split(":", 1)[1])
    validate_mocks(mock_bin, safe_bin, search_path)
    environment = controlled_environment(home, search_path, trace, extra)
    result = subprocess.run(
        [str(BASH), str(root / "stow/install.sh"), "herdr"],
        cwd=root,
        env=environment,
        text=True,
        capture_output=True,
        timeout=900,
        check=False,
    )
    if check and result.returncode != 0:
        raise AssertionError(f"Herdr setup failed ({result.returncode}):\n{result.stdout}\n{result.stderr}")
    if forbidden_trace.exists():
        raise AssertionError(f"blocked command was invoked: {forbidden_trace.read_text()}")
    return result


def active_generation(app_home, node, search_path, mod="muxcle-picker"):
    environment = controlled_environment(app_home.parent.parent, search_path, app_home.parent / "status.log")
    result = subprocess.run(
        [str(node), str(CHILD / "scripts/dev-loop.mjs"), "status", "--mod", mod, "--app-home", str(app_home)],
        env=environment,
        text=True,
        capture_output=True,
        timeout=30,
        check=False,
    )
    if result.returncode != 0:
        raise AssertionError(f"dev-loop status failed:\n{result.stdout}\n{result.stderr}")
    return json.loads(result.stdout)["active"]


def generation_count(child):
    root = child / ".build/dev-generations"
    if not root.exists():
        return 0
    return sum(path.is_dir() and not path.name.startswith(".") for path in root.iterdir())


def exercise_checkout(root, work, search_path, tools, forbidden_trace):
    trace = work / "stow.log"
    home = work / "home"
    app_home = home / ".config/herdr-app"
    (app_home / "mods").mkdir(parents=True)
    settings = app_home / "settings.json"
    settings.write_text('{"preserve": true}\n')
    old_keys = app_home / "keys.json"
    old_keys.write_text("keep existing keys\n")
    old_layout = app_home / "layouts/tmux.json"
    old_layout.parent.mkdir()
    old_layout.write_text("keep existing layout\n")
    dotfiles_home = home / ".dotfiles"
    dotfiles_home.symlink_to(root, target_is_directory=True)

    result = run_setup(root, home, search_path, trace, forbidden_trace)
    child = root / "herdr-term"
    target = app_home / "mods/muxcle-picker"
    if not target.is_symlink():
        raise AssertionError("setup did not create the selected development link")
    link_target = target.resolve(strict=True)
    managed_root = (child / ".build/dev-generations").resolve(strict=True)
    if managed_root not in link_target.parents:
        raise AssertionError(f"development link escaped managed generations: {link_target}")
    active_id = active_generation(app_home, tools["node"], search_path)
    generation_id = link_target.parents[2].name
    if active_id != generation_id:
        raise AssertionError(f"installed link generation {generation_id} differs from active {active_id}")

    selected_mods = [
        name for line in (root / "stow/herdr/dev-mods.txt").read_text().splitlines()
        if (name := line.partition("#")[0].strip())
    ]
    for mod in selected_mods:
        selected_target = app_home / "mods" / mod
        if not selected_target.is_symlink():
            raise AssertionError(f"setup did not create selected development link: {mod}")
        installed = selected_target.resolve(strict=True)
        if managed_root not in installed.parents:
            raise AssertionError(f"selected development link escaped managed generations: {mod}")
        if active_generation(app_home, tools["node"], search_path, mod) != installed.parents[2].name:
            raise AssertionError(f"selected development link has a different active generation: {mod}")
        owner = json.loads((installed / "package-owner.json").read_text())
        if owner != {"schema": 1, "package": mod} or not (installed / "main.js").is_file():
            raise AssertionError(f"selected development payload is incomplete or unowned: {mod}")

    views_file = root / "stow/herdr/native-views.json"
    native_views = json.loads(views_file.read_text())["views"] if views_file.exists() else {}
    for name, options in native_views.items():
        alias = app_home / "mods" / name
        if not alias.is_symlink() or alias.readlink() != Path(options["module"]):
            raise AssertionError(f"native view does not reuse its declared provider: {name}")
    expected_mods = set(selected_mods) | set(native_views)
    installed_mods = {entry.name for entry in (app_home / "mods").iterdir()}
    if installed_mods != expected_mods:
        raise AssertionError(
            f"installed modules differ from configured ownership: "
            f"missing={sorted(expected_mods - installed_mods)}, "
            f"unexpected={sorted(installed_mods - expected_mods)}"
        )

    if settings.read_text() != '{"preserve": true}\n':
        raise AssertionError("setup changed the unmanaged app-home setting")
    backups = list((home / ".config").glob("herdr-app.backup.*"))
    if len(backups) != 1:
        raise AssertionError(f"expected one Herdr config backup, found {len(backups)}")
    if not old_keys.is_symlink() or old_keys.resolve() != (
        root / "stow/herdr/.config/herdr-app/keys.json"
    ).resolve():
        raise AssertionError("setup did not link the managed keys file")
    if (backups[0] / "keys.json").read_text() != "keep existing keys\n":
        raise AssertionError("setup did not preserve the previous keys file")
    if not old_layout.is_symlink() or old_layout.resolve() != (
        root / "stow/herdr/.config/herdr-app/layouts/tmux.json"
    ).resolve():
        raise AssertionError("setup did not link the managed layout")
    if (backups[0] / "layouts/tmux.json").read_text() != "keep existing layout\n":
        raise AssertionError("setup did not preserve the previous layout")
    sessionizer_config = app_home / "data/muxcle-sessionizer/config.json"
    if not sessionizer_config.is_symlink() or sessionizer_config.resolve() != (
        root / "nix/shared/herdr/sessionizer.json"
    ).resolve():
        raise AssertionError("setup missed the personal Sessionizer configuration")
    if (app_home / "data").is_symlink() or sessionizer_config.parent.is_symlink():
        raise AssertionError("setup linked a mutable data container instead of the config file")

    # An existing foreign target stops before generation build or Stow calls.
    conflict_home = work / "conflict-home"
    conflict_app = conflict_home / ".config/herdr-app"
    (conflict_app / "mods").mkdir(parents=True)
    conflict_keys = conflict_app / "keys.json"
    conflict_keys.write_text("preserve this file\n")
    foreign_target = work / "foreign-mod"
    foreign_target.mkdir()
    foreign_link = conflict_app / "mods/muxcle-picker"
    foreign_link.symlink_to(foreign_target, target_is_directory=True)
    before_generations = generation_count(child)
    before_stow = trace.read_text().splitlines()
    failed = run_setup(root, conflict_home, search_path, trace, forbidden_trace, check=False)
    if failed.returncode == 0:
        raise AssertionError("setup unexpectedly replaced a foreign development link")
    if conflict_keys.read_text() != "preserve this file\n" or foreign_link.resolve() != foreign_target.resolve():
        raise AssertionError("foreign-link rejection changed the app home")
    if generation_count(child) != before_generations:
        raise AssertionError("foreign-link rejection built another generation")
    if trace.read_text().splitlines() != before_stow:
        raise AssertionError("Stow ran after the foreign-link preflight failed")

    # A late build failure cannot move any known-good target or run Stow.
    old_links = {mod: (app_home / "mods" / mod).readlink() for mod in selected_mods}
    before_stow = trace.read_text().splitlines()
    fail_bin = work / "failing-node-bin"
    fail_bin.mkdir()
    real_node = tools["node"]
    wrapper = fail_bin / "node"
    write_executable(
        wrapper,
        "#!/bin/sh\n"
        'case "$*" in\n'
        f'  *"dev-loop.mjs build --mod {selected_mods[-1]}"*) echo "forced build failure" >&2; exit 42 ;;\n'
        f'  *) exec "{real_node}" "$@" ;;\n'
        'esac\n',
    )
    failing_path = f"{fail_bin}:{search_path}"
    validate_mocks(
        Path(search_path.split(":", 1)[0]),
        Path(search_path.split(":", 1)[1]),
        failing_path,
        expected_tools={"node": wrapper.resolve(strict=True)},
    )
    environment = controlled_environment(home, failing_path, trace)
    failed = subprocess.run(
        [str(BASH), str(root / "stow/install.sh"), "herdr"],
        cwd=root,
        env=environment,
        text=True,
        capture_output=True,
        timeout=900,
        check=False,
    )
    if failed.returncode == 0 or "forced build failure" not in failed.stderr:
        raise AssertionError(f"build failure was not reported:\n{failed.stdout}\n{failed.stderr}")
    if any((app_home / "mods" / mod).readlink() != old_links[mod] for mod in selected_mods):
        raise AssertionError("failed build replaced a last-good development link")
    if trace.read_text().splitlines() != before_stow:
        raise AssertionError("Stow ran after the failed build")
    if forbidden_trace.exists():
        raise AssertionError(f"blocked command was invoked: {forbidden_trace.read_text()}")


def candidate_files():
    return (
        "Makefile",
        "install.sh",
        "stow/install.sh",
        "stow/herdr/before_install.sh",
        "stow/herdr/install.py",
        "stow/herdr/dev-mods.txt",
        "stow/herdr/native-views.json",
        "stow/herdr/.stow-local-ignore",
        "stow/herdr/tests/check_bootstrap.py",
    )


def prepare_fresh_checkout(work, tools, search_path):
    checkout = work / "fresh-dotfiles"
    commit = subprocess.run(
        [str(tools["git"]), "rev-parse", "HEAD"], cwd=ROOT, env=controlled_environment(work, search_path, work / "clone.log"),
        text=True, capture_output=True, timeout=30, check=True,
    ).stdout.strip()
    environment = controlled_environment(work, search_path, work / "clone.log")
    subprocess.run(
        [str(tools["git"]), "clone", "--no-checkout", "--local", str(ROOT), str(checkout)],
        env=environment, text=True, capture_output=True, timeout=60, check=True,
    )
    subprocess.run(
        [str(tools["git"]), "-C", str(checkout), "checkout", "--detach", commit],
        env=environment, text=True, capture_output=True, timeout=60, check=True,
    )
    for relative in candidate_files():
        source = ROOT / relative
        target = checkout / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    obsolete_checker = checkout / "scripts/check-herdr-bootstrap.py"
    obsolete_checker.unlink(missing_ok=True)

    child = checkout / "herdr-term"
    if (child / ".git").exists():
        raise AssertionError("fresh checkout unexpectedly initialized the child submodule")
    source_child = Path(os.environ.get("HERDR_SUBMODULE_SOURCE", str(CHILD))).resolve(strict=True)
    subprocess.run(
        [str(tools["git"]), "-C", str(checkout), "config", "submodule.herdr-term.url", str(source_child)],
        env=environment, text=True, capture_output=True, timeout=30, check=True,
    )
    return checkout, source_child


def main():
    # Exercise guard failures before any integration helper or command sentinel can run.
    guard_refusal_checks()
    with tempfile.TemporaryDirectory(prefix="herdr-bootstrap-") as temporary:
        work = Path(temporary)
        mock_bin, safe_bin, search_path, tools, forbidden_trace = create_controlled_path(
            work, os.environ.get("PATH", os.defpath)
        )
        if os.environ.get("HERDR_BOOTSTRAP_FRESH_CHECKOUT") == "1":
            if (CHILD / ".git").exists():
                raise AssertionError("fresh checkout child was initialized before the setup test")
            exercise_checkout(ROOT, work, search_path, tools, forbidden_trace)
            fresh_child = ROOT / "herdr-term"
            if not (fresh_child / ".git").exists():
                raise AssertionError("bootstrap did not initialize the uninitialized child submodule")
            after_child_status = subprocess.run(
                [str(tools["git"]), "-C", str(fresh_child), "status", "--porcelain", "--untracked-files=all"],
                env=controlled_environment(work, search_path, work / "source-status.log"),
                text=True, capture_output=True, timeout=30, check=True,
            ).stdout
            if after_child_status:
                raise AssertionError(
                    "fresh bootstrap left tracked or non-ignored writes in the initialized child: "
                    f"{after_child_status!r}"
                )
            print("Fresh uninitialized-submodule bootstrap passed in a disposable clone and HOME.")
            return 0

        current_child_status = subprocess.run(
            [str(tools["git"]), "-C", str(CHILD), "status", "--porcelain", "--untracked-files=all"],
            env=controlled_environment(work, search_path, work / "source-status.log"),
            text=True, capture_output=True, timeout=30, check=True,
        ).stdout
        checkout, source_child = prepare_fresh_checkout(work, tools, search_path)
        child_pin = subprocess.run(
            [str(tools["git"]), "-C", str(source_child), "rev-parse", "HEAD"],
            env=controlled_environment(work, search_path, work / "source-status.log"),
            text=True, capture_output=True, timeout=30, check=True,
        ).stdout.strip()
        expected_pin = subprocess.run(
            [str(tools["git"]), "-C", str(checkout), "rev-parse", "HEAD:herdr-term"],
            env=controlled_environment(work, search_path, work / "source-status.log"),
            text=True, capture_output=True, timeout=30, check=True,
        ).stdout.strip()
        if child_pin != expected_pin:
            raise AssertionError(f"fresh clone source does not match gitlink {expected_pin}")
        nested_environment = controlled_environment(
            work,
            search_path,
            work / "nested.log",
            {"HERDR_BOOTSTRAP_FRESH_CHECKOUT": "1", "HERDR_SUBMODULE_SOURCE": str(source_child)},
        )
        nested = subprocess.run(
            [str(tools["python3"]), "-B", str(checkout / "stow/herdr/tests/check_bootstrap.py")],
            cwd=checkout,
            env=nested_environment,
            text=True,
            capture_output=True,
            timeout=1200,
            check=False,
        )
        if nested.returncode != 0:
            raise AssertionError(f"fresh-clone Herdr bootstrap failed:\n{nested.stdout}\n{nested.stderr}")
        if subprocess.run(
            [str(tools["git"]), "-C", str(CHILD), "status", "--porcelain", "--untracked-files=all"],
            env=controlled_environment(work, search_path, work / "source-status.log"),
            text=True, capture_output=True, timeout=30, check=True,
        ).stdout != current_child_status:
            raise AssertionError("fresh-clone bootstrap changed the source child checkout")
        print(nested.stdout.strip())
        print("Herdr bootstrap passed with a fresh dotfiles clone and uninitialized pinned submodule.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
