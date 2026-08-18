import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/auth/security_service.dart';
import '../../../shared/theme.dart';

class SafetyNumberScreen extends StatefulWidget {
  final String contactName;
  final String contactPublicKey;

  const SafetyNumberScreen({
    super.key,
    required this.contactName,
    required this.contactPublicKey,
  });

  @override
  State<SafetyNumberScreen> createState() => _SafetyNumberScreenState();
}

class _SafetyNumberScreenState extends State<SafetyNumberScreen> {
  final CryptoService _cryptoService = CryptoService();
  final SecurityService _securityService = SecurityService();

  String? _safetyNumber;
  bool _isVerified = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _computeSafetyNumber();
  }

  Future<void> _computeSafetyNumber() async {
    final myPubKey = await _securityService.getPublicKey();
    if (myPubKey != null && widget.contactPublicKey.isNotEmpty) {
      final number = await _cryptoService.computeSafetyNumber(myPubKey, widget.contactPublicKey);
      setState(() {
        _safetyNumber = number;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Safety Number - ${widget.contactName}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user, color: GizmoTheme.accentEmerald, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        _isVerified ? '✔ Verified Contact' : 'Compare Safety Number',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _isVerified ? GizmoTheme.accentEmerald : GizmoTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'To verify end-to-end security with ${widget.contactName}, compare the numbers below or scan their QR code.',
                        style: const TextStyle(color: GizmoTheme.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // QR Code
                      if (_safetyNumber != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: _safetyNumber!,
                            version: QrVersions.auto,
                            size: 180.0,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // 60-digit Fingerprint Blocks
                      if (_safetyNumber != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: GizmoTheme.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: GizmoTheme.surfaceBg),
                          ),
                          child: Text(
                            _safetyNumber!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              height: 1.6,
                              fontFamily: 'monospace',
                              color: GizmoTheme.accentAmber,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 28),

                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _isVerified = !_isVerified);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isVerified ? GizmoTheme.cardBg : GizmoTheme.accentEmerald,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(_isVerified ? Icons.check_circle : Icons.verified, color: _isVerified ? GizmoTheme.accentEmerald : Colors.black),
                        label: Text(
                          _isVerified ? 'Marked as Verified' : 'Mark as Verified',
                          style: TextStyle(color: _isVerified ? GizmoTheme.accentEmerald : Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
