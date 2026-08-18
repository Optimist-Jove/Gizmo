import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

class WebSocketService {
  io.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessageReceived => _messageController.stream;
  Stream<Map<String, dynamic>> get onStatusUpdated => _statusController.stream;
  Stream<Map<String, dynamic>> get onTypingUpdated => _typingController.stream;

  void connect(String userId) {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'userId': userId},
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('[WebSocket] Connected as $userId');
    });

    _socket!.on('message:receive', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('message:status_ack', (data) {
      _statusController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('typing:update', (data) {
      _typingController.add(Map<String, dynamic>.from(data));
    });

    _socket!.onDisconnect((_) {
      print('[WebSocket] Disconnected');
    });
  }

  void sendMessage(Map<String, dynamic> payload) {
    _socket?.emit('message:send', payload);
  }

  void sendStatus(String messageId, String senderId, String status) {
    _socket?.emit('message:status', {
      'messageId': messageId,
      'senderId': senderId,
      'status': status,
    });
  }

  void sendTyping(String senderId, String receiverId, bool isTyping) {
    _socket?.emit(isTyping ? 'typing:start' : 'typing:stop', {
      'senderId': senderId,
      'receiverId': receiverId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
