import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class VaultService {
  static const List<String> _bannedPins = [
    '1111',
    '1234',
    '0000',
    '2580',
    '4321'
  ];

  /// Validates a PIN — rejects common patterns
  static String? validatePin(String pin) {
    if (pin.length != 4) return 'PIN must be 4 digits';
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) return 'PIN must be numeric';
    if (_bannedPins.contains(pin)) return 'Too simple. Choose a stronger PIN.';
    return null; // Valid
  }

  /// Derives a 32-byte AES key from the PIN
  static Key _deriveKey(String pin) {
    // Hash the PIN with SHA-256 to get a consistent 32-byte key
    final hash = sha256.convert(utf8.encode('vault_key_$pin')).bytes;
    return Key.fromBase64(base64.encode(hash));
  }

  static final _iv = IV.fromLength(16);

  /// Encrypts plaintext using AES with the PIN-derived key
  static String encrypt(String plaintext, String pin) {
    if (plaintext.isEmpty) return '';
    final key = _deriveKey(pin);
    final encrypter = Encrypter(AES(key));
    return encrypter.encrypt(plaintext, iv: _iv).base64;
  }

  /// Decrypts ciphertext using AES with the PIN-derived key
  static String decrypt(String ciphertext, String pin) {
    if (ciphertext.isEmpty) return '';
    try {
      final key = _deriveKey(pin);
      final encrypter = Encrypter(AES(key));
      return encrypter.decrypt64(ciphertext, iv: _iv);
    } catch (_) {
      return '*** Decryption Failed ***';
    }
  }
}
