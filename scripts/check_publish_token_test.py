import os
from pathlib import Path
import subprocess
import unittest


SCRIPT = Path(__file__).with_name("check_publish_token.sh")


class PublishTokenTest(unittest.TestCase):
    def check_token(self, token):
        env = {"PATH": os.environ["PATH"]}
        if token is not None:
            env["WIPPY_TOKEN"] = token
        return subprocess.run(["bash", str(SCRIPT)], env=env, capture_output=True, text=True)

    def test_missing_token_blocks_publication(self):
        result = self.check_token(None)
        self.assertEqual(result.returncode, 1)
        self.assertIn("WIPPY_TOKEN secret is required", result.stderr)

    def test_empty_token_blocks_publication(self):
        result = self.check_token("")
        self.assertEqual(result.returncode, 1)
        self.assertIn("WIPPY_TOKEN secret is required", result.stderr)

    def test_configured_token_is_not_printed(self):
        result = self.check_token("test-only-publish-token")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")


if __name__ == "__main__":
    unittest.main()
