#!/usr/bin/env python3
#
# SPDX-License-Identifier: MIT
#
# Copyright 2025 Joseph Kroesche
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import argparse
import base64
import json
import sys
import getpass
from pathlib import Path
import importlib.metadata
import importlib.resources

from Crypto.Cipher import AES
from Crypto.Hash import SHA256
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Random import get_random_bytes
from string import Template


HTML_TEMPLATE = Template(r"""<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<title>Encrypted Page</title>
<body style="font-family: sans-serif; background: #ddd; text-align: center; padding-top: 3em;">
  <div id="gate">
    <h1 style="font-size: 1.2em; font-weight: normal;">Enter password</h1>
    <input id="pw" type="password" style="background: white; padding: 0.5em; border: none; box-shadow: none; display: block; margin: 0.5em auto;">
    <button id="go" style="border: 1px solid #666; background: white; box-shadow: none; padding: 0.4em 1em; margin-top: 0.5em;">Decrypt</button>
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

epilog = """The input HTML file should be a complete HTML file with <head> and
<body>. For security, do not use --password to specify the password. Instead,
let the program ask you for the encryption password. The resulting output file
is a standalone HTML page you can open in a browser. It will ask for the
password, and if correct, will decrypt and display your original page. All
decryption occurs in the browser, nothing is sent off your machine.
"""

def main():
    parser = argparse.ArgumentParser(description="Generate encrypted HTML page",
                                     add_help=False, epilog=epilog)
    parser.add_argument("input_html", help="HTML page to encrypt")
    parser.add_argument("output_html", help="Encrypted HTML file with client side decrypt")
    parser.add_argument("-h", "--help", action="help", help="Show this help message and exit")
    parser.add_argument("--dump-json", metavar="JSONFILE",
                        help="Write encryption parms to JSON file (for test)")
    parser.add_argument("--password", help="Encryption password (insecure, test only)")
    version = importlib.metadata.version("pagecryptor")
    parser.add_argument("--version", action="version", version=f"%(prog)s {version}")
    args = parser.parse_args()

    if args.password:
        pw1 = args.password
        password = pw1.encode()
    else:
        pw1 = getpass.getpass("Enter encryption password: ")
        pw2 = getpass.getpass("Re-enter encryption password: ")
        if pw1 != pw2 or not pw1:
            print("Error: passwords do not match or are empty", file=sys.stderr)
            sys.exit(1)
        password = pw1.encode()

    try:
        plaintext_html = Path(args.input_html).read_text(encoding="utf-8")
    except FileNotFoundError:
        print("Could not find input file:", args.input_html)
        sys.exit(1)

    # Strip enclosing <html> ... </html> completely
    lines = plaintext_html.splitlines()
    # keep only lines that do not contain <html> or </html> (case-insensitive)
    stripped_lines = [
        line for line in lines if "<html" not in line.lower() and
                                  "</html>" not in line.lower() and
                                  "<!doctype" not in line.lower()
    ]
    # make sure last line has a newline
    stripped = "\n".join(stripped_lines) + "\n"
    plaintext_html_bytes = stripped.encode("utf-8")

    params = encrypt_html(plaintext_html_bytes, password)

    # Load decrypt.js and strip `export`
    decrypt_js = importlib.resources.read_text("pagecryptor", "decrypt.js")
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
