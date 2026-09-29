import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
RESOLVER = ROOT / "scripts/lib/resolve_codex_models.py"


class ResolveCodexModelsTests(unittest.TestCase):
    def run_resolver(self, server_source: str, timeout: str = "1") -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as temp_dir:
            server = Path(temp_dir) / "fake_codex"
            server.write_text(f"#!{sys.executable}\n{server_source}", encoding="utf-8")
            server.chmod(0o755)
            env = os.environ.copy()
            env["CODEX_MODEL_LIST_TIMEOUT_SECONDS"] = timeout
            return subprocess.run(
                [sys.executable, str(RESOLVER), str(server), ""],
                capture_output=True,
                text=True,
                env=env,
                timeout=3,
                check=False,
            )

    def test_reads_available_models(self) -> None:
        response = json.dumps(
            {"jsonrpc": "2.0", "id": 2, "result": {"data": [{"id": "gpt-test", "isDefault": True}]}}
        )
        result = self.run_resolver(
            "import sys\n"
            "for _ in range(3): sys.stdin.readline()\n"
            f"sys.stdout.write({response!r} + '\\n')\n"
            "sys.stdout.flush()\n"
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "gpt-test")

    def test_partial_response_does_not_block_past_timeout(self) -> None:
        result = self.run_resolver(
            "import sys, time\n"
            "for _ in range(3): sys.stdin.readline()\n"
            "sys.stdout.write('{\\\"jsonrpc\\\":')\n"
            "sys.stdout.flush()\n"
            "time.sleep(10)\n",
            timeout="0.15",
        )

        self.assertEqual(result.returncode, 1)
        self.assertIn("model/list", result.stderr)


if __name__ == "__main__":
    unittest.main()
