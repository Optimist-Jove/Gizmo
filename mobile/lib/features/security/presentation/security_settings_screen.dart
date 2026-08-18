import 'package:flutter/material.dart';
import '../../../core/auth/security_service.dart';
import '../../../shared/theme.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final SecurityService _securityService = SecurityService();

  bool _reqEncryptAuth = true;
  bool _reqDecryptAuth = true;
  bool _hideNotifications = true;
  bool _disableScreenshots = true;
  bool _appLock = false;
  String _defaultLevel = 'STANDARD';
  AuthProtectionType _protectionType = AuthProtectionType.deviceSecurity;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final reqEncrypt = await _securityService.getRequireAuthBeforeEncrypt();
    final reqDecrypt = await _securityService.getRequireAuthBeforeDecrypt();
    final level = await _securityService.getDefaultSecurityLevel();
    final protType = await _securityService.getProtectionType();

    setState(() {
      _reqEncryptAuth = reqEncrypt;
      _reqDecryptAuth = reqDecrypt;
      _defaultLevel = level;
      _protectionType = protType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security & Privacy Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text('AUTHENTICATION & KEYS', style: TextStyle(color: GizmoTheme.accentBlue, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: GizmoTheme.accentAmber),
                  title: const Text('Protection Method'),
                  subtitle: Text(_protectionType == AuthProtectionType.deviceSecurity ? 'Device Security (Biometrics / Keystore)' : 'Gizmo 6-digit PIN'),
                ),
                SwitchListTile(
                  title: const Text('Require Auth Before Encrypting'),
                  subtitle: const Text('Prompt for biometrics/PIN when sending encrypted message'),
                  value: _reqEncryptAuth,
                  activeColor: GizmoTheme.accentAmber,
                  onChanged: (val) async {
                    setState(() => _reqEncryptAuth = val);
                    await _securityService.setRequireAuthBeforeEncrypt(val);
                  },
                ),
                SwitchListTile(
                  title: const Text('Require Auth Before Decrypting'),
                  subtitle: const Text('Prompt for biometrics/PIN when tapping to view decrypted content'),
                  value: _reqDecryptAuth,
                  activeColor: GizmoTheme.accentAmber,
                  onChanged: (val) async {
                    setState(() => _reqDecryptAuth = val);
                    await _securityService.setRequireAuthBeforeDecrypt(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text('DEFAULT ENCRYPTION LEVEL', style: TextStyle(color: GizmoTheme.accentBlue, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Standard Security (AES-256-GCM)'),
                  value: 'STANDARD',
                  groupValue: _defaultLevel,
                  activeColor: GizmoTheme.accentBlue,
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _defaultLevel = val);
                      await _securityService.setDefaultSecurityLevel(val);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('High Security (ChaCha20-Poly1305)'),
                  value: 'HIGH',
                  groupValue: _defaultLevel,
                  activeColor: GizmoTheme.accentBlue,
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _defaultLevel = val);
                      await _securityService.setDefaultSecurityLevel(val);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Maximum Security (X25519 ECDH + AES-GCM)'),
                  value: 'MAXIMUM',
                  groupValue: _defaultLevel,
                  activeColor: GizmoTheme.accentBlue,
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _defaultLevel = val);
                      await _securityService.setDefaultSecurityLevel(val);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text('PRIVACY & SCREEN PROTECTION', style: TextStyle(color: GizmoTheme.accentBlue, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Hide Message Preview in Notifications'),
                  subtitle: const Text('Encrypted notifications display: 🔒 Encrypted Message'),
                  value: _hideNotifications,
                  activeColor: GizmoTheme.accentEmerald,
                  onChanged: (val) => setState(() => _hideNotifications = val),
                ),
                SwitchListTile(
                  title: const Text('Disable Screenshots'),
                  subtitle: const Text('Enforces FLAG_SECURE on sensitive chat screens'),
                  value: _disableScreenshots,
                  activeColor: GizmoTheme.accentEmerald,
                  onChanged: (val) => setState(() => _disableScreenshots = val),
                ),
                SwitchListTile(
                  title: const Text('App Lock'),
                  subtitle: const Text('Lock Gizmo app when closed or backgrounded'),
                  value: _appLock,
                  activeColor: GizmoTheme.accentEmerald,
                  onChanged: (val) => setState(() => _appLock = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
