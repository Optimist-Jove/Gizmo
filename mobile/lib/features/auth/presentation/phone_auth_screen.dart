import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/theme.dart';
import 'security_setup_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '+1234567890');
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(text: 'Alice');
  final ApiService _apiService = ApiService();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _debugOtp;
  String? _errorMessage;

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !phone.startsWith('+')) {
      setState(() => _errorMessage = 'Enter valid E.164 phone number (e.g. +1234567890)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.sendOtp(phone);
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
        _debugOtp = res['debugOtp'];
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send OTP. Check backend server connection.';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    final displayName = _nameController.text.trim();

    if (otp.isEmpty || displayName.isEmpty) {
      setState(() => _errorMessage = 'Please provide OTP and your Display Name.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.verifyOtp(phone, otp);
      if (res['accessToken'] != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SecuritySetupScreen(
              userId: res['user']['id'],
              displayName: displayName,
              phoneNumber: phone,
            ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid OTP code.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: GizmoTheme.accentBlue.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Gizmo Messaging',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Secure End-to-End Encrypted Mobile Messaging',
                    style: TextStyle(color: GizmoTheme.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

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

                  if (!_isOtpSent) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        filled: true,
                        fillColor: GizmoTheme.cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GizmoTheme.accentBlue,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('Send Verification Code', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ] else ...[
                    if (_debugOtp != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: GizmoTheme.accentAmber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Debug OTP Code: $_debugOtp', style: const TextStyle(color: GizmoTheme.accentAmber, fontWeight: FontWeight.bold)),
                      ),

                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: GizmoTheme.cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: '6-digit OTP Code',
                        prefixIcon: const Icon(Icons.vibration),
                        filled: true,
                        fillColor: GizmoTheme.cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GizmoTheme.accentEmerald,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('Verify & Continue', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
