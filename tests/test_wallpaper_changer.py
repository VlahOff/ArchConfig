"""Wallpaper process regressions using temporary script copies and fake IPC.

Run with: python3 -m unittest discover -s tests -p test_wallpaper_changer.py -v
"""

import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import unittest


REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "configs/hypr/new_wallpaper_changer.sh"
LAPTOP_SCRIPT = REPO / "configs-laptop/hypr/new_wallpaper_changer.sh"
MOCK = r'''import json, os, pathlib, sys, time
root = pathlib.Path(os.environ["WALLPAPER_TEST_ROOT"])
session = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
command = pathlib.Path(sys.argv[0]).name
ready = root / (session + ".ready")
def record(event, **fields):
    fd = os.open(root / "events", os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o600)
    os.write(fd, (json.dumps(dict(event=event, session=session, **fields)) + "\n").encode())
    os.close(fd)
if command == "sleep":
    record("sleep", seconds=sys.argv[1])
    while (root / "hold-sleep").exists():
        time.sleep(0.01)
    time.sleep(0.04)
elif command == "hyprpaper":
    try:
        os.fstat(9)
        inherited_lock = True
    except OSError:
        inherited_lock = False
    record("daemon", pid=os.getpid(), inherited_lock=inherited_lock)
    ready.touch()
    while True:
        time.sleep(0.1)
elif sys.argv[1:] == ["hyprpaper", "listactive"]:
    sys.exit(0 if os.environ["WALLPAPER_TEST_DAEMON_EXISTS"] == "1" or ready.exists() else 1)
elif sys.argv[1:] == ["monitors"]:
    dpms = (root / "dpms").read_text() if (root / "dpms").exists() else "1"
    for index, monitor in enumerate(os.environ.get("WALLPAPER_TEST_MONITORS", "TEST-1").split()):
        print(f"Monitor {monitor} (ID {index}):\n    dpmsStatus: {dpms}")
elif sys.argv[1:3] == ["hyprpaper", "wallpaper"]:
    failures = root / "apply-failures"
    remaining = int(failures.read_text()) if failures.exists() else 0
    if remaining:
        failures.write_text(str(remaining - 1))
    record("wallpaper", args=sys.argv[3:], status=int(remaining > 0))
    sys.exit(int(remaining > 0))
else:
    raise SystemExit("Unexpected mock invocation: " + repr(sys.argv))
'''


