"""Packaging invariants protect against republishing classic or misidentified builds."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from finish_web import finish
from validate_web import fingerprints, validate

SHA = "a" * 40
ENGINE = "4.7.2.stable.official.ed1daf0bf"


class WebBuildTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.output = Path(self.temp.name)
        (self.output / "index.html").write_text('<html><title>Game</title><body><script src="index.js"></script><script>new Engine({"mainPack":"index.pck"})</script></body></html>')
        (self.output / "index.js").write_text("/* engine */")
        (self.output / "index.wasm").write_bytes(b"\x00asm\x01\x00\x00\x00")
        (self.output / "index.pck").write_bytes(b"GDPCfixture")
        (self.output / "classic.html").write_text("classic")
        finish(self.output, SHA, ENGINE)

    def info(self, **changes):
        path = self.output / "build-info.json"
        data = json.loads(path.read_text())
        data.update(changes)
        path.write_text(json.dumps(data))

    def test_identified_complete_export(self):
        self.assertEqual(validate(self.output, SHA, "4.7.2")["source_commit"], SHA)
        html = (self.output / "index.html").read_text()
        self.assertIn("Build " + SHA[:12], html)
        self.assertIn("pointerlockchange", html)
        self.assertIn("classic.html", html)

    def test_stale_commit_rejected(self):
        with self.assertRaisesRegex(ValueError, "commit"): validate(self.output, "b" * 40)

    def test_engine_mismatch_rejected(self):
        with self.assertRaisesRegex(ValueError, "engine"): validate(self.output, SHA, "4.6.3")

    def test_missing_wasm_rejected(self):
        (self.output / "index.wasm").unlink()
        with self.assertRaisesRegex(ValueError, "Missing"): validate(self.output)

    def test_tampered_asset_rejected(self):
        (self.output / "index.pck").write_bytes(b"GDPCmodified")
        with self.assertRaisesRegex(ValueError, "hash"): validate(self.output)

    def test_classic_root_rejected_even_with_updated_hash(self):
        (self.output / "index.html").write_text("<html>Classic game</html>")
        self.info(files=fingerprints(self.output))
        with self.assertRaisesRegex(ValueError, "entry point"): validate(self.output)

    def test_threaded_build_rejected(self):
        self.info(threads=True)
        with self.assertRaisesRegex(ValueError, "threaded"): validate(self.output)

    def test_invalid_commit_rejected_at_packaging(self):
        with self.assertRaisesRegex(ValueError, "SHA"): finish(self.output, "local", ENGINE)

    def test_false_clean_source_rejected(self):
        self.info(clean_source=False)
        with self.assertRaisesRegex(ValueError, "committed"): validate(self.output)

    def test_invalid_wasm_header_rejected(self):
        (self.output / "index.wasm").write_bytes(b"not wasm")
        self.info(files=fingerprints(self.output))
        with self.assertRaisesRegex(ValueError, "WASM"): validate(self.output)


if __name__ == "__main__": unittest.main()
