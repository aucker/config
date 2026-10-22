#!/usr/bin/env bash

set -euo pipefail

readonly TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_ROOT="$(cd -- "$TEST_DIR/.." && pwd -P)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-secrets-tests.XXXXXX")"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/empty"
cp "$TEST_DIR/fixtures/secret-backend" "$TEST_ROOT/bin/security"
cp "$TEST_DIR/fixtures/secret-backend" "$TEST_ROOT/bin/pass"
chmod +x "$TEST_ROOT/bin/security" "$TEST_ROOT/bin/pass"

env PATH="$TEST_ROOT/bin:$PATH" fish --no-config "$TEST_DIR/test-secret-loading.fish" "$REPO_ROOT" "$TEST_ROOT"
env PATH="$TEST_ROOT/bin:$PATH" zsh -df "$TEST_DIR/test-secret-loading.zsh" "$REPO_ROOT" "$TEST_ROOT"
printf 'Secret-loading tests passed with offline backends.\n'
