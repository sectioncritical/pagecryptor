// test_decrypt.js
//
// SPDX-License-Identifier: MIT
//
// MIT License
//
// Copyright (c) 2025 Joseph Kroesche
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// this test program is used to verify the decrypt function

import fs from "fs";

async function main() {
  const decryptJsPath = process.argv[2];
  const paramFile = process.argv[3];
  const password = process.argv[4];
  const outputFile = process.argv[5];

  if (!decryptJsPath || !paramFile || !password || !outputFile) {
    console.error("Usage: node test_decrypt.js <path-to-decrypt.js> <params.json> <password> <output-file>");
    process.exit(1);
  }

  // dynamically import the decryptHtml function from the specified decrypt.js
  const { decryptHtml } = await import(`file://${decryptJsPath}`);

  const params = JSON.parse(fs.readFileSync(paramFile, "utf-8"));

  try {
    const plaintext = await decryptHtml(
      password,
      params.ciphertext_b64,
      params.tag_b64,
      params.iv_b64,
      params.salt_b64,
      params.iterations
    );

    fs.writeFileSync(outputFile, plaintext, "utf-8");
    console.log("Decrypted OK: output saved to " + outputFile);
  } catch (e) {
    console.error("Decryption failed:", e);
    process.exit(1);
  }
}

main().catch((e) => {
  console.error("Unexpected error:", e);
  process.exit(1);
});

