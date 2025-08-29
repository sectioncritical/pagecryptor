#!/usr/bin/env python3
import argparse
import base64
import json
import sys
from getpass import getpass
from pathlib import Path

from Crypto.Cipher import AES
from Crypto.Hash import SHA256
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Random import get_random_bytes
from string import Template


HTML_TEMPLATE = Template(r"""<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<title>Encrypted Page</title>
<body style="font-family: sans-serif; background: #eee; text-align: center; padding-top: 3em;">
  <div id="gate">
    <h1 style="font-size: 1.2em; font-weight: normal;">Enter password</h1>
    <input id="pw" type="password" style="background: white; padding: 0.5em;">
    <button id="go">Decrypt</button>
    <div id="msg" style="color:red; margin-top:0.5em;"></div>
  </div>
<script>
$decrypt_js

(async () => {
  const params = {
    iterations: $iterations,
    salt_b64: "$salt_b64",
    iv_b64: "$iv_b64",
    ciphertext_b64: "$ciphertext_b64",
    tag_b64: "$tag_b64"
  };

  async function onGo() {
    const pw = document.getElementById("pw").value;
    try {
      const html = await decryptHtml(
        pw,
        params.ciphertext_b64,
        params.tag_b64,
        params.iv_b64,
        params.salt_b64,
        params.iterations
      );
      document.documentElement.innerHTML = html;
    } catch (e) {
      document.getElementById("msg").textContent = "Decryption failed.";
    }
  }

  document.getElementById("go").addEventListener("click", onGo);
})();
</script>
</body>
</html>
""")


def encrypt_html(plaintext_html: bytes, password: bytes, iterations: int = 200_000):
    salt = get_random_bytes(16)
    iv = get_random_bytes(12)
    key = PBKDF2(password=password, salt=salt, dkLen=32, count=iterations, hmac_hash_module=SHA256)
    cipher = AES.new(key, AES.MODE_GCM, nonce=iv)
    ciphertext, tag = cipher.encrypt_and_digest(plaintext_html)

    return {
        "iterations": iterations,
        "salt_b64": base64.b64encode(salt).decode(),
        "iv_b64": base64.b64encode(iv).decode(),
        "ciphertext_b64": base64.b64encode(ciphertext).decode(),
        "tag_b64": base64.b64encode(tag).decode(),
    }


def main():
    parser = argparse.ArgumentParser(description="Generate encrypted HTML page.")
    parser.add_argument("input_html")
    parser.add_argument("output_html")
    parser.add_argument("--dump-json", help="Write encryption parameters to a JSON file.")
    parser.add_argument("--decrypt-js", default="decrypt.js", help="Path to decrypt.js file.")
    args = parser.parse_args()

    pw1 = getpass("Enter encryption password: ")
    pw2 = getpass("Re-enter encryption password: ")
    if pw1 != pw2 or not pw1:
        print("Error: passwords do not match or are empty", file=sys.stderr)
        sys.exit(1)
    password = pw1.encode()

    plaintext_html = Path(args.input_html).read_text(encoding="utf-8")

    # Strip enclosing <html> ... </html>
    # This keeps everything inside for replacement at runtime
    stripped = plaintext_html.strip()
    if stripped.lower().startswith("<html"):
        start = stripped.find(">") + 1
        end = stripped.rfind("</html>")
        if end != -1:
            stripped = stripped[start:end]
    plaintext_html_bytes = stripped.encode("utf-8")

    params = encrypt_html(plaintext_html_bytes, password)

    # Load decrypt.js and strip `export`
    decrypt_js = Path(args.decrypt_js).read_text(encoding="utf-8")
    decrypt_js = decrypt_js.replace("export ", "")

    html_out = HTML_TEMPLATE.substitute(decrypt_js=decrypt_js, **params)
    Path(args.output_html).write_text(html_out, encoding="utf-8")

    if args.dump_json:
        Path(args.dump_json).write_text(
            json.dumps({**params, "password": pw1}, indent=2),
            encoding="utf-8"
        )

    print(f"Encrypted page written to {args.output_html}")
    if args.dump_json:
        print(f"JSON test vectors written to {args.dump_json}")


if __name__ == "__main__":
    main()
