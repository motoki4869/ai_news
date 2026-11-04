import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("audio_script", ROOT / "scripts/generate_audio_script.py")
audio_script = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(audio_script)
TURNS = [{"speaker": "listener", "text": "何が発表されたのですか？"},
         {"speaker": "explainer", "text": "新しいAIが発表されました。"}]


class AudioScriptTests(unittest.TestCase):
    def test_render_preserves_turns_and_voice_roles(self):
        actual = audio_script.render_script({"turns": TURNS})
        self.assertIn("聞き手（女性）：何が発表されたのですか？", actual)
        self.assertIn("解説役（男性）：新しいAIが発表されました。", actual)
        self.assertLess(actual.index("聞き手"), actual.index("解説役"))

    def test_rejects_invalid_dialogue(self):
        for payload in [None, {}, {"turns": []}, {"turns": TURNS[:1]},
                        {"turns": list(reversed(TURNS))},
                        {"turns": [TURNS[0], TURNS[0]]},
                        {"turns": [TURNS[0], {"speaker": "explainer", "text": " "}]}]:
            with self.subTest(payload=payload), self.assertRaises(ValueError):
                audio_script.render_script(payload)

    def run_pipeline(self, mode):
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            (repo / "scripts/lib").mkdir(parents=True)
            (repo / "everyday_news").mkdir()
            (repo / "auth").mkdir()
            (repo / "auth/auth.json").write_text("{}")
            for name in ["generate_audio_script.py", "generate_audio_data.py",
                         "generate_notebooklm_audio.sh", "lib/codex_fallback.sh"]:
                shutil.copy2(ROOT / "scripts" / name, repo / "scripts" / name)
            (repo / "scripts/notebooklm_audio.env").write_text('NOTEBOOKLM_NOTEBOOK_ID="test-notebook"\n')
            (repo / "everyday_news/202611.md").write_text(
                "## 2026-11-05\n\n元の記事本文だけの文字列\n", encoding="utf-8")
            codex = repo / "fake-codex"
            codex.write_text("""#!/usr/bin/env python3
import json, os, pathlib, sys
if os.environ['SCRIPT_MODE'] == 'fail': sys.exit(1)
workspace = pathlib.Path(sys.argv[sys.argv.index('-C') + 1])
assert '元の記事本文' in (workspace / 'source.md').read_text()
assert not (workspace / 'scripts/notebooklm_audio.env').exists()
turns = [{'speaker':'listener','text':'何が発表されたのですか？'},
         {'speaker':'explainer','text':'新しいAIが発表されました。'}]
if os.environ['SCRIPT_MODE'] == 'invalid': turns.reverse()
(workspace / 'dialogue.json').write_text(json.dumps({'turns':turns}))
""")
            codex.chmod(0o755)
            nlm = repo / "fake-nlm"
            nlm.write_text("""#!/usr/bin/env python3
import os, pathlib, sys
if sys.argv[1] == 'login': sys.exit(0)
if sys.argv[1:3] == ['source', 'add']:
    source = pathlib.Path(sys.argv[sys.argv.index('--file') + 1])
    pathlib.Path(os.environ['CAPTURE']).write_text(source.read_text())
    sys.exit(1)  # アップロード直前の入力確認で止め、外部サービスは呼ばない。
raise SystemExit('予期しない呼び出し')
""")
            nlm.chmod(0o755)
            capture = repo / "captured.md"
            env = dict(os.environ, CODEX_BIN=str(codex), NODE_BIN="/usr/bin/true",
                       CODEX_FALLBACK_MODEL="gpt-6-sol", CODEX_HOME=str(repo / "auth"),
                       AI_NEWS_CODEX_RUNTIME_BASE=str(repo / "runtime"),
                       NLM_BIN=str(nlm), CAPTURE=str(capture), SCRIPT_MODE=mode)
            # 親プロセスのNotebookLM設定があってもテスト用設定だけを使う。
            env["NOTEBOOKLM_AUDIO_ENV"] = str(repo / "scripts/notebooklm_audio.env")
            result = subprocess.run(["bash", str(repo / "scripts/generate_notebooklm_audio.sh"),
                                     "2026-11-05"], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            saved = repo / "logs/audio-scripts/2026-11-05.md"
            return (capture.read_text() if capture.exists() else None,
                    saved.read_text() if saved.exists() else None,
                    result.stdout + result.stderr)

    def test_notebooklm_receives_only_generated_script(self):
        captured, saved, _ = self.run_pipeline("ok")
        self.assertIn("聞き手（女性）", captured)
        self.assertNotIn("元の記事本文", captured)
        self.assertEqual(captured, saved)

    def test_codex_failure_does_not_upload_articles(self):
        captured, saved, output = self.run_pipeline("fail")
        self.assertIsNone(captured)
        self.assertIsNone(saved)
        self.assertIn("音声生成を見送ります", output)

    def test_invalid_script_does_not_upload(self):
        captured, saved, output = self.run_pipeline("invalid")
        self.assertIsNone(captured)
        self.assertIsNone(saved)
        self.assertIn("順番が不正", output)


if __name__ == "__main__":
    unittest.main()
