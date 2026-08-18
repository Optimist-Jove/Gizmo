import 'dart:convert';
import 'package:cryptography/cryptography.dart';

enum SecurityLevel {
  standard, // AES-256-GCM
  high,     // ChaCha20-Poly1305
  maximum   // X25519-ECDH + HKDF-SHA256 + AES-256-GCM
}

class EncryptionResult {
  final String ciphertextBase64;
  final String nonceBase64;
  final String authTagBase64;
  final SecurityLevel securityLevel;
  final String? ephemeralPublicKeyBase64;

  EncryptionResult({
    required this.ciphertextBase64,
    required this.nonceBase64,
    required this.authTagBase64,
    required this.securityLevel,
    this.ephemeralPublicKeyBase64,
  });

  Map<String, dynamic> toJson() => {
        'ciphertext': ciphertextBase64,
        'nonce': nonceBase64,
        'authTag': authTagBase64,
        'securityLevel': securityLevel.name.toUpperCase(),
        'ephemeralPublicKey': ephemeralPublicKeyBase64,
      };
}

class CryptoService {
  final _aesGcm = AesGcm.with256bits();
  final _chaCha20 = Chacha20.poly1305Aead();
  final _x25519 = X25519();
  final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// Generate a long-term X25519 key pair for the user
  Future<SimpleKeyPair> generateX25519KeyPair() async {
    return await _x25519.newKeyPair();
  }

  /// Export public key as base64 string
  Future<String> exportPublicKeyBase64(SimpleKeyPair keyPair) async {
    final publicKey = await keyPair.extractPublicKey();
    return base64Encode(publicKey.bytes);
  }

  /// Export private key as base64 string (for local secure hardware storage)
  Future<String> exportPrivateKeyBase64(SimpleKeyPair keyPair) async {
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    return base64Encode(privateKeyBytes);
  }

  /// Reconstruct KeyPair from private key bytes
  Future<SimpleKeyPair> importKeyPairFromPrivateKeyBase64(String privateKeyBase64) async {
    final bytes = base64Decode(privateKeyBase64);
    return await _x25519.newKeyPairFromSeed(bytes);
  }

  /// Standard Security: AES-256-GCM with shared key or derived key
  Future<EncryptionResult> encryptStandard(String plaintext, List<int> keyBytes) async {
    final secretKey = SecretKey(keyBytes);
    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    return EncryptionResult(
      ciphertextBase64: base64Encode(secretBox.cipherText),
      nonceBase64: base64Encode(secretBox.nonce),
      authTagBase64: base64Encode(secretBox.mac.bytes),
      securityLevel: SecurityLevel.standard,
    );
  }

  Future<String> decryptStandard({
    required String ciphertextBase64,
    required String nonceBase64,
    required String authTagBase64,
    required List<int> keyBytes,
  }) async {
    final secretKey = SecretKey(keyBytes);
    final secretBox = SecretBox(
      base64Decode(ciphertextBase64),
      nonce: base64Decode(nonceBase64),
      mac: Mac(base64Decode(authTagBase64)),
    );

    final decryptedBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decryptedBytes);
  }

  /// High Security: ChaCha20-Poly1305
  Future<EncryptionResult> encryptHigh(String plaintext, List<int> keyBytes) async {
    final secretKey = SecretKey(keyBytes);
    final nonce = _chaCha20.newNonce();
    final secretBox = await _chaCha20.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    return EncryptionResult(
      ciphertextBase64: base64Encode(secretBox.cipherText),
      nonceBase64: base64Encode(secretBox.nonce),
      authTagBase64: base64Encode(secretBox.mac.bytes),
      securityLevel: SecurityLevel.high,
    );
  }

  Future<String> decryptHigh({
    required String ciphertextBase64,
    required String nonceBase64,
    required String authTagBase64,
    required List<int> keyBytes,
  }) async {
    final secretKey = SecretKey(keyBytes);
    final secretBox = SecretBox(
      base64Decode(ciphertextBase64),
      nonce: base64Decode(nonceBase64),
      mac: Mac(base64Decode(authTagBase64)),
    );

    final decryptedBytes = await _chaCha20.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decryptedBytes);
  }

  /// Maximum Security: Hybrid E2EE (X25519 ECDH + HKDF + AES-256-GCM)
  Future<EncryptionResult> encryptMaximum({
    required String plaintext,
    required String recipientPublicKeyBase64,
  }) async {
    // 1. Generate ephemeral X25519 keypair for this specific message
    final ephemeralKeyPair = await _x25519.newKeyPair();
    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

    // 2. Compute ECDH shared secret with recipient's static public key
    final recipientPublicKey = SimplePublicKey(
      base64Decode(recipientPublicKeyBase64),
      type: KeyPairType.x25519,
    );

    final sharedSecretKey = await _x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: recipientPublicKey,
    );

    // 3. Derive symmetric AES key via HKDF SHA-256
    final derivedSecretKey = await _hkdf.deriveKey(
      secretKey: sharedSecretKey,
      info: utf8.encode('Gizmo-Maximum-Security-v1'),
    );

    // 4. Encrypt message using AES-256-GCM
    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: derivedSecretKey,
      nonce: nonce,
    );

    return EncryptionResult(
      ciphertextBase64: base64Encode(secretBox.cipherText),
      nonceBase64: base64Encode(secretBox.nonce),
      authTagBase64: base64Encode(secretBox.mac.bytes),
      securityLevel: SecurityLevel.maximum,
      ephemeralPublicKeyBase64: base64Encode(ephemeralPublicKey.bytes),
    );
  }

  Future<String> decryptMaximum({
    required String ciphertextBase64,
    required String nonceBase64,
    required String authTagBase64,
    required String ephemeralPublicKeyBase64,
    required SimpleKeyPair recipientPrivateKeyPair,
  }) async {
    final ephemeralPublicKey = SimplePublicKey(
      base64Decode(ephemeralPublicKeyBase64),
      type: KeyPairType.x25519,
    );

    // 1. Compute ECDH shared secret using recipient's static private key & sender's ephemeral public key
    final sharedSecretKey = await _x25519.sharedSecretKey(
      keyPair: recipientPrivateKeyPair,
      remotePublicKey: ephemeralPublicKey,
    );

    // 2. Derive symmetric key via HKDF SHA-256
    final derivedSecretKey = await _hkdf.deriveKey(
      secretKey: sharedSecretKey,
      info: utf8.encode('Gizmo-Maximum-Security-v1'),
    );

    // 3. Decrypt ciphertext
    final secretBox = SecretBox(
      base64Decode(ciphertextBase64),
      nonce: base64Decode(nonceBase64),
      mac: Mac(base64Decode(authTagBase64)),
    );

    final decryptedBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: derivedSecretKey,
    );

    return utf8.decode(decryptedBytes);
  }

  /// Generate 60-digit Safety Number for identity verification between two users
  Future<String> computeSafetyNumber(String pubKeyA, String pubKeyB) async {
    final sortedKeys = [pubKeyA, pubKeyB]..sort();
    final combinedBytes = utf8.encode('${sortedKeys[0]}::${sortedKeys[1]}');

    final sha256 = Sha256();
    final hash = await sha256.hash(combinedBytes);
    
    // Format hash into 12 blocks of 5 decimal digits
    final bigInt = BigInt.parse(
      hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );

    final digits = bigInt.toString().padLeft(60, '0').substring(0, 60);
    final blocks = <String>[];
    for (int i = 0; i < 60; i += 5) {
      blocks.add(digits.substring(i, i + 5));
    }

    return blocks.join(' ');
  }
}
