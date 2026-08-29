import importlib.util
import json
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT / "scripts" / "generate_audio_data.py"
SPEC = importlib.util.spec_from_file_location("generate_audio_data", SCRIPT)
generate_audio_data = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(generate_audio_data)


def artifact_payload(title):
    return json.dumps({
        "artifacts": [{
            "id": "artifact-1",
            "type": "audio",
            "status": "completed",
            "title": title,
        }]
    })


class TestNotebookLmAudioTitle(unittest.TestCase):
    def test_rejects_placeholder_title(self):
        extractor = getattr(generate_audio_data, "extract_artifact_title", None)
        self.assertIsNotNone(extractor)

        actual = extractor(artifact_payload("AIニュース音声"), "artifact-1")

        self.assertEqual(actual, "")

    def test_accepts_final_title(self):
        extractor = getattr(generate_audio_data, "extract_artifact_title", None)
        self.assertIsNotNone(extractor)

        actual = extractor(artifact_payload("75兆円の要塞と手元のAI"), "artifact-1")

        self.assertEqual(actual, "75兆円の要塞と手元のAI")


if __name__ == "__main__":
    unittest.main()
