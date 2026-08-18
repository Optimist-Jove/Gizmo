import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/crypto/crypto_service.dart';

void main() {
  late CryptoService cryptoService;

  setUp(() {
    cryptoService = CryptoService();
  });

  group('Gizmo CryptoService Tests', () {
    const keyBytes = [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
      17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
    ];

    test('Standard Security (AES-256-GCM) Encrypt & Decrypt Round-Trip', () async {
      const plaintext = 'Meet me at 6 PM for secret meeting.';
      final result = await cryptoService.encryptStandard(plaintext, keyBytes);

      expect(result.securityLevel, SecurityLevel.standard);
      expect(result.ciphertextBase64.isNotEmpty, isTrue);

      final decrypted = await cryptoService.decryptStandard(
        ciphertextBase64: result.ciphertextBase64,
        nonceBase64: result.nonceBase64,
        authTagBase64: result.authTagBase64,
        keyBytes: keyBytes,
      );

      expect(decrypted, equals(plaintext));
    });

    test('High Security (ChaCha20-Poly1305) Encrypt & Decrypt Round-Trip', () async {
      const plaintext = 'High security classification level message.';
      final result = await cryptoService.encryptHigh(plaintext, keyBytes);

      expect(result.securityLevel, SecurityLevel.high);
      expect(result.ciphertextBase64.isNotEmpty, isTrue);

      final decrypted = await cryptoService.decryptHigh(
        ciphertextBase64: result.ciphertextBase64,
        nonceBase64: result.nonceBase64,
        authTagBase64: result.authTagBase64,
        keyBytes: keyBytes,
      );

      expect(decrypted, equals(plaintext));
    });

    test('Maximum Security (X25519 ECDH + HKDF + AES-GCM) Round-Trip', () async {
      const plaintext = 'Top secret maximum security document.';

      // Generate recipient keypair
      final recipientKeyPair = await cryptoService.generateX25519KeyPair();
      final recipientPubKeyBase64 = await cryptoService.exportPublicKeyBase64(recipientKeyPair);
      final recipientPrivKeyBase64 = await cryptoService.exportPrivateKeyBase64(recipientKeyPair);

      // Sender encrypts message using recipient's public key
      final result = await cryptoService.encryptMaximum(
        plaintext: plaintext,
        recipientPublicKeyBase64: recipientPubKeyBase64,
      );

      expect(result.securityLevel, SecurityLevel.maximum);
      expect(result.ephemeralPublicKeyBase64, isNotNull);

      // Recipient decrypts message using recipient's private key + sender's ephemeral public key
      final importedRecipientKeyPair = await cryptoService.importKeyPairFromPrivateKeyBase64(recipientPrivKeyBase64);
      final decrypted = await cryptoService.decryptMaximum(
        ciphertextBase64: result.ciphertextBase64,
        nonceBase64: result.nonceBase64,
        authTagBase64: result.authTagBase64,
        ephemeralPublicKeyBase64: result.ephemeralPublicKeyBase64!,
        recipientPrivateKeyPair: importedRecipientKeyPair,
      );

      expect(decrypted, equals(plaintext));
    });

    test('Safety Number Computation generates 60-digit formatted string', () async {
      final keyPairA = await cryptoService.generateX25519KeyPair();
      final keyPairB = await cryptoService.generateX25519KeyPair();

      final pubA = await cryptoService.exportPublicKeyBase64(keyPairA);
      final pubB = await cryptoService.exportPublicKeyBase64(keyPairB);

      final safetyNumberAB = await cryptoService.computeSafetyNumber(pubA, pubB);
      final safetyNumberBA = await cryptoService.computeSafetyNumber(pubB, pubA);

      // Symmetrical regardless of order
      expect(safetyNumberAB, equals(safetyNumberBA));
      expect(safetyNumberAB.split(' ').length, equals(12)); // 12 blocks of 5 digits
    });
  });
}
