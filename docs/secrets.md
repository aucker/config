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
