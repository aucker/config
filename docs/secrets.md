# Secret loading

Keep credential values in macOS Keychain or `pass`. The shell configuration
contains variable names and store references only; no credential belongs in
tracked files, Fish universal variables, or Git configuration.

Both shells provide this helper:

```text
dotfiles_load_secret VARIABLE keychain SERVICE
dotfiles_load_secret VARIABLE pass ENTRY
```

The helper exports a single-line credential into the current shell without
printing it. An existing nonempty environment value takes precedence. A failed
or empty lookup leaves the environment unchanged and returns failure. `pass`
uses the first line of an entry, allowing notes on subsequent lines.

## Current Mac

`ANTHROPIC_AUTH_TOKEN` loads automatically from the Keychain generic-password
item with service `codex-deepseek-anthropic-token` and account matching `$USER`.
The previous plaintext `.git/config` fallback has been removed after verifying
that Keychain holds the same value. The token itself was not rotated.

To provision another Mac, use Keychain Access to create a password item with
that service name and your macOS username as the account. Enter the credential
through the application's password field. Keychain may ask you to allow access
from `/usr/bin/security`, which is the command the shell helper uses.

## Other credentials or Linux/WSL

For `pass`, create an encrypted entry interactively after setting up its GPG
store:

```bash
pass insert api/anthropic
```

Copy the example for the shell you use, then enable the relevant lookup lines:

```bash
cp ~/.config/fish/secrets.local.fish.example ~/.config/fish/secrets.local.fish
chmod 600 ~/.config/fish/secrets.local.fish

cp ~/.config/zsh/secrets.local.zsh.example ~/.config/zsh/secrets.local.zsh
chmod 600 ~/.config/zsh/secrets.local.zsh
```

These local files are sourced before the default Keychain lookup so another
store can supply the token first. They should contain only mappings such as
`dotfiles_load_secret ANTHROPIC_AUTH_TOKEN pass api/anthropic`, never raw values.
Keep them in the home configuration directory outside the Stow packages.

Open a new terminal to load credentials. Already-exported values are preserved;
to reload a changed credential in an existing shell, unset its variable and
call the helper again. Missing tools, missing items, and locked stores do not
prevent shell startup. Loaded values are available to child processes in that
shell; use an application's own credential integration when per-command access
is preferable.

## Secret scanning

Install Gitleaks (`brew install gitleaks` on macOS) before committing to this
repository. CI pins version 8.30.1 and verifies the published release checksum;
Linux users can use the matching upstream binary. The scanner runs locally and
does not contact credential providers or upload files to a scanning service.

`python3 scripts/check_secrets.py staged` examines Git's staged changes, even
when the working version of a file differs. The managed shared pre-commit hook
opts this repository in when `.gitleaks.toml` and `scripts/check_secrets.py` are
present. It runs after C formatting so it sees the final staged content. Other
repositories keep their existing formatting behavior.

`worktree` scans tracked and untracked non-ignored files in a temporary snapshot.
It excludes Git metadata and ignored local state, and reads symlink text without
following external targets. `history` scans all reachable refs, including a
credential introduced and then removed in another commit. CI scans current
files plus the push/PR commit range using `history --log-opts=BASE..HEAD`.
No files or credentials are sent outside the machine by these commands.

Findings contain only location and rule information. Scanner output is captured,
and its redacted report is deleted with the temporary scan directory. A missing
scanner, invalid configuration, or other scan failure returns an error and
blocks commits in opted-in repositories.

If a finding is real, remove the value, store it in Keychain or `pass`, and
restage the file. Revoke/rotate a credential that has already been exposed.
Removing it from a newer commit does not remove it from older history.

If a finding is a harmless example, prefer a descriptive placeholder. The only
repository-specific exemptions are exact placeholder values in `.gitleaks.toml`.
The config extends upstream rules with checks for quoted passwords, private-key
headers, and opaque Fish `set` credentials that have no provider-specific prefix.
Review every new exemption; do not exclude whole files or credential-variable
names. Inline `gitleaks:allow` comments and `.gitleaksignore` are intentionally
disabled by the wrapper. No history baseline suppresses previous findings.
Pattern scanning is a preventive check, not proof that every possible secret
has been found.

The initial full-history audit found a WakaTime API-key setting in old
`Code/settings.json` and `vscode/settings.json` commits (`326cca0` and
`38f7075`). Its value is absent from current files. Verify that the credential
has been revoked/rotated before treating this exposure as resolved. Full-history
audits deliberately continue reporting it; no allowlist or baseline suppresses
it. The normal CI gate checks current files and newly introduced commits.
