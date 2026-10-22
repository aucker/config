"""Regressions for JSONC handling and selecting the appropriate native parser."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from validate_configs import file_format, parse_json


class JsoncTests(unittest.TestCase):
    def test_comments_and_trailing_commas(self):
        source = '// note\n{"items": [1, /* comment */ 2,], "enabled": true,}'
        self.assertEqual(parse_json(source, comments=True), {"items": [1, 2], "enabled": True})

    def test_string_contents_are_preserved(self):
        value = {"url": "https://example.com/a//b", "text": '/* text */ ,} ,] " \\'}
        source = json.dumps(value)[:-1] + ", // trailing comment\n}"
        self.assertEqual(parse_json(source, comments=True), value)

    def test_invalid_json_remains_invalid(self):
        for source in ('[,]', '[1,,]', '{"a":,}', '{,"a":1}',
                       '{"a":1 "b":2}', '{unquoted: 1}', "{'a': 1}",
                       '/* unfinished', '{"a": NaN}', '{"a": Infinity}',
                       '{"a":"unfinished}', '{"a":1} extra'):
            with self.subTest(source=source), self.assertRaises(ValueError):
                parse_json(source, comments=True)

    def test_comment_errors_keep_line_numbers(self):
        with self.assertRaises(json.JSONDecodeError) as error:
            parse_json('{\n/* note\n another line */\n"a":\n}', comments=True)
        self.assertEqual(error.exception.lineno, 5)

    def test_strict_json_disallows_comments_and_trailing_commas(self):
        for source in ('{"a":1,}', '// note\n{"a":1}'):
            with self.subTest(source=source), self.assertRaises(ValueError):
                parse_json(source)


class FileFormatTests(unittest.TestCase):
    def test_shell_files_and_examples_get_native_parsers(self):
        cases = {
            "bin/dotfiles": "bash",
            "packages/git/.config/git/hooks/pre-commit": "sh",
            "packages/zsh/.zshenv": "zsh",
            "packages/zsh/.config/zsh/.zshrc": "zsh",
            "packages/zsh/.config/zsh/local.zsh.example": "zsh",
            "packages/fish/.config/fish/secrets.local.fish.example": "fish",
            "tests/test-secret-loading.zsh": "zsh",
        }
        for path, expected in cases.items():
            with self.subTest(path=path):
                self.assertEqual(file_format(Path(path)), expected)

    def test_vscode_jsonc_is_distinct_from_strict_json(self):
        self.assertEqual(file_format(Path("packages/vscode-macos/Library/Application Support/Code/User/settings.json")), "jsonc")
        self.assertEqual(file_format(Path("packages/nvim/.config/nvim/lazy-lock.json")), "json")

    def test_deferred_and_archived_files_are_not_executed(self):
        for path in ("windows/Microsoft.PowerShell_profile.ps1", "stow-windows.ps1",
                     "windows/starship.toml", "docs/archive/zshrc_linux.legacy.zsh"):
            with self.subTest(path=path):
                self.assertIsNone(file_format(Path(path)))


class ValidatorIntegrationTests(unittest.TestCase):
    def test_checks_later_files_and_does_not_execute_configs(self):
        with tempfile.TemporaryDirectory(prefix="dotfiles-validator-test-") as scratch:
            root = Path(scratch)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            files = {
                "packages/zsh/.config/zsh/00-valid.zsh": "print 'CONFIG_WAS_EXECUTED'\n",
                "packages/zsh/.config/zsh/01-broken.zsh": "if true; then\n",
                "packages/fish/.config/fish/config.fish": "exit 99\n",
                "packages/nvim/.config/nvim/init.lua": "error('CONFIG_WAS_EXECUTED')\n",
            }
            for name, contents in files.items():
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(contents, encoding="utf-8")
            validator = Path(__file__).with_name("validate_configs.py")
            result = subprocess.run([sys.executable, "-B", str(validator), "--root", str(root)],
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertIn("01-broken.zsh", result.stderr)
            self.assertIn("1 configuration(s) failed", result.stderr)
            self.assertIn("fish=1", result.stdout)
            self.assertIn("lua=1", result.stdout)
            self.assertIn("zsh=1", result.stdout)
            self.assertNotIn("CONFIG_WAS_EXECUTED", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
