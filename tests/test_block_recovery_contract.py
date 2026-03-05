import importlib.util
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = REPO_ROOT / "devkit" / "shell_preflight_check.py"

_SPEC = importlib.util.spec_from_file_location("shell_preflight_check", MODULE_PATH)
if _SPEC is None or _SPEC.loader is None:
    raise RuntimeError(f"Unable to load module from {MODULE_PATH}")
MODULE = importlib.util.module_from_spec(_SPEC)
sys.modules[_SPEC.name] = MODULE
_SPEC.loader.exec_module(MODULE)


class TestBlockRecoveryContract(unittest.TestCase):
    def test_open_decision_for_safe_command(self):
        findings = MODULE.run_checks("bash", ["printf 'ok'"])
        if hasattr(MODULE, "build_gate_guidance"):
            guidance = MODULE.build_gate_guidance(findings)
            self.assertEqual(guidance["decision"], "OPEN")
            self.assertEqual(guidance["reason_code"], "NONE")
            self.assertEqual(guidance["next_actions"], [])
            return
        self.assertEqual(findings, [])

    def test_hold_decision_for_warning_only(self):
        findings = MODULE.run_checks("bash", ["echo $(date)"])
        if hasattr(MODULE, "build_gate_guidance"):
            guidance = MODULE.build_gate_guidance(findings)
            self.assertEqual(guidance["decision"], "HOLD")
            self.assertEqual(guidance["reason_code"], "PF_COMMAND_SUBSTITUTION_PRESENT")
            self.assertTrue(guidance["next_actions"])
            return
        self.assertTrue(findings)
        self.assertTrue(all(f.severity != "ERROR" for f in findings))
        self.assertTrue(any(f.rule_id == "PF_COMMAND_SUBSTITUTION_PRESENT" for f in findings))

    def test_block_decision_has_reason_and_next_action(self):
        findings = MODULE.run_checks("bash", ["echo `uname`"])
        if hasattr(MODULE, "build_gate_guidance"):
            guidance = MODULE.build_gate_guidance(findings)
            self.assertEqual(guidance["decision"], "BLOCK")
            self.assertEqual(guidance["reason_code"], "PF_BACKTICK_SUBSTITUTION_RISK")
            self.assertTrue(guidance["next_actions"])
            return
        self.assertTrue(findings)
        self.assertTrue(any(f.severity == "ERROR" for f in findings))
        self.assertTrue(any(f.rule_id == "PF_BACKTICK_SUBSTITUTION_RISK" for f in findings))


if __name__ == "__main__":
    unittest.main()
