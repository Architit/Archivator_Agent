import hashlib
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PATCH_SH = REPO_ROOT / "devkit" / "patch.sh"

def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, text=True, capture_output=True, check=False)

class TestPhaseBPatchRuntimeContract(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        run(["git", "init"], self.repo)
        run(["git", "config", "user.email", "phaseb@test.local"], self.repo)
        run(["git", "config", "user.name", "phaseb-test"], self.repo)
        (self.repo / "a.txt").write_text("hello\n", encoding="utf-8")
        (self.repo / "task_spec.yaml").write_text("spec_version: '1.1'\n", encoding="utf-8")
        run(["git", "add", "a.txt", "task_spec.yaml"], self.repo)
        run(["git", "commit", "-m", "init"], self.repo)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def _patch(self, content: str, name: str) -> Path:
        (self.repo / "a.txt").write_text(content, encoding="utf-8")
        patch = run(["git", "diff"], self.repo).stdout
        p = self.repo / name
        p.write_text(patch, encoding="utf-8")
        run(["git", "checkout", "--", "a.txt"], self.repo)
        return p

    def test_success(self) -> None:
        p = self._patch("hello world\n", "ok.patch")
        sha = hashlib.sha256(p.read_bytes()).hexdigest()
        r = run(["bash", str(PATCH_SH), "--file", str(p), "--sha256", sha, "--task-id", "ok", "--spec-file", "task_spec.yaml"], self.repo)
        self.assertEqual(r.returncode, 0, msg=r.stderr + r.stdout)
        self.assertIn("status=success", r.stdout)
        self.assertIn("trace: task_id=ok", r.stdout)
        self.assertNotIn("spec_hash= ", r.stdout)

    def test_missing_spec(self) -> None:
        p = self._patch("hello miss\n", "miss.patch")
        sha = hashlib.sha256(p.read_bytes()).hexdigest()
        r = run(["bash", str(PATCH_SH), "--file", str(p), "--sha256", sha, "--task-id", "x"], self.repo)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("error_code=PATCH_SPEC_FILE_REQUIRED", r.stdout)

    def test_integrity_mismatch(self) -> None:
        p = self._patch("hello mismatch\n", "badsha.patch")
        r = run(["bash", str(PATCH_SH), "--file", str(p), "--sha256", "0" * 64, "--task-id", "x", "--spec-file", "task_spec.yaml"], self.repo)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("status=integrity_mismatch", r.stdout)

    def test_conflict_detected(self) -> None:
        p = self.repo / "bad.patch"
        p.write_text("not-a-valid-patch\n", encoding="utf-8")
        sha = hashlib.sha256(p.read_bytes()).hexdigest()
        r = run(["bash", str(PATCH_SH), "--file", str(p), "--sha256", sha, "--task-id", "x", "--spec-file", "task_spec.yaml"], self.repo)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("status=conflict_detected", r.stdout)

if __name__ == "__main__":
    unittest.main()
