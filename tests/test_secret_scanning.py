"""Exercise the real scanner and hook using generated, unusable credentials."""

import os
from pathlib import Path
import random
import shutil
import string
import subprocess
import sys
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
SCANNER = REPO_ROOT / "scripts/check_secrets.py"
HOOKS = REPO_ROOT / "packages/git/.config/git/hooks"


def fake_value(length, alphabet=string.ascii_letters + string.digits):
    generator = random.Random(length)
    return "".join(generator.choice(alphabet) for _ in range(length))


class SecretScanningTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix="dotfiles-secret-test-")
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name) / "repo with spaces"
        self.root.mkdir()
        self.git("init", "-q")
        self.git("config", "user.name", "Scanner Test")
        self.git("config", "user.email", "scanner@example.invalid")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "core.hooksPath", str(self.root / "no-hooks"))
        shutil.copyfile(REPO_ROOT / ".gitleaks.toml", self.root / ".gitleaks.toml")
        (self.root / "scripts").mkdir()
        shutil.copyfile(SCANNER, self.root / "scripts/check_secrets.py")
        self.git("add", ".gitleaks.toml", "scripts/check_secrets.py")
        self.git("commit", "-qm", "offline scanner fixture")

    def git(self, *args, check=True):
        return subprocess.run(["git", "-C", str(self.root), *args],
                              capture_output=True, text=True, check=check)

    def write(self, name, contents, *, stage=True):
        target = self.root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(contents, encoding="utf-8")
        if stage:
            self.git("add", "--", name)

    def scan(self, mode="staged", *, env=None, log_opts=None):
        command = [sys.executable, "-B", str(SCANNER), mode, "--repo", str(self.root)]
        if log_opts is not None:
            command.append("--log-opts=" + log_opts)
        return subprocess.run(command,
                              capture_output=True, text=True, env=env)

    def assert_blocked(self, result, secret):
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("potential credential", result.stderr)
        self.assertNotIn(secret, result.stdout + result.stderr)

    def test_provider_keys_passwords_private_keys_and_fish_assignments(self):
        google = "AIza" + fake_value(35)
        github = "ghp_" + fake_value(36)
        aws = "AKIA" + fake_value(16, string.ascii_uppercase + string.digits)
        password = fake_value(26)
        generic_token = fake_value(48)
        key_header = "-----BEGIN " + "OPENSSH PRIVATE KEY-----"
        cases = [
            (f'set -gx GEMINI_API_KEY "{google}"\n', google),
            (f'set -gx CUSTOM_AUTH_TOKEN "{generic_token}"\n', generic_token),
            (f'set -gx DATABASE_PASSWORD "{password}"\n', password),
            (f'GITHUB_TOKEN="{github}"\n', github),
            (f'AWS_ACCESS_KEY_ID="{aws}"\nAWS_SECRET_ACCESS_KEY="{fake_value(40)}"\n', aws),
            ("password = " + repr(password) + "\n", password),
            (key_header + "\n" + fake_value(64) + "\n", key_header),
        ]
        for contents, secret in cases:
            with self.subTest(kind=contents.split()[0].split("=")[0]):
                self.write("candidate config.txt", contents)
                self.assert_blocked(self.scan(), secret)

    def test_names_store_references_and_exact_placeholders_are_allowed(self):
        self.write("example.fish", '\n'.join([
            'dotfiles_load_secret GEMINI_API_KEY keychain gemini-api-key',
            'dotfiles_load_secret ANTHROPIC_AUTH_TOKEN pass api/anthropic',
            'export GEMINI_API_KEY="$GEMINI_API_KEY"',
            'password = "YOUR_PASSWORD"',
            'token = "fixture value with spaces"',
        ]))
        result = self.scan()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_staged_scan_uses_index_not_unstaged_worktree(self):
        secret = "AIza" + fake_value(35)
        self.write("partial.fish", f'set -gx GEMINI_API_KEY "{secret}"\n')
        self.write("partial.fish", "# safe working version\n", stage=False)
        self.assert_blocked(self.scan(), secret)
        self.assertEqual(self.scan("worktree").returncode, 0)
        self.git("add", "partial.fish")
        self.write("partial.fish", f'set -gx GEMINI_API_KEY "{secret}"\n', stage=False)
        self.assertEqual(self.scan().returncode, 0)
        self.assert_blocked(self.scan("worktree"), secret)

    def test_ignored_files_and_external_symlink_targets_are_not_read(self):
        secret = "AIza" + fake_value(35)
        self.write(".gitignore", "private.local\n")
        self.write("private.local", f'GEMINI_API_KEY="{secret}"\n', stage=False)
        external = Path(self.scratch.name) / "private-outside-repo"
        external.write_text(f'GEMINI_API_KEY="{secret}"\n', encoding="utf-8")
        (self.root / "external-link").symlink_to(external)
        result = self.scan("worktree")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_inline_allow_comment_does_not_hide_new_credentials(self):
        secret = "AIza" + fake_value(35)
        self.write("candidate.txt", f'GEMINI_API_KEY="{secret}" # gitleaks:allow\n')
        self.assert_blocked(self.scan(), secret)

    def test_history_finds_a_credential_removed_in_a_later_commit(self):
        secret = "AIza" + fake_value(35)
        before = self.git("rev-parse", "HEAD").stdout.strip()
        self.write("past.txt", f'GEMINI_API_KEY="{secret}"\n')
        self.git("commit", "-qm", "generated fake credential fixture")
        (self.root / "past.txt").unlink()
        self.git("add", "-u")
        self.assertEqual(self.scan().returncode, 0)
        self.git("commit", "-qm", "remove fixture")
        self.assert_blocked(self.scan("history"), secret)
        self.assert_blocked(self.scan("history", log_opts=before + "..HEAD"), secret)
        # A deletion-only range is clean; the explicit whole-history audit is not.
        self.assertEqual(self.scan("history", log_opts="HEAD^..HEAD").returncode, 0)

    def test_missing_scanner_and_invalid_config_fail_closed(self):
        env = dict(os.environ, PATH=str(self.root / "empty-tools"))
        result = self.scan(env=env)
        self.assertEqual(result.returncode, 2)
        self.assertIn("Gitleaks is required", result.stderr)
        self.write(".gitleaks.toml", "[invalid syntax\n")
        result = self.scan()
        self.assertEqual(result.returncode, 2)
        self.assertIn("failed", result.stderr.lower())

    def test_live_hook_rejects_secret_and_accepts_corrected_config(self):
        secret = "AIza" + fake_value(35)
        self.write("candidate.txt", f'GEMINI_API_KEY="{secret}"\n')
        before = self.git("rev-parse", "HEAD").stdout
        result = self.git("-c", f"core.hooksPath={HOOKS}", "commit", "-qm", "must be blocked", check=False)
        self.assert_blocked(result, secret)
        self.assertEqual(self.git("rev-parse", "HEAD").stdout, before)
        self.write("candidate.txt", "# reference-only configuration\n")
        result = self.git("-c", f"core.hooksPath={HOOKS}", "commit", "-qm", "safe config", check=False)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
