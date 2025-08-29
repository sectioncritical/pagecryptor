// test_decrypt.js
import fs from "fs";
import { decryptHtml } from "./decrypt.js";

async function main() {
  const params = JSON.parse(fs.readFileSync("test_vectors.json", "utf-8"));

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