@unittest.skipUnless(shutil.which("flock"), "flock is required")
class WallpaperChangerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="wallpaper-changer-tests-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.processes = []
        self.addCleanup(self.stop_all)
        self.script = self.root / "new_wallpaper_changer.sh"
        shutil.copyfile(SCRIPT, self.script)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("hyprctl", "hyprpaper", "sleep"):
            mock = self.bin / name
            mock.write_text("#!" + sys.executable + "\n" + MOCK)
            mock.chmod(0o700)
        self.images = self.root / "images"
        self.images.mkdir()
        (self.images / "fixture.png").touch()

    def spawn(self, command, **env):
        output = self.root / f"process-{len(self.processes)}.log"
        with output.open("w") as stream:
            process = subprocess.Popen(
                command, cwd=self.root, start_new_session=True,
                stdout=stream, stderr=subprocess.STDOUT,
                env={**os.environ, "PATH": f"{self.bin}:/usr/bin:/bin",
                     "XDG_RUNTIME_DIR": str(self.root), "IMAGE_DIR": str(self.images),
                     "INTERVAL": "600", "DPMS_POLL_INTERVAL": "5",
                     "HYPRLAND_INSTANCE_SIGNATURE": "session-a",
                     "WALLPAPER_TEST_ROOT": str(self.root),
                     "WALLPAPER_TEST_DAEMON_EXISTS": "1", **env},
            )
        self.processes.append(process)
        return process

    def start(self, session="session-a", **env):
        return self.spawn(["bash", str(self.script)], HYPRLAND_INSTANCE_SIGNATURE=session, **env)

    def events(self, event=None, session="session-a"):
        path = self.root / "events"
        rows = [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []
        return [row for row in rows if (event is None or row["event"] == event) and row["session"] == session]

    def wait_for(self, predicate):
        deadline = time.monotonic() + 4
        while time.monotonic() < deadline:
            if predicate():
                return
            time.sleep(0.02)
        logs = "\n".join(path.read_text() for path in self.root.glob("process-*.log"))
        self.fail("Timed out waiting for mock activity.\n" + logs)

    def stop(self, process):
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=3)

    def stop_all(self):
        # Every group was created by spawn(); never inspect or signal other processes.
        for process in self.processes:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait(timeout=3)

    def test_desktop_and_laptop_scripts_match(self):
        self.assertEqual(SCRIPT.read_bytes(), LAPTOP_SCRIPT.read_bytes())

    def test_editor_and_stale_pidfile_are_not_killed(self):
        editor = self.spawn([sys.executable, "-c", "import time; time.sleep(60)", str(self.script)])
        (self.root / f"hyprpaper_wallpaper_changer.{os.getuid()}.pid").write_text(str(editor.pid))
        slideshow = self.start()
        self.wait_for(lambda: self.events("wallpaper"))
        self.assertIsNone(editor.poll())
        self.assertIsNone(slideshow.poll())

    def test_duplicate_session_reuses_running_slideshow(self):
        first = self.start()
        self.wait_for(lambda: self.events("wallpaper"))
        duplicate = self.start()
        self.assertEqual(duplicate.wait(timeout=3), 0)
        self.assertIsNone(first.poll())
        self.assertEqual(len(self.events("wallpaper")), 1)

    def test_distinct_sessions_can_run_together(self):
        first, second = self.start(), self.start("session-b")
        self.wait_for(lambda: self.events("wallpaper") and self.events("wallpaper", "session-b"))
        self.assertIsNone(first.poll())
        self.assertIsNone(second.poll())

    def test_daemon_does_not_hold_lock_and_restart_succeeds(self):
        first = self.start(WALLPAPER_TEST_DAEMON_EXISTS="0")
        self.wait_for(lambda: self.events("wallpaper"))
        daemon, = self.events("daemon")
        self.assertFalse(daemon["inherited_lock"])
        self.stop(first)
        os.kill(daemon["pid"], 0)
        restarted = self.start(WALLPAPER_TEST_DAEMON_EXISTS="0")
        self.wait_for(lambda: len(self.events("wallpaper")) == 2)
        self.assertIsNone(restarted.poll())
        self.assertEqual(len(self.events("daemon")), 1)

    def test_one_fallback_request_covers_multiple_monitors_and_spaced_image_path(self):
        image = self.images / "wallpaper with spaces.png"
        (self.images / "fixture.png").rename(image)
        process = self.start(WALLPAPER_TEST_MONITORS="TEST-1 TEST-2")
        self.wait_for(lambda: self.events("sleep"))
        self.stop(process)
        requests = self.events("wallpaper")
        self.assertEqual(len(requests), 1)
        self.assertEqual(requests[0]["args"], [f", {image}, cover"])

    def test_failed_apply_retries_after_poll_instead_of_full_interval(self):
        (self.root / "apply-failures").write_text("1")
        process = self.start()
        self.wait_for(lambda: len(self.events("wallpaper")) >= 2)
        self.stop(process)
        requests = self.events("wallpaper")
        self.assertEqual([row["status"] for row in requests[:2]], [1, 0])
        rows = self.events()
        first, second = [i for i, row in enumerate(rows) if row["event"] == "wallpaper"][:2]
        sleeps = [row["seconds"] for row in rows[first + 1:second] if row["event"] == "sleep"]
        self.assertEqual(sleeps, ["5"])

    def test_dpms_sleep_pauses_changes_and_awake_interval(self):
        dpms = self.root / "dpms"
        dpms.write_text("0")
        (self.images / "second image.png").touch()
        process = self.start(INTERVAL="5")
        self.wait_for(lambda: len(self.events("sleep")) >= 2)
        self.assertFalse(self.events("wallpaper"))
        # Hold the next tick so the test can put displays back to sleep after
        # the first apply, before its interval can elapse.
        hold = self.root / "hold-sleep"
        hold.touch()
        dpms.write_text("1")
        self.wait_for(lambda: self.events("wallpaper"))
        dpms.write_text("0")
        before = len(self.events("sleep"))
        hold.unlink()
        self.wait_for(lambda: len(self.events("sleep")) >= before + 2)
        self.assertEqual(len(self.events("wallpaper")), 1)
        dpms.write_text("1")
        self.wait_for(lambda: len(self.events("wallpaper")) >= 2)
        self.stop(process)


if __name__ == "__main__":
    unittest.main()
