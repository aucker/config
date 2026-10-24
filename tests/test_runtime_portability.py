"""Offline runtime checks for greetings, clipboard selection, and formatting."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
GREETING = ROOT / 'packages/fish/.config/fish/functions/fish_greeting.fish'
CLIPBOARD = ROOT / 'packages/tmux/.local/bin/dotfiles-clipboard'


class RuntimeFixture(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix='dotfiles-runtime-')
        self.addCleanup(self.scratch.cleanup)
        self.tmp = Path(self.scratch.name)
        self.bin = self.tmp / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, XDG_CACHE_HOME=str(self.tmp / 'cache'),
                        XDG_STATE_HOME=str(self.tmp / 'state'), XDG_DATA_HOME=str(self.tmp / 'data'),
                        NVIM_LOG_FILE=str(self.tmp / 'nvim.log'), DOTFILES_TEST_REPO=str(ROOT), TERM='xterm-256color')
        self.env.pop('BASH_ENV', None)
        self.env.pop('ENV', None)

    def tool(self, name, body):
        path = self.bin / name
        path.write_text('#!/bin/sh\n' + body, encoding='utf-8')
        path.chmod(0o755)
        return path

    def fish(self, body, *args):
        result = subprocess.run([shutil.which('fish'), '--no-config', '-c',
                                 'source "$argv[1]"; ' + body, str(GREETING), *map(str, args)],
                                env=self.env, text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, '')
        return result.stdout


class GreetingTests(RuntimeFixture):
    def test_linux_memory_available_fallback_and_missing_data(self):
        meminfo = self.tmp / 'meminfo'
        meminfo.write_text('MemTotal: 16777216 kB\nMemAvailable: 8388608 kB\nMemFree: 1024 kB\n')
        result = self.fish('__dotfiles_greeting_linux_memory "$argv[2]"', meminfo)
        self.assertIn('8.00 / 16.00 GB (50%)', result)
        meminfo.write_text('MemTotal: 16777216 kB\nMemFree: 4194304 kB\nBuffers: 2097152 kB\nCached: 2097152 kB\n')
        self.assertIn('8.00 / 16.00 GB (50%)', self.fish('__dotfiles_greeting_linux_memory "$argv[2]"', meminfo))
        meminfo.write_text('MemTotal: 16777216 kB\nMemAvailable: 33554432 kB\n')
        self.assertIn('0.00 / 16.00 GB (0%)', self.fish('__dotfiles_greeting_linux_memory "$argv[2]"', meminfo))
        self.assertEqual(self.fish('__dotfiles_greeting_linux_memory "$argv[2]"', self.tmp / 'missing'), '(unavailable)')

    def test_linux_battery_and_absent_battery(self):
        batteries = self.tmp / 'power'
        batteries.mkdir()
        self.assertEqual(self.fish('__dotfiles_greeting_linux_battery "$argv[2]"', batteries), '(n/a)')
        (batteries / 'BAT0').mkdir()
        (batteries / 'BAT0/capacity').write_text('73\n')
        self.assertEqual(self.fish('__dotfiles_greeting_linux_battery "$argv[2]"', batteries), '73%')

    def linux_tools(self):
        self.env['PATH'] = str(self.bin) + os.pathsep + os.environ['PATH']
        self.tool('uname', 'if [ "$1" = -s ]; then printf "Linux\\n"; else printf "Linux fixture\\n"; fi\n')
        self.tool('hostname', 'printf "fixture-host\\n"\n')
        self.tool('uptime', 'printf "up 1 hour\\n"\n')
        self.tool('date', 'printf "1700000000\\n"\n')
        self.tool('stat', '[ "$1" = -c ] && [ "$2" = %Y ] || exit 98\nprintf "1700000000\\n"\n')
        self.tool('df', 'printf "Filesystem 1024-blocks Used Available Capacity Mounted on\\nfixture 10485760 5242880 5242880 50%% /\\n"\n')
        self.env['DOTFILES_TEST_IP_LOG'] = str(self.tmp / 'ip.calls')
        self.tool('ip', 'printf "call\\n" >> "$DOTFILES_TEST_IP_LOG"\ncase "$*" in\n*route*) printf "default via 192.0.2.1 dev eth0\\n" ;;\n*addr*) printf "2: eth0 inet 192.0.2.10/24 scope global eth0\\n" ;;\nesac\n')
        self.env['DOTFILES_TEST_FORBIDDEN_LOG'] = str(self.tmp / 'forbidden.calls')
        for name in ('sysctl', 'vm_stat', 'diskutil', 'plutil', 'pmset', 'ipconfig', 'route'):
            self.tool(name, 'printf "forbidden\\n" >> "$DOTFILES_TEST_FORBIDDEN_LOG"\nexit 99\n')

    def test_linux_greeting_avoids_mac_commands_and_reuses_private_cache(self):
        self.linux_tools()
        first = self.fish('fish_greeting')
        self.assertIn('fixture-host', first)
        self.assertIn('eth0 (192.0.2.10)', first)
        self.assertIn('5.0 / 10.0', first)
        self.assertEqual(len((self.tmp / 'ip.calls').read_text().splitlines()), 2)
        second = self.fish('fish_greeting')
        self.assertEqual(first, second)
        self.assertEqual(len((self.tmp / 'ip.calls').read_text().splitlines()), 2)
        self.assertFalse((self.tmp / 'forbidden.calls').exists())
        self.assertTrue((self.tmp / 'cache/fish/dotfiles-greeting-Linux').is_file())
        self.assertEqual((self.tmp / 'cache/fish/dotfiles-greeting-Linux').stat().st_mode & 0o777, 0o600)

    def test_readonly_cache_and_unknown_platform_degrade_gracefully(self):
        self.linux_tools()
        blocked = self.tmp / 'not-a-directory'
        blocked.write_text('fixture')
        self.env['XDG_CACHE_HOME'] = str(blocked)
        self.assertIn('System Overview', self.fish('fish_greeting'))
        self.assertIn('(unavailable)', self.fish('__dotfiles_greeting_render OtherOS'))
        self.assertFalse((self.tmp / 'forbidden.calls').exists())

    def test_linux_network_handles_no_route_and_missing_ip_tool(self):
        self.linux_tools()
        self.tool('ip', 'exit 0\n')
        self.assertEqual(self.fish('__dotfiles_greeting_linux_network'), '(offline)')
        (self.bin / 'ip').unlink()
        self.env['PATH'] = str(self.bin)
        self.assertEqual(self.fish('__dotfiles_greeting_linux_network'), '(unavailable)')

    def test_macos_dispatch_retains_macos_metrics(self):
        self.linux_tools()
        body = '''
function __dotfiles_greeting_macos_memory; printf 'mac-memory'; end
function __dotfiles_greeting_macos_disk; printf 'mac-disk'; end
function __dotfiles_greeting_macos_network; printf 'mac-network'; end
function __dotfiles_greeting_macos_battery; printf 'mac-battery'; end
__dotfiles_greeting_render Darwin
'''
        result = self.fish(body)
        for value in ('mac-memory', 'mac-disk', 'mac-network', 'mac-battery'):
            self.assertIn(value, result)
        self.assertFalse((self.tmp / 'forbidden.calls').exists())


class ClipboardTests(RuntimeFixture):
    def clipboard(self, system, available, *, wayland='', display='', failure=0):
        self.env.update(PATH=str(self.bin), WAYLAND_DISPLAY=wayland, DISPLAY=display,
                        DOTFILES_TEST_BACKEND=str(self.tmp / 'backend'), DOTFILES_TEST_ARGS=str(self.tmp / 'args'))
        self.tool('uname', 'printf "%s\\n" ' + system + '\n')
        for name in available:
            self.tool(name, 'printf "%s\\n" "${0##*/}" > "$DOTFILES_TEST_BACKEND"\nprintf "%s\\n" "$@" > "$DOTFILES_TEST_ARGS"\n/bin/cat\nexit ' + str(failure) + '\n')
        return subprocess.run([str(CLIPBOARD)], env=self.env, input='fixture clipboard\nβeta\n',
                              text=True, capture_output=True, timeout=10)

    def test_mac_wayland_and_x11_selection_preserves_input(self):
        cases = [
            ('Darwin', ['pbcopy', 'wl-copy'], '', '', 'pbcopy', []),
            ('Linux', ['pbcopy', 'wl-copy', 'xclip'], 'wayland-0', ':0', 'wl-copy', []),
            ('Linux', ['pbcopy', 'xclip'], '', ':0', 'xclip', ['-in', '-selection', 'clipboard']),
            ('Linux', ['xsel'], '', ':0', 'xsel', ['--clipboard', '--input']),
        ]
        for system, tools, wayland, display, expected, args in cases:
            with self.subTest(system=system, backend=expected):
                for old in self.bin.iterdir():
                    old.unlink()
                result = self.clipboard(system, tools, wayland=wayland, display=display)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, 'fixture clipboard\nβeta\n')
                self.assertEqual((self.tmp / 'backend').read_text().strip(), expected)
                self.assertEqual((self.tmp / 'args').read_text().split(), args)

    def test_headless_session_is_reported_and_backend_errors_propagate(self):
        result = self.clipboard('Linux', ['xclip'])
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, '')
        self.assertIn('Text remains in the tmux buffer', result.stderr)
        self.assertFalse((self.tmp / 'backend').exists())
        result = self.clipboard('Linux', ['wl-copy'], wayland='wayland-0', failure=7)
        self.assertEqual(result.returncode, 7)

    def test_neovim_native_provider_without_plugins_or_desktop(self):
        self.env['DOTFILES_TEST_LUA'] = str(ROOT / 'tests/test_runtime_clipboard.lua')
        check = "lua local ok, err = pcall(dofile, vim.env.DOTFILES_TEST_LUA); if not ok then io.stderr:write(tostring(err)); vim.cmd('cquit 1') end"
        result = subprocess.run(['nvim', '--headless', '-u', 'NONE', '-i', 'NONE', '-n', '--noplugin',
                                 '-c', check, '-c', 'qa!'], env=self.env, capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_tmux_config_loads_on_a_private_server(self):
        socket = str(self.tmp / 'tmux.sock')
        prefix = ['tmux', '-S', socket]
        config = str(ROOT / 'packages/tmux/.tmux.conf')
        try:
            result = subprocess.run(prefix + ['-f', config, 'new-session', '-d', '-s', 'fixture', '/bin/sleep 30'],
                                    env=self.env, capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            result = subprocess.run(prefix + ['source-file', config], env=self.env, capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            for table, key in [('copy-mode-vi', 'y'), ('root', 'C-y')]:
                result = subprocess.run(prefix + ['list-keys', '-T', table, key],
                                        env=self.env, capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('dotfiles-clipboard', result.stdout)
        finally:
            subprocess.run(prefix + ['kill-server'], env=self.env, capture_output=True, timeout=10)


class VimFormattingTests(RuntimeFixture):
    def test_formatter_uses_path_preserves_buffers_and_reloads_cleanly(self):
        self.env.update(PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        DOTFILES_TEST_FILE=str(self.tmp / "file with spaces'quote.cpp"),
                        DOTFILES_FORMAT_ARGS=str(self.tmp / 'format.args'),
                        DOTFILES_FORMAT_INPUT=str(self.tmp / 'format.input'),
                        DOTFILES_FORMAT_CALLS=str(self.tmp / 'format.calls'),
                        DOTFILES_TEST_ERROR_LOG=str(self.tmp / 'vim.errors'),
                        DOTFILES_TEST_EMPTY_BIN=str(self.tmp / 'empty-bin'))
        (self.tmp / 'empty-bin').mkdir()
        self.tool('clang-format', '''printf '%s\\n' "$@" > "$DOTFILES_FORMAT_ARGS"
printf 'call\\n' >> "$DOTFILES_FORMAT_CALLS"
/bin/cat > "$DOTFILES_FORMAT_INPUT"
case "$DOTFILES_FORMAT_MODE" in
  fail) printf 'not formatted\\n'; exit 1 ;;
  empty) exit 0 ;;
  shrink) printf 'int main() {}\\n' ;;
  *) printf 'int main() {\\n  return 0;\\n}\\n' ;;
esac
''')
        fragments = self.tmp / 'format-fragments'
        fragments.mkdir()
        self.env['DOTFILES_TEST_FORMAT_FRAGMENTS'] = str(fragments)
        for name in ('.vimrc', '.vimrc_mac', '.vimrc_linux'):
            source = (ROOT / 'packages/vim' / name).read_text()
            fragment = re.search(r'^" C/C\+\+ save formatting.*?^augroup END[ \t]*$', source, re.M | re.S)
            self.assertIsNotNone(fragment, name)
            (fragments / (name.lstrip('.') + '.vim')).write_text(fragment.group(0) + '\n')
        result = subprocess.run(['vim', '-Nu', 'NONE', '-i', 'NONE', '-n', '-es', '-S', str(ROOT / 'tests/test_runtime_format.vim')],
                                env=self.env, text=True, capture_output=True, timeout=15)
        errors = self.tmp / 'vim.errors'
        self.assertEqual(result.returncode, 0, result.stderr + (errors.read_text() if errors.exists() else ''))


if __name__ == '__main__':
    unittest.main()
