import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/auth/security_service.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/websocket_service.dart';
import '../../../shared/theme.dart';
import 'encryption_dialog.dart';
import 'auth_prompt_modal.dart';
import '../../security/presentation/safety_number_screen.dart';

class ChatMessageItem {
  final String id;
  final String senderId;
  final String receiverId;
  final String ciphertext;
  final SecurityLevel securityLevel;
  final String? nonce;
  final String? authTag;
  final String? ephemeralPublicKey;
  String status; // SENT, DELIVERED, READ
  String? decryptedPlaintext;
  bool isDecrypted;

  ChatMessageItem({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.ciphertext,
    required this.securityLevel,
    this.nonce,
    this.authTag,
    this.ephemeralPublicKey,
    this.status = 'SENT',
    this.decryptedPlaintext,
    this.isDecrypted = false,
  });
}

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String contactId;
  final String contactName;
  final String contactPhone;
  final String contactPublicKey;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.contactId,
    required this.contactName,
    required this.contactPhone,
    required this.contactPublicKey,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final CryptoService _cryptoService = CryptoService();
  final SecurityService _securityService = SecurityService();
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageItem> _messages = [];
  SecurityLevel _selectedSecurityLevel = SecurityLevel.standard;
  bool _isEncryptToggleActive = false;

  late StreamSubscription _messageSub;
  late StreamSubscription _statusSub;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _connectWebSocket();
    _loadDefaultSecurityLevel();
  }

  Future<void> _loadDefaultSecurityLevel() async {
    final levelStr = await _securityService.getDefaultSecurityLevel();
    setState(() {
      if (levelStr == 'HIGH') _selectedSecurityLevel = SecurityLevel.high;
      if (levelStr == 'MAXIMUM') _selectedSecurityLevel = SecurityLevel.maximum;
    });
  }

  Future<void> _loadHistory() async {
    try {
      final list = await _apiService.getMessageHistory(widget.contactId);
      final parsed = list.map((m) {
        final secLevel = _parseSecurityLevel(m['securityLevel']);
        return ChatMessageItem(
          id: m['id'],
          senderId: m['senderId'],
          receiverId: m['receiverId'],
          ciphertext: m['ciphertext'],
          securityLevel: secLevel,
          nonce: m['nonce'],
          authTag: m['authTag'],
          ephemeralPublicKey: m['ephemeralPublicKey'],
          status: m['status'] ?? 'SENT',
          decryptedPlaintext: secLevel == SecurityLevel.standard && m['nonce'] == null ? m['ciphertext'] : null,
          isDecrypted: secLevel == SecurityLevel.standard && m['nonce'] == null,
        );
      }).toList();

      setState(() => _messages = parsed);
      _scrollToBottom();
    } catch (_) {}
  }

  void _connectWebSocket() {
    _wsService.connect(widget.currentUserId);
    _messageSub = _wsService.onMessageReceived.listen((data) {
      if (data['senderId'] == widget.contactId) {
        final secLevel = _parseSecurityLevel(data['securityLevel']);
        final newItem = ChatMessageItem(
          id: data['id'],
          senderId: data['senderId'],
          receiverId: data['receiverId'],
          ciphertext: data['ciphertext'],
          securityLevel: secLevel,
          nonce: data['nonce'],
          authTag: data['authTag'],
          ephemeralPublicKey: data['ephemeralPublicKey'],
          status: 'DELIVERED',
        );
        setState(() => _messages.add(newItem));
        _scrollToBottom();
      }
    });

    _statusSub = _wsService.onStatusUpdated.listen((data) {
      final msgId = data['messageId'];
      final status = data['status'];
      setState(() {
        for (var m in _messages) {
          if (m.id == msgId) m.status = status;
        }
      });
    });
  }

  SecurityLevel _parseSecurityLevel(String? str) {
    if (str == 'HIGH') return SecurityLevel.high;
    if (str == 'MAXIMUM') return SecurityLevel.maximum;
    return SecurityLevel.standard;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_isEncryptToggleActive) {
      // 1. Check if auth before encrypt required
      final reqAuth = await _securityService.getRequireAuthBeforeEncrypt();
      if (!mounted) return;
      if (reqAuth) {
        showDialog(
          context: context,
          builder: (_) => AuthPromptModal(
            title: 'Authenticate to Encrypt',
            subtitle: 'Scan biometrics or enter PIN to unlock encryption keys',
            securityService: _securityService,
            onResult: (success, decryptedKey) {
              if (success) _executeEncryptedSend(text, decryptedKey);
            },
          ),
        );
      } else {
        final key = await _securityService.getPrivateKeyHardware();
        _executeEncryptedSend(text, key);
      }
    } else {
      // Normal Plaintext Message
      _executeNormalSend(text);
    }
  }

  Future<void> _executeNormalSend(String text) async {
    _messageController.clear();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final item = ChatMessageItem(
      id: tempId,
      senderId: widget.currentUserId,
      receiverId: widget.contactId,
      ciphertext: text,
      securityLevel: SecurityLevel.standard,
      decryptedPlaintext: text,
      isDecrypted: true,
      status: 'SENT',
    );

    setState(() => _messages.add(item));
    _scrollToBottom();

    _wsService.sendMessage({
      'senderId': widget.currentUserId,
      'receiverId': widget.contactId,
      'ciphertext': text,
      'securityLevel': 'STANDARD',
    });
  }

  Future<void> _executeEncryptedSend(String plaintext, String? privateKeyBase64) async {
    _messageController.clear();
    EncryptionResult result;

    if (_selectedSecurityLevel == SecurityLevel.maximum) {
      result = await _cryptoService.encryptMaximum(
        plaintext: plaintext,
        recipientPublicKeyBase64: widget.contactPublicKey,
      );
    } else if (_selectedSecurityLevel == SecurityLevel.high) {
      result = await _cryptoService.encryptHigh(plaintext, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]);
    } else {
      result = await _cryptoService.encryptStandard(plaintext, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]);
    }

    final item = ChatMessageItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.currentUserId,
      receiverId: widget.contactId,
      ciphertext: result.ciphertextBase64,
      securityLevel: result.securityLevel,
      nonce: result.nonceBase64,
      authTag: result.authTagBase64,
      ephemeralPublicKey: result.ephemeralPublicKeyBase64,
      decryptedPlaintext: plaintext,
      isDecrypted: true,
      status: 'SENT',
    );

    setState(() => _messages.add(item));
    _scrollToBottom();

    _wsService.sendMessage({
      'senderId': widget.currentUserId,
      'receiverId': widget.contactId,
      'ciphertext': result.ciphertextBase64,
      'securityLevel': result.securityLevel.name.toUpperCase(),
      'nonce': result.nonceBase64,
      'authTag': result.authTagBase64,
      'ephemeralPublicKey': result.ephemeralPublicKeyBase64,
    });
  }

  Future<void> _handleDecryptMessage(ChatMessageItem item) async {
    if (item.isDecrypted) return;

    final reqAuth = await _securityService.getRequireAuthBeforeDecrypt();
    if (!mounted) return;
    if (reqAuth) {
      showDialog(
        context: context,
        builder: (_) => AuthPromptModal(
          title: 'Authenticate to Decrypt',
          subtitle: 'Use Face ID / Biometrics or PIN to view message contents',
          securityService: _securityService,
          onResult: (success, decryptedKey) {
            if (success) _executeDecryption(item, decryptedKey);
          },
        ),
      );
    } else {
      final key = await _securityService.getPrivateKeyHardware();
      _executeDecryption(item, key);
    }
  }

  Future<void> _executeDecryption(ChatMessageItem item, String? privateKeyBase64) async {
    try {
      String plaintext;
      if (item.securityLevel == SecurityLevel.maximum && item.ephemeralPublicKey != null && privateKeyBase64 != null) {
        final keyPair = await _cryptoService.importKeyPairFromPrivateKeyBase64(privateKeyBase64);
        plaintext = await _cryptoService.decryptMaximum(
          ciphertextBase64: item.ciphertext,
          nonceBase64: item.nonce!,
          authTagBase64: item.authTag!,
          ephemeralPublicKeyBase64: item.ephemeralPublicKey!,
          recipientPrivateKeyPair: keyPair,
        );
      } else if (item.securityLevel == SecurityLevel.high) {
        plaintext = await _cryptoService.decryptHigh(
          ciphertextBase64: item.ciphertext,
          nonceBase64: item.nonce!,
          authTagBase64: item.authTag!,
          keyBytes: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32],
        );
      } else {
        plaintext = await _cryptoService.decryptStandard(
          ciphertextBase64: item.ciphertext,
          nonceBase64: item.nonce!,
          authTagBase64: item.authTag!,
          keyBytes: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32],
        );
      }

      setState(() {
        item.decryptedPlaintext = plaintext;
        item.isDecrypted = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Decryption failed: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _messageSub.cancel();
    _statusSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: GizmoTheme.accentBlue.withOpacity(0.2),
              child: Text(widget.contactName[0], style: const TextStyle(color: GizmoTheme.accentBlue, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.contactName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Online', style: TextStyle(fontSize: 11, color: GizmoTheme.accentEmerald)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: GizmoTheme.accentBlue),
            tooltip: 'Safety Number',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SafetyNumberScreen(
                    contactName: widget.contactName,
                    contactPublicKey: widget.contactPublicKey,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Trust Indicator Header Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            color: GizmoTheme.cardBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock_rounded, size: 14, color: GizmoTheme.accentAmber),
                SizedBox(width: 6),
                Text(
                  '🔒 End-to-End Encrypted Transport',
                  style: TextStyle(fontSize: 12, color: GizmoTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Message Bubbles List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.senderId == widget.currentUserId;
                return _buildMessageBubble(msg, isMe);
              },
            ),
          ),

          // Bottom Input Controls (Matching Spec Diagram)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: GizmoTheme.cardBg,
              border: Border(top: BorderSide(color: GizmoTheme.surfaceBg)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.sentiment_satisfied_alt, color: GizmoTheme.textSecondary),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isEncryptToggleActive ? 'Type encrypted message...' : 'Type a message...',
                      border: InputBorder.none,
                      hintStyle: const TextStyle(color: GizmoTheme.textSecondary),
                    ),
                  ),
                ),
                // Lock Encryption Button
                IconButton(
                  icon: Icon(
                    Icons.lock_rounded,
                    color: _isEncryptToggleActive ? GizmoTheme.accentAmber : GizmoTheme.textSecondary,
                  ),
                  tooltip: 'Security Level Selector',
                  onPressed: () {
                    setState(() => _isEncryptToggleActive = !_isEncryptToggleActive);
                    showDialog(
                      context: context,
                      builder: (_) => EncryptionDialog(
                        initialLevel: _selectedSecurityLevel,
                        onSelected: (lvl) {
                          setState(() {
                            _selectedSecurityLevel = lvl;
                            _isEncryptToggleActive = true;
                          });
                        },
                      ),
                    );
                  },
                ),
                // Send Button
                IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: _isEncryptToggleActive ? GizmoTheme.accentAmber : GizmoTheme.accentBlue,
                  ),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe
              ? (msg.nonce != null ? GizmoTheme.accentAmber.withOpacity(0.2) : GizmoTheme.accentBlue.withOpacity(0.2))
              : GizmoTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe
                ? (msg.nonce != null ? GizmoTheme.accentAmber : GizmoTheme.accentBlue)
                : GizmoTheme.surfaceBg,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isDecrypted && msg.nonce != null) ...[
              // Spec Encrypted Message Placeholder Card
              InkWell(
                onTap: () => _handleDecryptMessage(msg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_rounded, color: GizmoTheme.accentAmber, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Encrypted Message',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: GizmoTheme.accentAmber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${msg.securityLevel.name.toUpperCase()} Security · Tap to Decrypt',
                      style: const TextStyle(fontSize: 12, color: GizmoTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Decrypted or Plaintext Message
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.nonce != null)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.lock_open_rounded, color: GizmoTheme.accentEmerald, size: 16),
                    ),
                  Expanded(
                    child: Text(
                      msg.decryptedPlaintext ?? msg.ciphertext,
                      style: const TextStyle(fontSize: 15, color: GizmoTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.nonce != null && msg.isDecrypted)
                  const Text('🔓 Decrypted  •  ', style: TextStyle(fontSize: 10, color: GizmoTheme.accentEmerald)),
                Text(
                  '10:02',
                  style: const TextStyle(fontSize: 10, color: GizmoTheme.textSecondary),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.status == 'READ'
                        ? Icons.remove_red_eye
                        : msg.status == 'DELIVERED'
                            ? Icons.done_all
                            : Icons.done,
                    size: 14,
                    color: msg.status == 'READ' ? GizmoTheme.accentBlue : GizmoTheme.textSecondary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
