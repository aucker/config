#!/usr/bin/env bash

set -uo pipefail

readonly TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_ROOT="$(cd -- "$TEST_DIR/.." && pwd -P)"
readonly DOTFILES="$REPO_ROOT/bin/dotfiles"

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-tests.XXXXXX")"
TARGET="$TEST_ROOT/home"
mkdir -p "$TARGET"

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" != *"$needle"* ]]; then
        fail "expected output to contain: $needle"
    fi
}

assert_link() {
    local path="$1"
    [[ -L "$path" ]] || fail "expected symlink: $path"
}

printf 'Test: command works outside the repository\n'
output="$(cd "$TEST_ROOT" && "$DOTFILES" --target "$TARGET" status core)" || fail 'initial status command failed'
assert_contains "$output" 'not installed'
output="$("$DOTFILES" --target "$TARGET" status missing)" || fail 'absent status command failed'
assert_contains "$output" 'absent'

printf 'Test: GNU Stow dry-run does not modify the target\n'
output="$("$DOTFILES" --dry-run --target "$TARGET" install core)" || fail 'dry-run failed'
assert_contains "$output" '[dry-run] install core'
[[ ! -e "$TARGET/.editorconfig" ]] || fail 'dry-run created a target file'

printf 'Test: install and status\n'
output="$("$DOTFILES" --target "$TARGET" install core)" || fail 'install failed'
assert_contains "$output" '1 succeeded, 0 failed'
assert_link "$TARGET/.editorconfig"
assert_link "$TARGET/.clang-format"
output="$("$DOTFILES" --target "$TARGET" status core)" || fail 'installed status failed'
assert_contains "$output" 'installed'
assert_contains "$output" '2/2 linked'

printf 'Test: partial and conflicting states\n'
rm -- "$TARGET/.editorconfig"
output="$("$DOTFILES" --target "$TARGET" status core)" || fail 'partial status failed'
assert_contains "$output" 'partial'
printf 'local conflict\n' >"$TARGET/.editorconfig"
output="$("$DOTFILES" --target "$TARGET" status core)" || fail 'conflict status failed'
assert_contains "$output" 'conflict'
if "$DOTFILES" --target "$TARGET" install core >/dev/null 2>&1; then
    fail 'conflicting install unexpectedly succeeded'
fi

printf 'Test: uninstall and idempotent install\n'
rm -- "$TARGET/.editorconfig"
"$DOTFILES" --target "$TARGET" install core >/dev/null || fail 'repair install failed'
"$DOTFILES" --target "$TARGET" install core >/dev/null || fail 'idempotent install failed'
"$DOTFILES" --target "$TARGET" uninstall core >/dev/null || fail 'uninstall failed'
[[ ! -e "$TARGET/.editorconfig" ]] || fail 'uninstall left .editorconfig'
[[ ! -e "$TARGET/.clang-format" ]] || fail 'uninstall left .clang-format'

printf 'Test: explicit profiles include packages omitted by old discovery\n'
output="$("$DOTFILES" list)" || fail 'list failed'
assert_contains "$output" '@macos'
assert_contains "$output" '@windows'
assert_contains "$output" 'vscode-macos'
assert_contains "$output" 'powershell'
assert_contains "$output" 'core'

printf 'Test: platform profiles keep platform-only paths isolated\n'
LINUX_TARGET="$TEST_ROOT/linux-home"
mkdir -p "$LINUX_TARGET"
"$DOTFILES" --target "$LINUX_TARGET" install @linux >/dev/null || fail 'Linux profile install failed'
[[ ! -e "$LINUX_TARGET/Library" ]] || fail 'Linux profile created a macOS Library path'
"$DOTFILES" --target "$LINUX_TARGET" uninstall @linux >/dev/null || fail 'Linux profile uninstall failed'
if output="$("$DOTFILES" --target "$TARGET" status @windows 2>&1)"; then
    fail 'POSIX command unexpectedly accepted the Windows profile'
fi
assert_contains "$output" 'managed by stow-windows.ps1'

printf 'Test: shared shell files delegate host-specific settings\n'
grep -q 'local.fish' "$REPO_ROOT/packages/fish/.config/fish/config.fish" || fail 'Fish local override is not loaded'
grep -q 'local.zsh' "$REPO_ROOT/packages/zsh/.config/zsh/.zshrc" || fail 'Zsh local override is not loaded'
if grep -Eq '/mnt/c/Users/|clang\+llvm-[0-9]|cuda-[0-9]|cmake-[0-9]|postgresql@[0-9]|127\.0\.0\.1 [0-9]+' \
    "$REPO_ROOT/packages/fish/.config/fish/config.fish" \
    "$REPO_ROOT/packages/zsh/.config/zsh/.zshrc"; then
    fail 'shared shell files still contain host-specific paths'
