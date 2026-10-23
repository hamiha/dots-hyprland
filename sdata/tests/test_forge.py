#!/usr/bin/env python3
"""Exercise forge with mocked commands; never install packages or touch live config."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


FORGE = Path(__file__).resolve().parents[2] / "forge"
MOCK = """#!/usr/bin/env bash
set -eu
name="${0##*/}"
printf '%s|%s\\n' "$name $*" "$PWD" >> "$TEST_LOG"
case "$name" in
  git)
    case "$*" in
      *'rev-parse --show-toplevel') printf '%s\\n' "$TEST_ROOT" ;;
      *'branch --show-current') printf '%s\\n' "${TEST_BRANCH:-main}" ;;
    esac
    ;;
  makepkg) exit "${TEST_BUILD_EXIT:-0}" ;;
  quickshell) exit "${TEST_COMPAT_EXIT:-0}" ;;
  rsync|killall|qs) echo "Unexpected live-shell mutation" >&2; exit 99 ;;
esac
"""


class ForgeTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="forge-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        shutil.copy2(FORGE, self.repo / "forge")
        self.package = self.repo / "sdata/dist-arch/illogical-impulse-quickshell-git"
        self.package.mkdir(parents=True)
        (self.package / "PKGBUILD").write_text("depends=(qt6-base)\n")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("git", "yay", "makepkg", "quickshell", "sudo", "rsync", "killall", "qs"):
            self.mock(self.bin / name)
        self.mock(self.repo / "setup")
        self.log = self.root / "commands.log"
        self.config = self.root / "home/.config/quickshell/ii/shell.qml"
        self.config.parent.mkdir(parents=True)
        self.config.write_text("keep my settings\n")

    def mock(self, path):
        path.write_text(MOCK)
        path.chmod(0o755)

    def run_forge(self, *args, **overrides):
        env = dict(os.environ, PATH=f"{self.bin}:{os.defpath}",
                   HOME=str(self.root / "home"), TEST_ROOT=str(self.repo),
                   TEST_LOG=str(self.log), **overrides)
        self.result = subprocess.run(
            ["bash", str(self.repo / "forge"), *args], cwd=self.root, env=env,
            capture_output=True, text=True, timeout=10,
        )
        self.calls = self.log.read_text().splitlines() if self.log.exists() else []
        self.commands = [line.split("|", 1)[0] for line in self.calls]
        self.assertEqual(self.config.read_text(), "keep my settings\n")
        self.assertFalse(any(cmd.startswith(("rsync ", "killall ", "qs "))
                             for cmd in self.commands))
        return self.result.returncode

    def test_default_runs_setup_from_main(self):
        self.assertEqual(self.run_forge(TEST_BRANCH="legacy"), 0, self.result.stderr)
        self.assertIn(f"git -C {self.repo} checkout main", self.commands)
        self.assertIn(f"git -C {self.repo} pull --ff-only origin main", self.commands)
        self.assertIn(f"git -C {self.repo} submodule update --init --recursive", self.commands)
        self.assertIn(f"setup install|{self.repo}", self.calls)
        self.assertIn("sudo pacman -S --needed --noconfirm awww", self.commands)
        self.assertFalse(any(cmd.startswith("makepkg ") for cmd in self.commands))

    def test_explicit_all_skips_pull(self):
        self.assertEqual(self.run_forge("all", "--no-pull"), 0, self.result.stderr)
        self.assertIn("setup install", self.commands)
        self.assertFalse(any(" pull " in cmd for cmd in self.commands))

    def test_quickshell_only_rebuilds_package(self):
        self.assertEqual(self.run_forge("quickshell", "--no-pull"), 0, self.result.stderr)
        self.assertIn(f"makepkg -Cfsi --noconfirm|{self.package}", self.calls)
        self.assertIn("quickshell --private-check-compat", self.commands)
        self.assertFalse(any(cmd.startswith(("setup ", "sudo ")) or "submodule" in cmd
                             or " pull " in cmd for cmd in self.commands))

    def test_build_failure_stops_before_compatibility_check(self):
        self.assertEqual(self.run_forge("quickshell", "--no-pull", TEST_BUILD_EXIT="42"), 42)
        self.assertNotIn("quickshell --private-check-compat", self.commands)
        self.assertNotIn("successfully reforged", self.result.stdout)

    def test_incompatible_build_fails(self):
        self.assertEqual(self.run_forge("quickshell", "--no-pull", TEST_COMPAT_EXIT="7"), 7)
        self.assertNotIn("successfully reforged", self.result.stdout)

    def test_missing_recipe_fails(self):
        (self.package / "PKGBUILD").unlink()
        self.assertNotEqual(self.run_forge("quickshell", "--no-pull"), 0)
        self.assertFalse(any(cmd.startswith("makepkg ") for cmd in self.commands))

    def test_help_and_invalid_args_do_not_install(self):
        self.assertEqual(self.run_forge("--help"), 0)
        self.assertIn("default", self.result.stdout)
        self.assertNotEqual(self.run_forge("--invalid"), 0)
        self.assertFalse(any(cmd.startswith(("setup ", "makepkg ", "sudo "))
                             for cmd in self.commands))


if __name__ == "__main__":
    unittest.main()
