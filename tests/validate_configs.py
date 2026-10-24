#!/usr/bin/env python3
"""Parse active POSIX configs without sourcing them or starting plugins."""

import argparse
import ast
import collections
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import tomllib

import yaml


def quoted_end(text, start):
    """Skip a JSON string, leaving malformed strings for json.loads to reject."""
    index = start + 1
    while index < len(text):
        if text[index] == "\\":
            index += 2
        elif text[index] == '"':
            return index + 1
        else:
            index += 1
    return len(text)


def jsonc_to_json(text):
    """Replace JSONC comments/trailing commas with spaces, preserving positions."""
    result = list(text)
    index = 0
    while index < len(text):
        if text[index] == '"':
            index = quoted_end(text, index)
            continue
        if text.startswith("//", index):
            end = index + 2
            while end < len(text) and text[end] not in "\r\n":
                end += 1
        elif text.startswith("/*", index):
            closing = text.find("*/", index + 2)
            if closing < 0:
                line = text.count("\n", 0, index) + 1
                raise ValueError(f"unterminated JSONC comment at line {line}")
            end = closing + 2
        else:
            index += 1
            continue
        for position in range(index, end):
            if result[position] not in "\r\n":
                result[position] = " "
        index = end

    text = "".join(result)
    index = 0
    previous = None
    while index < len(text):
        if text[index] == '"':
            index = quoted_end(text, index)
            previous = '"'
            continue
        if text[index] == ",":
            following = index + 1
            while following < len(text) and text[following] in " \t\r\n":
                following += 1
            # Do not turn invalid inputs such as [,] or [1,,] into valid JSON.
            if (following < len(text) and text[following] in "]}"
                    and previous is not None and previous not in "[{,:"):
                result[index] = " "
        if text[index] not in " \t\r\n":
            previous = text[index]
        index += 1
    return "".join(result)


def reject_json_constant(value):
    raise ValueError(f"non-JSON numeric constant: {value}")


def parse_json(text, *, comments=False):
    if comments:
        text = jsonc_to_json(text)
    return json.loads(text, parse_constant=reject_json_constant)


def file_format(relative):
    path = relative.as_posix()
    if path == ".gitleaks.toml":
        return "toml"
    # Archived notes and native Windows validation are deliberately deferred.
    if not path.startswith(("packages/", "tests/", "scripts/", ".github/", "bin/")):
        return None
    if path == "bin/dotfiles" or relative.suffix == ".sh":
        return "bash"
    if path in ("packages/git/.config/git/hooks/pre-commit", "tests/fixtures/secret-backend",
                "packages/tmux/.local/bin/dotfiles-clipboard"):
        return "sh"
    if relative.name in (".zshrc", ".zshenv") or path.endswith((".zsh", ".zsh.example")):
        return "zsh"
    if path.endswith((".fish", ".fish.example")):
        return "fish"
    if relative.suffix == ".lua":
        return "lua"
    if relative.suffix == ".toml":
        return "toml"
    if relative.suffix in (".yml", ".yaml") or relative.name == ".clang-format":
        return "yaml"
    if relative.suffix == ".json":
        return "jsonc" if path.startswith("packages/vscode-macos/") else "json"
    if path in ("packages/git/.config/git/config", "packages/git/.config/git/config.local.example"):
        return "git"
    if relative.suffix == ".py":
        return "python"
    return None


def run_parser(command, *, env):
    result = subprocess.run(command, env=env, text=True, capture_output=True)
    if result.returncode:
        diagnostic = result.stderr.strip() or result.stdout.strip()
        raise ValueError(diagnostic or f"parser exited {result.returncode}")


def validate(path, kind, env):
    if kind in ("bash", "sh"):
        run_parser([kind, "-n", str(path)], env=env)
    elif kind == "zsh":
        run_parser(["zsh", "-d", "-f", "-n", str(path)], env=env)
    elif kind == "fish":
        run_parser(["fish", "--no-config", "--no-execute", str(path)], env=env)
    elif kind == "lua":
        # loadfile compiles in Neovim's Lua runtime but never calls the chunk.
        lua_env = dict(env, DOTFILES_VALIDATE_LUA=str(path))
        check = ("lua local _, err = loadfile(vim.env.DOTFILES_VALIDATE_LUA); "
                 "if err then io.stderr:write(err .. '\\n'); vim.cmd('cquit 1') end")
        run_parser(["nvim", "--headless", "-u", "NONE", "-i", "NONE", "-n",
                    "--noplugin", "-c", check, "-c", "qa!"], env=lua_env)
    elif kind == "git":
        run_parser(["git", "config", "--file", str(path), "--no-includes", "--list"], env=env)
    elif kind == "toml":
        with path.open("rb") as source:
            tomllib.load(source)
    elif kind in ("json", "jsonc"):
        parse_json(path.read_text(encoding="utf-8-sig"), comments=kind == "jsonc")
    elif kind == "yaml":
        yaml.safe_load(path.read_text(encoding="utf-8-sig"))
    elif kind == "python":
        ast.parse(path.read_text(encoding="utf-8"), filename=str(path))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    root = args.root.resolve()

    missing = [tool for tool in ("git", "bash", "sh", "zsh", "fish", "nvim")
               if shutil.which(tool) is None]
    if missing:
        parser.exit(1, "Missing validators: " + ", ".join(missing) + "\n")

    paths = subprocess.check_output(
        ["git", "-C", str(root), "ls-files", "--cached", "--others", "--exclude-standard", "-z"]
    ).decode().split("\0")
    counts = collections.Counter()
    failures = 0
    with tempfile.TemporaryDirectory(prefix="dotfiles-validate-") as scratch:
        env = dict(os.environ)
        env.pop("BASH_ENV", None)
        env.pop("ENV", None)
        # Keep Neovim cache, state, and logs away from the user's live files.
        env.update(XDG_CACHE_HOME=scratch, XDG_STATE_HOME=scratch, XDG_DATA_HOME=scratch,
                   NVIM_LOG_FILE=str(Path(scratch) / "nvim.log"))
        for name in sorted(set(paths)):
            relative = Path(name)
            path = root / relative
            kind = file_format(relative) if name else None
            if kind is None or not path.is_file():
                continue
            try:
                validate(path, kind, env)
            except (ValueError, OSError, SyntaxError, yaml.YAMLError) as error:
                print(f"FAIL [{kind}] {name}: {error}", file=sys.stderr)
                failures += 1
            else:
                counts[kind] += 1
    print("Validated: " + ", ".join(f"{kind}={count}" for kind, count in sorted(counts.items())))
    if failures:
        print(f"{failures} configuration(s) failed validation.", file=sys.stderr)
        return 1
    print("Supported POSIX configuration formats are valid; Windows checks are deferred.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
