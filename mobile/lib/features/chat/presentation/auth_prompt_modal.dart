import 'package:flutter/material.dart';
import '../../../core/auth/security_service.dart';
import '../../../shared/theme.dart';

class AuthPromptModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final SecurityService securityService;
  final Function(bool success, String? decryptedPrivateKey) onResult;

  const AuthPromptModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.securityService,
    required this.onResult,
  });

  @override
  State<AuthPromptModal> createState() => _AuthPromptModalState();
}

class _AuthPromptModalState extends State<AuthPromptModal> {
  final TextEditingController _pinController = TextEditingController();
  bool _isPinMode = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthType();
  }

  Future<void> _checkAuthType() async {
    final protectionType = await widget.securityService.getProtectionType();
    if (protectionType == AuthProtectionType.gizmoPin) {
      setState(() => _isPinMode = true);
    } else {
      _triggerBiometricAuth();
    }
  }

  Future<void> _triggerBiometricAuth() async {
    setState(() => _isLoading = true);
    final authenticated = await widget.securityService.authenticateWithDeviceSecurity(
      reason: widget.subtitle,
    );
    setState(() => _isLoading = false);

    if (authenticated) {
      final key = await widget.securityService.getPrivateKeyHardware();
      widget.onResult(true, key);
      if (mounted) Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = 'Authentication failed or canceled.';
        _isPinMode = true; // Fallback to PIN
      });
    }
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _errorMessage = 'Please enter a valid PIN.');
      return;
    }

    setState(() => _isLoading = true);
    final key = await widget.securityService.unwrapPrivateKeyWithGizmoPin(pin);
    setState(() => _isLoading = false);

    if (key != null) {
      widget.onResult(true, key);
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _errorMessage = 'Incorrect PIN code. Access denied.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GizmoTheme.accentAmber.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, size: 40, color: GizmoTheme.accentAmber),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 14, color: GizmoTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (!_isPinMode) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _triggerBiometricAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GizmoTheme.accentBlue,
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.fingerprint, color: Colors.black),
                label: const Text('Scan Biometrics / Face ID', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => setState(() => _isPinMode = true),
                child: const Text('Use Gizmo PIN Instead', style: TextStyle(color: GizmoTheme.accentAmber)),
              ),
            ] else ...[
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '••••••',
                  counterText: '',
                  filled: true,
                  fillColor: GizmoTheme.darkBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GizmoTheme.accentAmber,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Unlock Keys', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],

            TextButton(
              onPressed: () {
                widget.onResult(false, null);
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: GizmoTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
