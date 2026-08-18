import 'package:flutter/material.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/auth/security_service.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/theme.dart';
import '../../chat/presentation/conversations_screen.dart';

class SecuritySetupScreen extends StatefulWidget {
  final String userId;
  final String displayName;
  final String phoneNumber;

  const SecuritySetupScreen({
    super.key,
    required this.userId,
    required this.displayName,
    required this.phoneNumber,
  });

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final CryptoService _cryptoService = CryptoService();
  final SecurityService _securityService = SecurityService();
  final ApiService _apiService = ApiService();
  final TextEditingController _pinController = TextEditingController();

  int _selectedOption = 1; // 1: Device Security, 2: Gizmo PIN
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _completeSetup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Generate long-term X25519 key pair for user
      final keyPair = await _cryptoService.generateX25519KeyPair();
      final pubKeyBase64 = await _cryptoService.exportPublicKeyBase64(keyPair);
      final privKeyBase64 = await _cryptoService.exportPrivateKeyBase64(keyPair);

      // 2. Save private key according to user's selected protection method
      if (_selectedOption == 1) {
        // Hardware Secure Storage (Keystore / Keychain)
        await _securityService.savePrivateKeyHardware(privKeyBase64, pubKeyBase64);
      } else {
        // Gizmo PIN wrapped key
        final pin = _pinController.text.trim();
        if (pin.length < 4) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Please enter a 4 to 6 digit PIN.';
          });
          return;
        }
        await _securityService.setupGizmoPin(
          pin: pin,
          privateKeyBase64: privKeyBase64,
          publicKeyBase64: pubKeyBase64,
        );
      }

      // 3. Upload public key to backend registry
      await _apiService.registerProfile(
        displayName: widget.displayName,
        publicKey: pubKeyBase64,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationsScreen(
            currentUserId: widget.userId,
            currentUserName: widget.displayName,
            currentUserPhone: widget.phoneNumber,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Security setup failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Setup')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How would you like to protect encrypted messages?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gizmo requires authentication before unlocking your private encryption keys to encrypt or decrypt messages.',
                style: TextStyle(color: GizmoTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              // Option 1: Device Security
              InkWell(
                onTap: () => setState(() => _selectedOption = 1),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedOption == 1 ? GizmoTheme.accentBlue.withOpacity(0.15) : GizmoTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedOption == 1 ? GizmoTheme.accentBlue : GizmoTheme.surfaceBg,
                      width: _selectedOption == 1 ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio<int>(
                            value: 1,
                            groupValue: _selectedOption,
                            activeColor: GizmoTheme.accentBlue,
                            onChanged: (v) => setState(() => _selectedOption = v!),
                          ),
                          const Icon(Icons.fingerprint, color: GizmoTheme.accentBlue, size: 28),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Option 1 (Recommended)\nUse Device Security',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 48, top: 4),
                        child: Text(
                          'Protects keys using Android Keystore / Apple Secure Enclave.\nSupported: Fingerprint, Face ID, Device PIN / Pattern.',
                          style: TextStyle(fontSize: 13, color: GizmoTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Option 2: Gizmo PIN
              InkWell(
                onTap: () => setState(() => _selectedOption = 2),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedOption == 2 ? GizmoTheme.accentAmber.withOpacity(0.15) : GizmoTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedOption == 2 ? GizmoTheme.accentAmber : GizmoTheme.surfaceBg,
                      width: _selectedOption == 2 ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio<int>(
                            value: 2,
                            groupValue: _selectedOption,
                            activeColor: GizmoTheme.accentAmber,
                            onChanged: (v) => setState(() => _selectedOption = v!),
                          ),
                          const Icon(Icons.pin, color: GizmoTheme.accentAmber, size: 28),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Option 2\nCreate Gizmo Security PIN',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 48, top: 4),
                        child: Text(
                          'Derives a 255-bit KEK (Key Encryption Key) using PBKDF2 (100,000 iterations) to wrap your private key.',
                          style: TextStyle(fontSize: 13, color: GizmoTheme.textSecondary),
                        ),
                      ),
                      if (_selectedOption == 2) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 48, right: 16),
                          child: TextField(
                            controller: _pinController,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              labelText: 'Create 6-digit Gizmo PIN',
                              filled: true,
                              fillColor: GizmoTheme.darkBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: _isLoading ? null : _completeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GizmoTheme.accentBlue,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Complete Security Setup', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
