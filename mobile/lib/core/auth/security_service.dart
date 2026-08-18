import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthProtectionType { deviceSecurity, gizmoPin, none }

class SecurityService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  final _localAuth = LocalAuthentication();
  final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );
  final _aesGcm = AesGcm.with256bits();

  static const _keyPrivateKey = 'gizmo_private_key';
  static const _keyPublicKey = 'gizmo_public_key';
  static const _keyGizmoPinSalt = 'gizmo_pin_salt';
  static const _keyWrappedPrivateKey = 'gizmo_wrapped_private_key';
  static const _keyAuthProtection = 'gizmo_auth_protection_type';

  /// Check if hardware biometrics are available on device
  Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Authenticate user via Device Security (Biometrics / Device PIN / Pattern)
  Future<bool> authenticateWithDeviceSecurity({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Save raw private key directly to Hardware Secure Storage (Android Keystore / iOS Keychain)
  Future<void> savePrivateKeyHardware(String privateKeyBase64, String publicKeyBase64) async {
    await _storage.write(key: _keyPrivateKey, value: privateKeyBase64);
    await _storage.write(key: _keyPublicKey, value: publicKeyBase64);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthProtection, AuthProtectionType.deviceSecurity.name);
  }

  /// Get private key from Hardware Secure Storage
  Future<String?> getPrivateKeyHardware() async {
    return await _storage.read(key: _keyPrivateKey);
  }

  /// Set up Gizmo 6-digit PIN and encrypt/wrap private key using KEK derived from PIN
  Future<void> setupGizmoPin({
    required String pin,
    required String privateKeyBase64,
    required String publicKeyBase64,
  }) async {
    final salt = _aesGcm.newNonce(); // 16 bytes salt/nonce
    final pinSecretKey = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );

    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(privateKeyBase64),
      secretKey: pinSecretKey,
      nonce: nonce,
    );

    final wrappedData = {
      'ciphertext': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    await _storage.write(key: _keyGizmoPinSalt, value: base64Encode(salt));
    await _storage.write(key: _keyWrappedPrivateKey, value: jsonEncode(wrappedData));
    await _storage.write(key: _keyPublicKey, value: publicKeyBase64);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthProtection, AuthProtectionType.gizmoPin.name);
  }

  /// Verify Gizmo PIN and unwrap private key
  Future<String?> unwrapPrivateKeyWithGizmoPin(String pin) async {
    try {
      final saltBase64 = await _storage.read(key: _keyGizmoPinSalt);
      final wrappedJson = await _storage.read(key: _keyWrappedPrivateKey);

      if (saltBase64 == null || wrappedJson == null) return null;

      final salt = base64Decode(saltBase64);
      final wrappedData = jsonDecode(wrappedJson);

      final pinSecretKey = await _pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(pin)),
        nonce: salt,
      );

      final secretBox = SecretBox(
        base64Decode(wrappedData['ciphertext']),
        nonce: base64Decode(wrappedData['nonce']),
        mac: Mac(base64Decode(wrappedData['mac'])),
      );

      final decryptedBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: pinSecretKey,
      );

      return utf8.decode(decryptedBytes);
    } catch (_) {
      return null; // Invalid PIN or decryption failure
    }
  }

  /// Retrieve stored Public Key
  Future<String?> getPublicKey() async {
    return await _storage.read(key: _keyPublicKey);
  }

  /// Get current Protection Type
  Future<AuthProtectionType> getProtectionType() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_keyAuthProtection);
    if (val == AuthProtectionType.gizmoPin.name) return AuthProtectionType.gizmoPin;
    if (val == AuthProtectionType.deviceSecurity.name) return AuthProtectionType.deviceSecurity;
    return AuthProtectionType.none;
  }

  /// Security Settings Preferences
  Future<bool> getRequireAuthBeforeEncrypt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('require_auth_encrypt') ?? true;
  }

  Future<void> setRequireAuthBeforeEncrypt(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('require_auth_encrypt', val);
  }

  Future<bool> getRequireAuthBeforeDecrypt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('require_auth_decrypt') ?? true;
  }

  Future<void> setRequireAuthBeforeDecrypt(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('require_auth_decrypt', val);
  }

  Future<String> getDefaultSecurityLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('default_security_level') ?? 'STANDARD';
  }

  Future<void> setDefaultSecurityLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_security_level', level);
  }
}
