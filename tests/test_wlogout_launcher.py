"""Exercise launcher geometry with fake IPC and a recorder instead of a GUI.

Run with: python3 -m unittest discover -s tests -p test_wlogout_launcher.py -v
"""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
LAUNCHER = REPO / "configs/wlogout/launch.py"
LAPTOP_LAUNCHER = REPO / "configs-laptop/wlogout/launch.py"
MOCK = r'''import json, os, pathlib, sys
root = pathlib.Path(os.environ["WLOGOUT_TEST_ROOT"])
if pathlib.Path(sys.argv[0]).name == "hyprctl":
    assert sys.argv[1:] == ["-j", "monitors"]
    sys.stdout.write((root / "monitors").read_text())
    sys.exit(int(os.environ.get("WLOGOUT_TEST_IPC_STATUS", "0")))
else:
    (root / "arguments").write_text(json.dumps(sys.argv[1:]))
'''


class WlogoutLauncherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="wlogout-launcher-tests-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("hyprctl", "wlogout"):
            path = self.bin / name
            path.write_text("#!" + sys.executable + "\n" + MOCK)
            path.chmod(0o700)

    def launch(self, monitors=None, *, raw=None, status=0, extra=()):
        data = json.dumps(monitors) if raw is None else raw
        (self.root / "monitors").write_text(data)
        result = subprocess.run(
            [sys.executable, str(LAUNCHER), *extra], cwd=self.root,
            capture_output=True, text=True, timeout=5,
            env={**os.environ, "PATH": str(self.bin), "WLOGOUT_TEST_ROOT": str(self.root),
                 "WLOGOUT_TEST_IPC_STATUS": str(status)},
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return json.loads((self.root / "arguments").read_text())

    @staticmethod
    def monitor(width, height, *, scale=1, transform=0, focused=True):
        return dict(width=width, height=height, scale=scale, transform=transform, focused=focused)

    def assert_panel(self, args, screen, panel):
        def option(name):
            return args[args.index(name) + 1]

        self.assertEqual(option("--buttons-per-row"), "5")
        self.assertEqual(option("--column-spacing"), "14")
        self.assertIn("--no-span", args)
        left, right, top, bottom = [int(option("--margin-" + side)) for side in ("left", "right", "top", "bottom")]
        self.assertTrue(all(value >= 0 for value in (left, right, top, bottom)))
        self.assertEqual((screen[0] - left - right, screen[1] - top - bottom), panel)
        self.assertLessEqual(abs(left - right), 1)
        self.assertLessEqual(abs(top - bottom), 1)

    def test_ultrawide_laptop_scaled_rotated_and_odd_dimensions(self):
        cases = [
            (self.monitor(5120, 1440), (5120, 1440), (920, 240)),
            (self.monitor(1920, 1080), (1920, 1080), (920, 240)),
            (self.monitor(3840, 2160, scale=2), (1920, 1080), (920, 240)),
            (self.monitor(3440, 1440, transform=1), (1440, 3440), (920, 240)),
            (self.monitor(1920, 1080, scale=1.25, transform=3), (864, 1536), (816, 240)),
            (self.monitor(1921, 1081), (1921, 1081), (920, 240)),
        ]
        for monitor, screen, panel in cases:
            with self.subTest(monitor=monitor):
                self.assert_panel(self.launch([monitor]), screen, panel)

    def test_small_screens_keep_positive_panel_with_nonnegative_margins(self):
        for width, height, panel in ((640, 360, (592, 240)), (48, 40, (1, 1))):
            with self.subTest(screen=(width, height)):
                self.assert_panel(self.launch([self.monitor(width, height)]), (width, height), panel)

    def test_focused_monitor_is_preferred(self):
        args = self.launch([self.monitor(5120, 1440, focused=False), self.monitor(1920, 1080)])
        self.assert_panel(args, (1920, 1080), (920, 240))

    def test_first_monitor_is_used_without_focus_flag(self):
        args = self.launch([self.monitor(800, 600, focused=False), self.monitor(5120, 1440, focused=False)])
        self.assert_panel(args, (800, 600), (752, 240))

    def test_invalid_or_failed_ipc_uses_stable_fallback(self):
        cases = [
            dict(raw="invalid JSON"), dict(raw="{}"), dict(monitors=[]),
            dict(monitors=[{}]), dict(monitors=[self.monitor(0, 1080)]),
            dict(monitors=[self.monitor(1920, 1080, scale=0)]),
            dict(monitors=[self.monitor(800, 600)], status=1),
        ]
        for case in cases:
            with self.subTest(case=case):
                self.assert_panel(self.launch(**case), (1920, 1080), (920, 240))

    def test_missing_ipc_command_uses_stable_fallback(self):
        (self.bin / "hyprctl").unlink()
        self.assert_panel(self.launch(), (1920, 1080), (920, 240))

    def test_preview_arguments_are_forwarded_unchanged(self):
        extra = ("--layout", "/tmp/preview layout", "--css", "/tmp/preview style.css", "--show-binds")
        args = self.launch([self.monitor(1920, 1080)], extra=extra)
        self.assertEqual(args[-len(extra):], list(extra))

    def test_launcher_copies_match_and_are_executable(self):
        self.assertEqual(LAUNCHER.read_bytes(), LAPTOP_LAUNCHER.read_bytes())
        self.assertTrue(os.access(LAUNCHER, os.X_OK))
        self.assertTrue(os.access(LAPTOP_LAUNCHER, os.X_OK))


if __name__ == "__main__":
    unittest.main()
