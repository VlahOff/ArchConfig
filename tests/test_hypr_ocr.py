"""Run the actual OCR binding with fake display, OCR, and clipboard commands.

Run with: python3 -m unittest discover -s tests -p test_hypr_ocr.py -v
"""

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
CONFIGS = (REPO / "configs/hypr/hyprland.lua", REPO / "configs-laptop/hypr/hyprland.lua")
PREVIOUS = "Existing clipboard: съществуващ текст".encode()
TEXT = "Hello, свят!\nSecond line: %s $HOME `printf nope` ' \" \\\n  край  "
MOCK = r'''import json, os, pathlib, sys
root = pathlib.Path(os.environ["OCR_TEST_ROOT"])
command = pathlib.Path(sys.argv[0]).name
def record(event, **fields):
    with (root / "events").open("a") as stream:
        stream.write(json.dumps(dict(event=event, **fields)) + "\n")
if command == "slurp":
    record("select")
    sys.stdout.write(os.environ["OCR_TEST_SELECTION"])
    sys.exit(int(os.environ["OCR_TEST_SELECTION_STATUS"]))
elif command == "grim":
    assert sys.argv[1:] == ["-g", os.environ["OCR_TEST_SELECTION"].rstrip("\n"), "-t", "png", "-"]
    record("capture")
    sys.stdout.write("partial or complete screenshot")
    sys.exit(int(os.environ["OCR_TEST_CAPTURE_STATUS"]))
elif command == "tesseract":
    assert sys.argv[1:] == ["stdin", "stdout", "-l", "eng+bul"]
    sys.stdin.buffer.read()
    record("recognize")
    sys.stdout.write(os.environ["OCR_TEST_TEXT"])
    sys.exit(int(os.environ["OCR_TEST_RECOGNIZE_STATUS"]))
elif command == "wl-copy":
    assert sys.argv[1:] == ["--type", "text/plain"]
    data = sys.stdin.buffer.read()
    if os.environ["OCR_TEST_COPY_STATUS"] != "0":
        record("copy_failed")
        sys.exit(int(os.environ["OCR_TEST_COPY_STATUS"]))
    (root / "clipboard").write_bytes(data)
    record("copy")
elif command == "notify-send":
    assert sys.argv[1:] == ["OCR", "Text copied to clipboard"]
    record("notify", clipboard=(root / "clipboard").read_text())
else:
    raise SystemExit("Unexpected mock invocation: " + repr(sys.argv))
'''


def ocr_command(config):
    match = re.search(
        r'hl\.bind\(mainMod \.\. " \+ T", hl\.dsp\.exec_cmd\(\s*\[\[(.*?)\]\]\)\)',
        config.read_text(), re.DOTALL,
    )
    if not match:
        raise AssertionError(f"OCR binding long string not found in {config}")
    # Lua ignores a newline immediately after the long-string opener.
    return match.group(1).removeprefix("\n")


class HyprOcrTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="hypr-ocr-tests-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("slurp", "grim", "tesseract", "wl-copy", "notify-send"):
            path = self.bin / name
            path.write_text("#!" + sys.executable + "\n" + MOCK)
            path.chmod(0o700)
        self.clipboard = self.root / "clipboard"
        self.clipboard.write_bytes(PREVIOUS)

    def run_ocr(self, **settings):
        return subprocess.run(
            ["sh", "-c", ocr_command(CONFIGS[0])],
            cwd=self.root, capture_output=True, timeout=5,
            env={**os.environ, "PATH": f"{self.bin}:/usr/bin:/bin",
                 "OCR_TEST_ROOT": str(self.root), "OCR_TEST_SELECTION": "10,20 300x100",
                 "OCR_TEST_SELECTION_STATUS": "0", "OCR_TEST_CAPTURE_STATUS": "0",
                 "OCR_TEST_RECOGNIZE_STATUS": "0", "OCR_TEST_COPY_STATUS": "0",
                 "OCR_TEST_TEXT": TEXT, **settings},
        )

    def events(self):
        path = self.root / "events"
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def assert_preserved(self):
        self.assertEqual(self.clipboard.read_bytes(), PREVIOUS)
        self.assertFalse({"copy", "copy_failed", "notify"} & {row["event"] for row in self.events()})

    def test_desktop_and_laptop_commands_match(self):
        self.assertEqual(ocr_command(CONFIGS[0]), ocr_command(CONFIGS[1]))

    def test_cancelled_selection_even_with_partial_output_preserves_clipboard(self):
        for selection in ("", "10,20 300x100"):
            with self.subTest(selection=selection):
                result = self.run_ocr(OCR_TEST_SELECTION=selection, OCR_TEST_SELECTION_STATUS="1")
                self.assertNotEqual(result.returncode, 0, result.stderr)
                self.assert_preserved()
                self.assertEqual({row["event"] for row in self.events()}, {"select"})

    def test_empty_selection_preserves_clipboard(self):
        result = self.run_ocr(OCR_TEST_SELECTION="")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_preserved()
        self.assertEqual([row["event"] for row in self.events()], ["select"])

    def test_failed_capture_with_partial_stdout_preserves_clipboard(self):
        result = self.run_ocr(OCR_TEST_CAPTURE_STATUS="1")
        self.assertNotEqual(result.returncode, 0, result.stderr)
        self.assert_preserved()

    def test_failed_recognition_with_partial_text_preserves_clipboard(self):
        result = self.run_ocr(OCR_TEST_RECOGNIZE_STATUS="1", OCR_TEST_TEXT="partial текст")
        self.assertNotEqual(result.returncode, 0, result.stderr)
        self.assert_preserved()

    def test_empty_recognition_preserves_clipboard(self):
        result = self.run_ocr(OCR_TEST_TEXT="\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_preserved()

    def test_success_copies_exact_text_before_notifying(self):
        result = self.run_ocr()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.clipboard.read_bytes(), TEXT.encode())
        rows = self.events()
        self.assertEqual([row["event"] for row in rows][-2:], ["copy", "notify"])
        self.assertEqual(rows[-1]["clipboard"], TEXT)

    def test_failed_copy_does_not_send_success_notification(self):
        result = self.run_ocr(OCR_TEST_COPY_STATUS="1")
        self.assertNotEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.clipboard.read_bytes(), PREVIOUS)
        self.assertEqual([row["event"] for row in self.events()][-1], "copy_failed")
        self.assertNotIn("notify", [row["event"] for row in self.events()])


if __name__ == "__main__":
    unittest.main()
