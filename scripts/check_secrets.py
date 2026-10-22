#!/usr/bin/env python3
"""Scan staged changes, working files, or Git history without printing secrets."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def worktree_snapshot(root, destination):
    # Include untracked candidates, but never ignored files or Git metadata.
    result = subprocess.run(
        ["git", "-C", str(root), "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        capture_output=True, check=True,
    )
    for raw_name in set(result.stdout.split(b"\0")):
        if not raw_name:
            continue
        relative = Path(os.fsdecode(raw_name))
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("invalid path in Git file listing")
        source = root / relative
        target = destination / relative
        if source.is_symlink():
            # Inspect the link text, not the contents of an external target.
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(os.readlink(source), encoding="utf-8")
        elif source.is_file():
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("staged", "worktree", "history"), nargs="?", default="staged")
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--log-opts", default="--all", help="Git log options for history scans; defaults to all reachable refs")
    args = parser.parse_args()
    root = args.repo.resolve()
    config = root / ".gitleaks.toml"
    scanner = shutil.which("gitleaks")
    if not scanner:
        parser.exit(2, "Gitleaks is required; install it with `brew install gitleaks` or use the documented upstream release.\n")
    if not config.is_file():
        parser.exit(2, "Missing .gitleaks.toml; secret scanning was not performed.\n")

    try:
        with tempfile.TemporaryDirectory(prefix="dotfiles-secret-scan-") as scratch:
            scratch = Path(scratch)
            report = scratch / "findings.json"
            ignore = scratch / "empty-ignore"
            ignore.touch()
            command = [scanner, "--config", str(config), "--redact=100", "--no-banner",
                       "--no-color", "--log-level=error", "--exit-code=42",
                       "--ignore-gitleaks-allow", "--gitleaks-ignore-path", str(ignore),
                       "--report-format=json", "--report-path", str(report)]
            if args.mode == "worktree":
                snapshot = scratch / "worktree"
                snapshot.mkdir()
                worktree_snapshot(root, snapshot)
                command += ["dir", str(snapshot)]
            elif args.mode == "staged":
                command += ["git", "--staged", "--pre-commit", str(root)]
            else:
                command += ["git", "--log-opts=" + args.log_opts, str(root)]

            # Scanner output and report fields containing values are never echoed.
            result = subprocess.run(command, capture_output=True, cwd=root)
            if result.returncode == 0:
                print(f"Secret scan ({args.mode}): clean.")
                return 0
            if result.returncode != 42:
                print(f"Gitleaks failed (exit {result.returncode}); check its version and .gitleaks.toml. No successful scan was recorded.", file=sys.stderr)
                return 2

            findings = json.loads(report.read_text(encoding="utf-8"))
            print(f"Secret scan blocked: {len(findings)} potential credential(s). Values are hidden.", file=sys.stderr)
            for finding in findings:
                location = {"file": finding["File"], "line": finding["StartLine"], "rule": finding["RuleID"]}
                if args.mode == "history":
                    location["commit"] = finding["Commit"]
                if args.mode == "worktree":
                    file_path = Path(location["file"])
                    if file_path.is_absolute():
                        location["file"] = str(file_path.relative_to(snapshot))
                print(json.dumps(location, ensure_ascii=True), file=sys.stderr)
            print("Remove the credential and restage the file. Revoke it if it was exposed; see docs/secrets.md.", file=sys.stderr)
            return 1
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError):
        print("Secret scanner could not complete; no successful scan was recorded.", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
