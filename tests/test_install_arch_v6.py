"""Isolated installer regressions: no real installs, services, or firewall changes.

Run with: python3 -m unittest discover -s tests -v
"""

import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "install-archV6.sh"
SOURCE = SCRIPT.read_text()
HELPERS, MAIN = SOURCE.split("# ---------- helpers ----------", 1)[1].split(
    "# ---------- main ----------", 1
)


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="arch-v6-tests-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "user home"
        self.home.mkdir()
        self.zshrc = self.home / ".zshrc"
        self.repo = self.root / "repo"
        self.repo.mkdir()

    def bash(self, body, *, stdin="", helpers=HELPERS, args=()):
        return subprocess.run(
            ["bash", "-c", "set -Eeuo pipefail\n" + helpers + "\n" + body, "test-installer", *args],
            input=stdin,
            text=True,
            capture_output=True,
            timeout=10,
            cwd=self.root,
            env={
                **os.environ,
                "HOME": str(self.home),
                "USER_HOME": str(self.home),
                "ORIGINAL_USER": "fixture-user",
                "SCRIPT_DIR": str(self.repo),
                "AUDIT_ROOT": str(self.root),
                "XDG_CONFIG_HOME": str(self.home / ".config"),
                "XDG_STATE_HOME": str(self.home / ".local/state"),
            },
        )

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which("zsh"), "zsh is required for startup validation")
    def test_zsh_preserves_user_code_and_loads_requested_settings_once(self):
        omz = self.home / ".oh-my-zsh"
        omz.mkdir()
        (omz / "oh-my-zsh.sh").write_text(
            'print -r -- "$ZSH_THEME" >> "$AUDIT_ROOT/themes"\n'
            'printf "%s\\n" "${plugins[@]}" > "$AUDIT_ROOT/plugins"\n'
        )
        cases = {
            "plain": "export KEEP_ME=original\n",
            "semicolon": (
                'export ZSH="$HOME/.oh-my-zsh"\n'
                "plugins=(git); export SAME_LINE=preserved\n"
                'source "$ZSH/oh-my-zsh.sh"\n'
                "export KEEP_ME=original\n"
            ),
            "multiline": (
                'export ZSH="$HOME/.oh-my-zsh"\n'
                "plugins=(\n git\n # comment with a closing )\n 'custom)plugin'\n)\n"
                'source "$ZSH/oh-my-zsh.sh"\n'
                "export KEEP_ME=original\n"
            ),
            "dot_source": (
                'export ZSH="$HOME/.oh-my-zsh"\n'
                'ZSH_THEME="old-theme"\n'
                'plugins=(git)\n. "$ZSH/oh-my-zsh.sh"\n'
                "export KEEP_ME=original\n"
            ),
        }
        for name, original in cases.items():
            with self.subTest(name=name):
                self.zshrc.write_text(original)
                backups_before = set(self.home.glob(".zshrc.pre-archconfig-v6.*"))
                self.assert_success(self.bash("configure_zshrc"))
                configured = self.zshrc.read_text()
                # Every original line remains, in its original order.
                lines = iter(configured.splitlines())
                for line in original.splitlines():
                    self.assertTrue(any(candidate == line for candidate in lines), line)
                backups = set(self.home.glob(".zshrc.pre-archconfig-v6.*")) - backups_before
                self.assertEqual(len(backups), 1)
                self.assertEqual(backups.pop().read_text(), original)
                self.assert_success(self.bash("configure_zshrc"))
                self.assertEqual(self.zshrc.read_text(), configured)
                self.assertEqual(
                    len(set(self.home.glob(".zshrc.pre-archconfig-v6.*")) - backups_before),
                    1,
                )
                (self.root / "themes").unlink(missing_ok=True)
                self.assert_success(
                    self.bash(
                        "zsh -f -c '. \"$HOME/.zshrc\"; "
                        "[[ \"$KEEP_ME\" == original ]]'"
                    )
                )
                self.assertEqual(
                    (self.root / "themes").read_text().splitlines(),
                    ["powerlevel10k/powerlevel10k"],
                )
                self.assertEqual(
                    (self.root / "plugins").read_text().splitlines(),
                    ["git", "zsh-autosuggestions", "zsh-syntax-highlighting", "web-search"],
                )

    @unittest.skipUnless(shutil.which("zsh"), "zsh is required for syntax validation")
    def test_zsh_preserves_symlink_and_permissions(self):
        target = self.home / "custom-zshrc"
        original = "export KEEP_ME=original\n"
        target.write_text(original)
        target.chmod(0o640)
        self.zshrc.symlink_to(target)
        self.assert_success(self.bash("configure_zshrc"))
        self.assertTrue(self.zshrc.is_symlink())
        self.assertEqual(target.stat().st_mode & 0o777, 0o640)
        self.assertEqual(
            next(self.home.glob("custom-zshrc.pre-archconfig-v6.*")).read_text(),
            original,
        )

    @unittest.skipUnless(shutil.which("zsh"), "zsh is required for syntax validation")
    def test_invalid_zsh_or_unclosed_managed_block_does_not_replace_original(self):
        for original in (
            "plugins=(git\n",
            "# >>> ArchConfig V6 shell settings >>>\nexport KEEP_ME=original\n",
        ):
            with self.subTest(original=original):
                self.zshrc.write_text(original)
                self.assertNotEqual(self.bash("configure_zshrc").returncode, 0)
                self.assertEqual(self.zshrc.read_text(), original)
                self.assertEqual(list(self.home.glob(".zshrc.pre-archconfig-v6.*")), [])
                self.assertEqual(list(self.home.glob(".zshrc.v6.*")), [])

    def test_nvm_creates_explicit_directory_with_xdg_and_reuses_existing_install(self):
        # The pinned upstream installer requires an explicit non-default NVM_DIR
        # to exist. This fixture enforces that boundary without any downloads.
        (self.root / "nvm-installer.sh").write_text(
            "set -e\n"
            '[[ -d "$NVM_DIR" ]] || exit 41\n'
            'cat > "$NVM_DIR/nvm.sh" <<\'EOF\'\n'
            'nvm() { printf "nvm %s\\n" "$*" >> "$AUDIT_ROOT/node-calls"; }\n'
            "EOF\n"
        )
        self.zshrc.touch()
        body = r'''
curl() {
    printf 'download\n' >> "$AUDIT_ROOT/downloads"
    cp -- "$AUDIT_ROOT/nvm-installer.sh" "${@: -1}"
}
npm() { printf 'npm %s\n' "$*" >> "$AUDIT_ROOT/node-calls"; }
install_nvm_node_and_global_tools
'''
        self.assert_success(self.bash(body))
        self.assertTrue((self.home / ".nvm/nvm.sh").is_file())
        configured = self.zshrc.read_text()
        self.assert_success(self.bash(body))
        self.assertEqual(self.zshrc.read_text(), configured)
        self.assertEqual((self.root / "downloads").read_text().splitlines(), ["download"])
        self.assertEqual(
            (self.root / "node-calls").read_text().splitlines(),
            [
                "nvm install --lts",
                "nvm alias default lts/*",
                "npm install --global nodemon eslint typescript http-server",
            ]
            * 2,
        )

    @unittest.skipUnless(shutil.which("pacman-conf"), "pacman-conf is required")
    def test_multilib_accepts_large_server_list_and_uncomments_only_its_section(self):
        config = self.root / "pacman.conf"
        mirrorlist = self.root / "mirrorlist"
        mirrorlist.write_text(
            "".join(
                f"Server = https://mirror{i}.example.org/$repo/os/$arch\n"
                for i in range(3000)
            )
        )
        # Only redirect fixture paths; run the real helper, sed, and pacman-conf.
        helpers = HELPERS.replace("/etc/pacman.conf", str(config)).replace(
            "/etc/pacman.d/mirrorlist", str(mirrorlist)
        )
        custom = "#[custom]\n#Include = /not-a-real-custom-mirrorlist\n"
        original = (
            "[options]\nArchitecture = auto\n"
            "[extra]\nServer = https://extra.example.org/$repo/os/$arch\n"
            f"#[multilib]\n#Include = {mirrorlist}\n" + custom
        )
        config.write_text(original)
        body = r'''
pacman-conf() { command pacman-conf --config "$AUDIT_ROOT/pacman.conf" "$@"; }
sudo() {
    [[ "$1" == sed && "${@: -1}" == "$AUDIT_ROOT/pacman.conf" ]] || exit 42
    printf 'edit\n' >> "$AUDIT_ROOT/config-edits"
    "$@"
}
enable_multilib
'''
        self.assert_success(self.bash(body, helpers=helpers))
        self.assertIn(f"[multilib]\nInclude = {mirrorlist}", config.read_text())
        self.assertTrue(config.read_text().endswith(custom))
        self.assert_success(self.bash(body, helpers=helpers))
        self.assertEqual((self.root / "config-edits").read_text().splitlines(), ["edit"])

    def test_multilib_does_not_accept_output_from_a_failed_pacman_conf(self):
        config = self.root / "pacman.conf"
        config.write_text("[multilib]\n")
        helpers = HELPERS.replace("/etc/pacman.conf", str(config))
        result = self.bash(
            "pacman-conf() { printf 'https://fixture\\n'; return 7; }\n"
            "sudo() { :; }\nenable_multilib\nprintf 'WRONG_SUCCESS\\n'",
            helpers=helpers,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("WRONG_SUCCESS", result.stdout)

    def test_prompt_answers_retry_and_eof(self):
        body = (
            "if prompt_yes_no test; then echo YES; else echo NO; fi\n"
            "echo CONTINUED"
        )
        for answer, expected in (("y\n", "YES"), ("n\n", "NO"), ("bad\nY\n", "YES")):
            with self.subTest(answer=answer):
                result = self.bash(body, stdin=answer)
                self.assert_success(result)
                self.assertIn(expected, result.stdout)
                self.assertIn("CONTINUED", result.stdout)
        for answer in ("", "bad\n"):
            with self.subTest(eof=answer):
                result = self.bash(body, stdin=answer)
                self.assertEqual(result.returncode, 1)
                self.assertIn("Input closed", result.stderr)
                self.assertNotIn("CONTINUED", result.stdout)

    def main_stubs(self):
        for profile in ("configs", "configs-laptop"):
            for item in ("hypr", "kitty"):
                (self.repo / profile / item).mkdir(parents=True, exist_ok=True)
        return r'''
audit_log() { printf '%s\n' "$*" >> "$AUDIT_ROOT/commands"; }
sudo() { audit_log sudo "$@"; }
pacman-conf() { printf 'https://fixture.example.org\n'; }
pacman() {
    case "$1" in
        -Si) return 0 ;;
        -Q) [[ "$2" == linux ]] ;;
        *) echo "Unexpected pacman call" >&2; exit 43 ;;
    esac
}
yay() { audit_log yay "$@"; }
flatpak() { audit_log flatpak "$@"; }
install_appimages() { audit_log appimages; }
install_post_install_shell_tools() { audit_log shell-setup; }
configure_grub() { audit_log grub-setup; }
curl() { echo 'Unexpected network request' >&2; exit 44; }
git() { echo 'Unexpected Git operation' >&2; exit 45; }
'''

    def checkpoint(self):
        return next(self.home.glob(".local/state/archconfig/install-arch-v6/*/next-stage"))

    def calls(self):
        return (self.root / "commands").read_text().splitlines()

    def test_main_installs_desktop_enables_bluetooth_and_allows_localsend(self):
        stubs = self.main_stubs()
        cases = (
            ("n\nn\nn\nn\ny\n", "configs", False),
            ("y\ny\ny\ny\nn\n", "configs-laptop", True),
        )
        for answers, profile, full in cases:
            with self.subTest(profile=profile):
                (self.root / "commands").unlink(missing_ok=True)
                result = self.bash(stubs + MAIN, stdin=answers)
                self.assert_success(result)
                self.assertIn("Done.", result.stdout)
                calls = (self.root / "commands").read_text().splitlines()
                packages = next(c for c in calls if c.startswith("sudo pacman -S --needed "))
                for package in ("hyprland", "kitty", "bluez"):
                    self.assertIn(package, packages.split())
                self.assertIn("sudo systemctl enable --now bluetooth.service", calls)
                self.assertLess(calls.index("sudo ufw allow 53317"), calls.index("sudo ufw enable"))
                self.assertEqual("sudo ufw limit 22/tcp" in calls, full)
                self.assertEqual("appimages" in calls, full)
                installs = [c for c in calls if c.startswith("flatpak install ")]
                installed_apps = [c.split()[-1] for c in installs]
                self.assertIn("org.localsend.localsend_app", installed_apps)
                self.assertEqual("com.discordapp.Discord" in installed_apps, full)
                for item in ("hypr", "kitty"):
                    self.assertEqual(
                        (self.home / ".config" / item).resolve(),
                        self.repo / profile / item,
                    )
                self.assertEqual(calls[-2:], ["shell-setup", "grub-setup"])

    def grub_fixture(self):
        defaults = self.root / "etc/default/grub"
        config = self.root / "boot/grub/grub.cfg"
        defaults.parent.mkdir(parents=True)
        config.parent.mkdir(parents=True)
        defaults.write_text(
            "# Preserve this comment and the kernel command line\n"
            "GRUB_DEFAULT=0\n"
            "#GRUB_SAVEDEFAULT=false\n"
            'GRUB_TIMEOUT_STYLE="hidden"\n'
            "GRUB_TIMEOUT=0\n"
            "export GRUB_TIMEOUT=9 # Duplicate setting\n"
            "# GRUB_DISABLE_BOOTNEXT=false\n"
            'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"\n'
        )
        config.write_text("previous boot menu\n")
        defaults.chmod(0o640)
        config.chmod(0o600)
        return defaults, config

    def grub_stubs(self):
        return r'''
sudo() {
    printf '%s\n' "$*" >> "$AUDIT_ROOT/grub-commands"
    case "$1" in
        awk|mktemp|cp|tee|mv|rm|grub-mkconfig) "$@" ;;
        *) echo "Unexpected privileged operation: $1" >&2; exit 42 ;;
    esac
}
grub-mkconfig() {
    [[ "$1" == -o ]] || exit 43
    sh -c '. "$1"; printf "%s\n" "$GRUB_DEFAULT" "$GRUB_SAVEDEFAULT" "$GRUB_TIMEOUT_STYLE" "$GRUB_TIMEOUT" "$GRUB_DISABLE_BOOTNEXT"' \
        fixture "$AUDIT_ROOT/etc/default/grub" > "$AUDIT_ROOT/grub-values-seen"
    printf 'new boot menu\n' > "$2"
    return "${GRUB_FIXTURE_STATUS:-0}"
}
'''

    def configure_fixture_grub(self, prefix=""):
        return self.bash(
            self.grub_stubs()
            + prefix
            + '\nconfigure_grub "$AUDIT_ROOT/etc/default/grub" "$AUDIT_ROOT/boot/grub/grub.cfg"'
        )

    def test_grub_applies_all_five_settings_preserves_other_options_and_backs_up(self):
        defaults, config = self.grub_fixture()
        original = defaults.read_text()
        original_menu = config.read_text()
        result = self.configure_fixture_grub()
        self.assert_success(result)
        expected = {
            "GRUB_DEFAULT": "saved",
            "GRUB_SAVEDEFAULT": "true",
            "GRUB_TIMEOUT_STYLE": "menu",
            "GRUB_TIMEOUT": "5",
            "GRUB_DISABLE_BOOTNEXT": "true",
        }
        configured = defaults.read_text()
        for key, value in expected.items():
            self.assertEqual(re.findall(rf"^{key}=(.*)$", configured, re.M), [value])
        self.assertIn('GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"', configured)
        self.assertIn("# Preserve this comment and the kernel command line", configured)
        self.assertEqual((self.root / "grub-values-seen").read_text().splitlines(), list(expected.values()))
        self.assertEqual(next(defaults.parent.glob("grub.pre-archconfig-v6.*")).read_text(), original)
        self.assertEqual(next(config.parent.glob("grub.cfg.pre-archconfig-v6.*")).read_text(), original_menu)
        self.assertEqual(config.read_text(), "new boot menu\n")
        self.assertEqual(defaults.stat().st_mode & 0o777, 0o640)
        self.assertEqual(config.stat().st_mode & 0o777, 0o600)
        self.assert_success(self.configure_fixture_grub())
        self.assertEqual(defaults.read_text(), configured)
        self.assertEqual(list(defaults.parent.glob("grub.v6.*")), [])

    def test_grub_adds_missing_settings_without_replacing_config_symlinks(self):
        defaults, config = self.grub_fixture()
        defaults.write_text('GRUB_CMDLINE_LINUX_DEFAULT="quiet"\n')
        defaults_target = defaults.with_name("real-defaults")
        config_target = config.with_name("real-menu.cfg")
        defaults.rename(defaults_target)
        config.rename(config_target)
        defaults.symlink_to(defaults_target)
        config.symlink_to(config_target)
        self.assert_success(self.configure_fixture_grub())
        self.assertTrue(defaults.is_symlink())
        self.assertTrue(config.is_symlink())
        self.assertIn("GRUB_DISABLE_BOOTNEXT=true\n", defaults_target.read_text())
        self.assertEqual(config_target.read_text(), "new boot menu\n")
        self.assertEqual(
            (self.root / "grub-values-seen").read_text().splitlines(),
            ["saved", "true", "menu", "5", "true"],
        )

    def test_grub_generation_failure_restores_defaults_and_existing_menu(self):
        defaults, config = self.grub_fixture()
        original = defaults.read_bytes()
        menu = config.read_bytes()
        result = self.configure_fixture_grub("GRUB_FIXTURE_STATUS=25\n")
        self.assertEqual(result.returncode, 25, result.stdout + result.stderr)
        self.assertIn("restored the previous GRUB files", result.stderr)
        self.assertEqual(defaults.read_bytes(), original)
        self.assertEqual(config.read_bytes(), menu)
        self.assertEqual(defaults.stat().st_mode & 0o777, 0o640)
        self.assertEqual(config.stat().st_mode & 0o777, 0o600)

    def test_grub_generation_failure_removes_menu_that_did_not_previously_exist(self):
        defaults, config = self.grub_fixture()
        config.unlink()
        original = defaults.read_bytes()
        result = self.configure_fixture_grub("GRUB_FIXTURE_STATUS=25\n")
        self.assertEqual(result.returncode, 25, result.stdout + result.stderr)
        self.assertEqual(defaults.read_bytes(), original)
        self.assertFalse(config.exists())

    def test_grub_invalid_or_compound_settings_leave_original_files_unchanged(self):
        defaults, config = self.grub_fixture()
        for original in (
            "GRUB_TIMEOUT=0; echo PRESERVE_THIS_COMMAND\n",
            "GRUB_DEFAULT=0 echo PRESERVE_THIS_COMMAND\n",
            'GRUB_CMDLINE_LINUX_DEFAULT="unterminated\n',
        ):
            with self.subTest(original=original):
                defaults.write_text(original)
                result = self.configure_fixture_grub()
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(defaults.read_text(), original)
                self.assertEqual(config.read_text(), "previous boot menu\n")
                self.assertFalse((self.root / "grub-values-seen").exists())
                self.assertEqual(list(defaults.parent.glob("grub.pre-archconfig-v6.*")), [])

    def test_grub_skips_non_grub_system_and_requires_tools_when_configured(self):
        skipped = self.configure_fixture_grub()
        self.assert_success(skipped)
        self.assertIn("No existing GRUB installation", skipped.stdout)
        self.assertFalse((self.root / "grub-commands").exists())
        defaults, config = self.grub_fixture()
        original = defaults.read_text()
        missing = self.configure_fixture_grub("need_cmd() { return 1; }\n")
        self.assertEqual(missing.returncode, 1)
        self.assertIn("grub-mkconfig is unavailable", missing.stderr)
        self.assertEqual(defaults.read_text(), original)
        self.assertEqual(config.read_text(), "previous boot menu\n")

    def test_grub_stage_can_be_run_directly_and_resumed_after_failure(self):
        stubs = self.main_stubs()
        first = self.bash(
            stubs + "configure_grub() { audit_log grub-setup; return 25; }\n" + MAIN,
            args=("--from", "grub"),
        )
        self.assertEqual(first.returncode, 25)
        self.assertEqual(self.calls(), ["grub-setup"])
        self.assertEqual(self.checkpoint().read_text(), "grub\n")
        (self.root / "commands").unlink()
        resumed = self.bash(stubs + MAIN)
        self.assert_success(resumed)
        self.assertEqual(self.calls(), ["grub-setup"])
        self.assertEqual(self.checkpoint().read_text(), "complete\n")

    def test_failed_stage_stops_immediately_and_rerun_skips_completed_stages(self):
        stubs = self.main_stubs() + r'''
sudo() {
    audit_log sudo "$@"
    if [[ "$*" == 'systemctl enable --now bluetooth.service' && -f "$AUDIT_ROOT/fail-service" ]]; then
        return 23
    fi
}
'''
        failure = self.root / "fail-service"
        failure.touch()
        first = self.bash(stubs + MAIN, stdin="n\n")
        self.assertEqual(first.returncode, 23, first.stdout + first.stderr)
        self.assertEqual(self.checkpoint().read_text(), "services\n")
        self.assertNotIn("sudo systemctl enable --now libvirtd", self.calls())
        self.assertFalse(any(c.startswith("flatpak ") for c in self.calls()))
        failure.unlink()
        (self.root / "commands").unlink()
        second = self.bash(stubs + MAIN, stdin="n\nn\nn\ny\n")
        self.assert_success(second)
        self.assertIn("Resuming interrupted installation at stage: services", second.stdout)
        self.assertFalse(any(c.startswith("sudo pacman ") for c in self.calls()))
        self.assertIn("sudo systemctl enable --now bluetooth.service", self.calls())
        self.assertEqual(self.checkpoint().read_text(), "complete\n")

    def failing_anydesk_stubs(self):
        return self.main_stubs() + r'''
sleep() { audit_log sleep "$@"; }
flatpak() {
    audit_log flatpak "$@"
    if [[ "$1" == install && "${@: -1}" == com.anydesk.Anydesk && -f "$AUDIT_ROOT/fail-anydesk" ]]; then
        return 28
    fi
}
'''

    def test_flatpak_stop_and_resume_remembers_profile_and_successful_apps(self):
        stubs = self.failing_anydesk_stubs()
        failure = self.root / "fail-anydesk"
        failure.touch()
        first = self.bash(stubs + MAIN, stdin="y\nq\n", args=("--from", "flatpak"))
        self.assertEqual(first.returncode, 1, first.stdout + first.stderr)
        self.assertEqual(self.checkpoint().read_text(), "flatpak\n")
        state = self.checkpoint().parent
        completed = (state / "flatpak-completed").read_text().splitlines()
        self.assertIn("org.localsend.localsend_app", completed)
        self.assertEqual((state / "flatpak-profile").read_text(), "full\n")
        self.assertEqual(sum(c.endswith("com.anydesk.Anydesk") for c in self.calls()), 3)
        self.assertEqual(self.calls().count("sleep 5"), 2)
        self.assertNotIn("shell-setup", self.calls())
        self.assertFalse(any(c.startswith("sudo pacman ") for c in self.calls()))

        failure.unlink()
        (self.root / "commands").unlink()
        second = self.bash(stubs + MAIN, stdin="n\ny\n")
        self.assert_success(second)
        installed = [c.split()[-1] for c in self.calls() if c.startswith("flatpak install ")]
        self.assertEqual(installed[0], "com.anydesk.Anydesk")
        self.assertIn("com.discordapp.Discord", installed)
        self.assertFalse(set(installed) & set(completed))
        self.assertEqual(self.checkpoint().read_text(), "complete\n")
        self.assertIn("shell-setup", self.calls())

    def test_skipping_failed_flatpak_continues_and_reports_it_at_completion(self):
        stubs = self.failing_anydesk_stubs()
        (self.root / "fail-anydesk").touch()
        result = self.bash(stubs + MAIN, stdin="y\ns\nn\ny\n", args=("--from", "flatpak"))
        self.assert_success(result)
        self.assertIn("These Flatpaks were skipped", result.stdout)
        self.assertIn("com.anydesk.Anydesk", result.stdout)
        self.assertIn("To retry them", result.stdout)
        self.assertIn("shell-setup", self.calls())
        state = self.checkpoint().parent
        self.assertEqual((state / "flatpak-skipped").read_text(), "com.anydesk.Anydesk\n")
        self.assertNotIn("com.anydesk.Anydesk", (state / "flatpak-completed").read_text())
        self.assertTrue(any(c.endswith("org.blender.Blender") for c in self.calls()))
        self.assertEqual(self.checkpoint().read_text(), "complete\n")

    def test_retry_choice_after_three_failures_can_succeed(self):
        stubs = self.main_stubs() + r'''
sleep() { :; }
flatpak() {
    audit_log flatpak "$@"
    if [[ "$1" == install && "${@: -1}" == com.anydesk.Anydesk ]]; then
        local count=0
        if [[ -f "$AUDIT_ROOT/attempts" ]]; then count="$(cat "$AUDIT_ROOT/attempts")"; fi
        count=$((count + 1))
        printf '%s\n' "$count" > "$AUDIT_ROOT/attempts"
        if ((count <= 3)); then return 28; fi
    fi
}
'''
        result = self.bash(stubs + MAIN, stdin="y\nr\nn\ny\n", args=("--from", "flatpak"))
        self.assert_success(result)
        self.assertEqual((self.root / "attempts").read_text(), "4\n")
        self.assertFalse((self.checkpoint().parent / "flatpak-skipped").exists())
        self.assertEqual(self.checkpoint().read_text(), "complete\n")

    def test_eof_after_flatpak_failure_stops_and_keeps_resume_progress(self):
        stubs = self.failing_anydesk_stubs()
        (self.root / "fail-anydesk").touch()
        result = self.bash(stubs + MAIN, stdin="y\n", args=("--from", "flatpak"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("Input closed", result.stderr)
        self.assertNotIn("shell-setup", self.calls())
        self.assertEqual(self.checkpoint().read_text(), "flatpak\n")
        self.assertIn(
            "org.localsend.localsend_app",
            (self.checkpoint().parent / "flatpak-completed").read_text(),
        )

    def test_flatpak_cancellation_is_not_retried_or_recorded_as_complete(self):
        stubs = self.main_stubs() + r'''
flatpak() {
    audit_log flatpak "$@"
    if [[ "$1" == install ]]; then return 130; fi
}
sleep() { audit_log sleep "$@"; }
'''
        result = self.bash(stubs + MAIN, stdin="n\n", args=("--from", "flatpak"))
        self.assertEqual(result.returncode, 130)
        self.assertIn("Installation interrupted", result.stderr)
        self.assertEqual(sum(c.startswith("flatpak install ") for c in self.calls()), 1)
        self.assertFalse(any(c.startswith("sleep ") for c in self.calls()))
        self.assertEqual(self.checkpoint().read_text(), "flatpak\n")
        self.assertFalse((self.checkpoint().parent / "flatpak-completed").exists())

    def test_restart_discards_old_flatpak_choices_and_runs_earlier_stages(self):
        stubs = self.failing_anydesk_stubs()
        (self.root / "fail-anydesk").touch()
        first = self.bash(stubs + MAIN, stdin="y\nq\n", args=("--from", "flatpak"))
        self.assertEqual(first.returncode, 1)
        (self.root / "commands").unlink()
        result = self.bash(stubs + MAIN, stdin="n\nn\nn\nn\ny\n", args=("--restart",))
        self.assert_success(result)
        self.assertIn("sudo pacman -Syu", self.calls())
        self.assertFalse(any(c.endswith("com.anydesk.Anydesk") for c in self.calls()))
        self.assertEqual((self.checkpoint().parent / "flatpak-profile").read_text(), "minimal\n")
        self.assertEqual(self.checkpoint().read_text(), "complete\n")

    def test_help_and_invalid_arguments_do_not_run_stages_or_create_state(self):
        stubs = self.main_stubs()
        cases = (
            (("--help",), 0),
            (("--from",), 2),
            (("--from", "unknown"), 2),
            (("--from", "system packages"), 2),
            (("--restart", "--from", "flatpak"), 2),
            (("--unknown",), 2),
        )
        for args, code in cases:
            with self.subTest(args=args):
                result = self.bash(stubs + MAIN, args=args)
                self.assertEqual(result.returncode, code, result.stdout + result.stderr)
                self.assertFalse((self.root / "commands").exists())
                self.assertFalse((self.home / ".local/state").exists())

    def test_corrupt_checkpoint_is_not_executed_and_can_be_recovered(self):
        stubs = self.main_stubs()
        first = self.bash(stubs + "stage_shell() { return 23; }\n" + MAIN, args=("--from", "shell"))
        self.assertEqual(first.returncode, 23)
        checkpoint = self.checkpoint()
        checkpoint.write_text('$(touch "$AUDIT_ROOT/pwned")\n')
        bad = self.bash(stubs + MAIN)
        self.assertEqual(bad.returncode, 1)
        self.assertIn("Invalid saved stage", bad.stderr)
        self.assertFalse((self.root / "pwned").exists())
        recovered = self.bash(stubs + MAIN, args=("--from", "shell"))
        self.assert_success(recovered)
        self.assertEqual(checkpoint.read_text(), "complete\n")

    def test_concurrent_installer_is_rejected_without_running_a_stage(self):
        stubs = self.main_stubs()
        first = self.bash(stubs + "stage_shell() { return 23; }\n" + MAIN, args=("--from", "shell"))
        self.assertEqual(first.returncode, 23)
        lock = self.checkpoint().parent / "lock"
        holder = subprocess.Popen(
            ["bash", "-c", 'exec 9>"$1"; flock 9; echo ready; read -r', "lock-holder", str(lock)],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
        )
        try:
            self.assertEqual(holder.stdout.readline().strip(), "ready")
            result = self.bash(stubs + MAIN)
            self.assertEqual(result.returncode, 1)
            self.assertIn("already running", result.stderr)
            self.assertFalse((self.root / "commands").exists())
        finally:
            holder.communicate(input="\n", timeout=2)


if __name__ == "__main__":
    unittest.main()
