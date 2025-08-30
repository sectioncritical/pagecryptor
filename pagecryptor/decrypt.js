// decrypt.js
// This function only:
// Copyright 2025 Joseph Kroesche
// Subject to MIT license: https://choosealicense.com/licenses/mit/
//
export async function decryptHtml(password, ciphertextB64, tagB64, ivB64, saltB64, iterations) {
  const enc = new TextEncoder();
  const dec = new TextDecoder();

  function b64ToBytes(b64) {
    const bin = atob(b64);
    const out = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
  }

  function concatBytes(a, b) {
    const out = new Uint8Array(a.length + b.length);
    out.set(a, 0);
    out.set(b, a.length);
    return out;
  }

  async function deriveAesGcmKey(passwordBytes, saltBytes, iterations) {
    const baseKey = await crypto.subtle.importKey(
      "raw",
      passwordBytes,
      "PBKDF2",
      false,
      ["deriveKey"]
    );
    return crypto.subtle.deriveKey(
      {
        name: "PBKDF2",
        salt: saltBytes,
        iterations: iterations,
        hash: "SHA-256"
      },
      baseKey,
      { name: "AES-GCM", length: 256 },
      false,
      ["decrypt"]
    );
  }

  const salt = b64ToBytes(saltB64);
  const iv = b64ToBytes(ivB64);
  const ct = b64ToBytes(ciphertextB64);
  const tag = b64ToBytes(tagB64);
  const ctPlusTag = concatBytes(ct, tag);

  const key = await deriveAesGcmKey(enc.encode(password), salt, iterations);

  const plainBuf = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: iv, tagLength: 128 },
    key,
    ctPlusTag.buffer
  );

  return dec.decode(new Uint8Array(plainBuf));
}
