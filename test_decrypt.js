// test_decrypt.js
import fs from "fs";
import { decryptHtml } from "./decrypt.js";

async function main() {
  const file = process.argv[2];
  if (!file) {
    console.error("Usage: node test_decrypt.js <test-vector.json>");
    process.exit(1);
  }
  const params = JSON.parse(fs.readFileSync(file, "utf-8"));

  try {
    const plaintext = await decryptHtml(
      params.password,
      params.ciphertext_b64,
      params.tag_b64,
      params.iv_b64,
      params.salt_b64,
      params.iterations
    );
    console.log("Decrypted OK:");
    console.log(plaintext);
  } catch (e) {
    console.error("Decryption failed:", e);
  }
}

main();

