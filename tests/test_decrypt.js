// test_decrypt.js

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

