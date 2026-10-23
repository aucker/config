# Validation

Run checks from the repository root. Installer and secret-loader test fixtures
use temporary targets and offline credentials. They do not stow into your real
home or query your real password stores.

## Installation and shell credentials

With Git, Bash, and GNU Stow available:

```bash
./tests/test-dotfiles.sh
```

This covers macOS, Linux, and WSL profile selections, every expected managed
link, paths containing spaces, conflicts, partial states, dry-runs, repeated
operations, adoption guards/backups, and preservation of local files on uninstall.
WSL selection is exercised in a temporary target, not a native Windows or
complete WSL runtime environment.

With Fish and Zsh installed:

```bash
bash tests/test-secret-loading.sh
```

Mock Keychain/`pass` backends check exports, inherited values, empty/failed
lookups, and that values are not printed.

## Configuration formats

Use Python 3.11+, Bash, Git, Fish, Zsh, and Neovim. The Python requirement comes
from [the standard-library TOML parser](https://docs.python.org/3/library/tomllib.html).
Create an isolated environment for parser dependencies:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r tests/requirements.txt
.venv/bin/python -B tests/test_config_validation.py
.venv/bin/python -B tests/validate_configs.py
```

The validator discovers tracked and untracked non-ignored files in active
packages, scripts, tests, and CI, plus `.gitleaks.toml`. It checks Bash, POSIX sh,
Zsh, Fish, Lua, TOML, YAML, JSON, VS Code JSONC, Git config, and its own Python
tools. Shell files and local-file examples are parsed individually.

Lua is compiled with Neovim's `loadfile` without executing the chunk. Neovim
cache/state paths are isolated, and plugin bootstraps do not run. JSONC accepts
comments and trailing commas while preserving strict JSON syntax otherwise.
Regression tests check malformed input and ensure configs are not executed.
Git includes are disabled during syntax checks, so local settings are not loaded.

These are syntax checks, not application-schema or plugin compatibility checks.
Vimscript/tmux runtime behavior, native Windows, and archived files are outside
the validator's scope.

## Secret scanning

Install Gitleaks and use Python 3:

```bash
python3 -B tests/test_secret_scanning.py
python3 scripts/check_secrets.py worktree
python3 scripts/check_secrets.py staged
```

The tests run the actual scanner against generated fake credentials and
temporary Git repositories. They exercise the real hook, partially staged
files, Fish assignments, missing tools, and failures. Worktree mode snapshots
tracked and untracked non-ignored files. Staged mode checks the index, so run
it after staging what you intend to commit.

An explicit audit of all reachable Git refs is available:

```bash
python3 scripts/check_secrets.py history
```

This currently reports the historical WakaTime finding described in
[the secrets guide](secrets.md#secret-scanning). WakaTime work is deferred at the
user's request. The finding remains unresolved and is not suppressed; it is
separate from implementation-test failures. For a selected range, pass
`history --log-opts=BASE..HEAD` with actual revisions.

Exit status is `0` for clean, `1` for findings, and `2` when scanning could not
complete. Reports show location/rule metadata and hide credential values.

## CI and maintenance

The [workflow](../.github/workflows/ci.yml) configures:

- macOS/Linux profile integration, native syntax checks, and offline loader tests.
- ShellCheck for Bash/POSIX sh; Zsh uses its native parser.
- shfmt for the POSIX command and `.sh` files.
- Checksum-verified Gitleaks 8.30.1, scanner tests, worktree scanning, and scans
  of new push/PR commits. Whole-history auditing is explicit.

Local success does not mean a remote workflow has run; check CI after pushing.
When package contents change, update `tests/fixtures/managed-files.tsv` and
expected profile selections in `tests/test-dotfiles.sh`. Keep secret exemptions
exact and centrally reviewed; do not exclude whole configuration/test directories.
