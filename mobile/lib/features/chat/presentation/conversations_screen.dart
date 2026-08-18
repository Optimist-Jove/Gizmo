import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/theme.dart';
import 'chat_screen.dart';
import '../../security/presentation/security_settings_screen.dart';

class ConversationsScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserPhone;

  const ConversationsScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserPhone,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final list = await _apiService.getAllUsers();
      setState(() {
        _users = list.where((u) => u['id'] != widget.currentUserId).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizmo Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: GizmoTheme.accentAmber),
            tooltip: 'Security Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.mark_chat_read_outlined, size: 64, color: GizmoTheme.textSecondary),
                      SizedBox(height: 12),
                      Text('No active conversations', style: TextStyle(fontSize: 18, color: GizmoTheme.textSecondary)),
                      SizedBox(height: 4),
                      Text('Send OTP to another test phone number to connect.', style: TextStyle(fontSize: 13, color: GizmoTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final name = user['displayName'] ?? user['phoneNumber'] ?? 'User';
                    final phone = user['phoneNumber'] ?? '';
                    final pubKey = user['publicKey'] ?? '';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: GizmoTheme.accentBlue.withOpacity(0.2),
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(color: GizmoTheme.accentBlue, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(phone, style: const TextStyle(color: GizmoTheme.textSecondary, fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.shield, color: GizmoTheme.accentEmerald, size: 18),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: GizmoTheme.textSecondary),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              currentUserId: widget.currentUserId,
                              contactId: user['id'],
                              contactName: name,
                              contactPhone: phone,
                              contactPublicKey: pubKey,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