fi

printf 'Test: Git local overrides resolve beside the installed config symlink\n'
GIT_TARGET="$TEST_ROOT/git-home"
mkdir -p "$GIT_TARGET"
"$DOTFILES" --target "$GIT_TARGET" install git >/dev/null || fail 'Git package install failed'
assert_link "$GIT_TARGET/.config/git/config"
assert_link "$GIT_TARGET/.config/git/config.local.example"
output="$(git config --file "$GIT_TARGET/.config/git/config" --includes --get alias.st)" || fail 'Git config failed without local overrides'
[[ "$output" == status ]] || fail 'shared Git alias was lost'
if git config --file "$GIT_TARGET/.config/git/config" --includes --get user.email >/dev/null 2>&1; then
    fail 'Git package supplies a host identity without local configuration'
fi
git config --file "$GIT_TARGET/.config/git/config.local" user.email 'host@example.invalid' || fail 'could not create local Git override'
git config --file "$GIT_TARGET/.config/git/config.local" pull.ff false || fail 'could not create shared-setting override'
output="$(git config --file "$GIT_TARGET/.config/git/config" --includes --get user.email)" || fail 'local Git identity was not loaded'
[[ "$output" == host@example.invalid ]] || fail 'local Git identity was not preserved'
output="$(git config --file "$GIT_TARGET/.config/git/config" --includes --get pull.ff)" || fail 'local Git preference was not loaded'
[[ "$output" == false ]] || fail 'local Git setting did not override the shared default'
"$DOTFILES" --target "$GIT_TARGET" uninstall git >/dev/null || fail 'Git package uninstall failed'
[[ -f "$GIT_TARGET/.config/git/config.local" && ! -L "$GIT_TARGET/.config/git/config.local" ]] || fail 'uninstall removed the host Git configuration'

printf 'Test: adopt guards, previews, backs up, applies, and shows a diff\n'
ADOPT_REPO="$TEST_ROOT/adopt-repo"
ADOPT_TARGET="$TEST_ROOT/adopt-home"
ADOPT_BACKUPS="$TEST_ROOT/adopt-backups"
mkdir -p "$ADOPT_REPO/bin" "$ADOPT_REPO/packages/sample" "$ADOPT_TARGET"
cp "$DOTFILES" "$ADOPT_REPO/bin/dotfiles"
printf 'package version\n' >"$ADOPT_REPO/packages/sample/.example"
git -C "$ADOPT_REPO" init -q
git -C "$ADOPT_REPO" config user.name 'Dotfiles Test'
git -C "$ADOPT_REPO" config user.email 'dotfiles-test@example.invalid'
git -C "$ADOPT_REPO" config commit.gpgsign false
git -C "$ADOPT_REPO" add bin/dotfiles packages/sample/.example
git -C "$ADOPT_REPO" commit -qm 'test fixture'
printf 'target version\n' >"$ADOPT_TARGET/.example"

printf 'dirty\n' >"$ADOPT_REPO/untracked"
if DOTFILES_BACKUP_DIR="$ADOPT_BACKUPS" "$ADOPT_REPO/bin/dotfiles" \
    --target "$ADOPT_TARGET" --yes adopt sample >/dev/null 2>&1; then
    fail 'adopt unexpectedly accepted a dirty repository'
fi
rm -- "$ADOPT_REPO/untracked"

if output="$(DOTFILES_BACKUP_DIR="$ADOPT_BACKUPS" "$ADOPT_REPO/bin/dotfiles" \
    --target "$ADOPT_TARGET" adopt sample 2>&1)"; then
    fail 'adopt without --yes unexpectedly succeeded'
fi
assert_contains "$output" 'Adopt preview for sample'
assert_contains "$output" 'Re-run with --yes'
[[ ! -L "$ADOPT_TARGET/.example" ]] || fail 'preview changed the target'

output="$(DOTFILES_BACKUP_DIR="$ADOPT_BACKUPS" "$ADOPT_REPO/bin/dotfiles" \
    --target "$ADOPT_TARGET" --yes adopt sample)" || fail 'confirmed adopt failed'
assert_contains "$output" 'Backup created:'
assert_contains "$output" 'Repository changes after adoption:'
assert_link "$ADOPT_TARGET/.example"
grep -q 'target version' "$ADOPT_REPO/packages/sample/.example" || fail 'target content was not adopted'
backup_dir="$(find "$ADOPT_BACKUPS" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[[ -n "$backup_dir" ]] || fail 'adopt backup directory was not created'
grep -q 'package version' "$backup_dir/package/.example" || fail 'package backup is incorrect'
grep -q 'target version' "$backup_dir/target/.example" || fail 'target backup is incorrect'

printf 'All dotfiles integration tests passed.\n'
