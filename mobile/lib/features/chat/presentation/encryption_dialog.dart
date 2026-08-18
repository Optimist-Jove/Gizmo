import 'package:flutter/material.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../shared/theme.dart';

class EncryptionDialog extends StatefulWidget {
  final SecurityLevel initialLevel;
  final Function(SecurityLevel selectedLevel) onSelected;

  const EncryptionDialog({
    super.key,
    required this.initialLevel,
    required this.onSelected,
  });

  @override
  State<EncryptionDialog> createState() => _EncryptionDialogState();
}

class _EncryptionDialogState extends State<EncryptionDialog> {
  late SecurityLevel _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.lock_clock_outlined, color: GizmoTheme.accentAmber, size: 28),
                SizedBox(width: 12),
                Text('Encrypt Message', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose Security Level',
              style: TextStyle(color: GizmoTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),

            _buildOption(
              level: SecurityLevel.standard,
              title: 'Standard Security',
              subtitle: 'AES-256-GCM symmetric authenticated encryption',
              icon: Icons.shield,
            ),
            const SizedBox(height: 8),

            _buildOption(
              level: SecurityLevel.high,
              title: 'High Security',
              subtitle: 'ChaCha20-Poly1305 high-speed stream cipher',
              icon: Icons.bolt,
            ),
            const SizedBox(height: 8),

            _buildOption(
              level: SecurityLevel.maximum,
              title: 'Maximum Security',
              subtitle: 'X25519 ECDH + HKDF + AES-GCM (Ephemeral Per-Message)',
              icon: Icons.verified_user,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: GizmoTheme.textSecondary)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onSelected(_selectedLevel);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: GizmoTheme.accentAmber),
                  child: const Text('Continue', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required SecurityLevel level,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedLevel == level;
    return InkWell(
      onTap: () => setState(() => _selectedLevel = level),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? GizmoTheme.accentBlue.withOpacity(0.15) : GizmoTheme.darkBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? GizmoTheme.accentBlue : GizmoTheme.surfaceBg,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<SecurityLevel>(
              value: level,
              groupValue: _selectedLevel,
              activeColor: GizmoTheme.accentBlue,
              onChanged: (val) {
                if (val != null) setState(() => _selectedLevel = val);
              },
            ),
            Icon(icon, color: isSelected ? GizmoTheme.accentBlue : GizmoTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? GizmoTheme.accentBlue : GizmoTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: GizmoTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
