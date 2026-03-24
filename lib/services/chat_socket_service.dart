// =============================================================================
// FILE PATH: lib/services/chat_socket_service.dart
//
// Real-time chat via Socket.IO.
// Connects to Flask-SocketIO server running on port 5000.
//
// Add to pubspec.yaml:
//   socket_io_client: ^2.0.3+1
//
// Then run: flutter pub get
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class ChatSocketService {
  ChatSocketService._();
  static final ChatSocketService instance = ChatSocketService._();

  IO.Socket? _socket;
  bool       _isConnected = false;

  // ── Callbacks set by ChatController ───────────────────────────────────────
  /// Called when a new message arrives in any joined conversation room.
  /// Map keys: id, text, sender_id, sender_name, sent_at, conversation_id, is_mine
  Function(Map<String, dynamic>)? onNewMessage;

  /// Called when a DM conversation is ready (after start_dm event).
  /// Receives the conversation_id string.
  Function(String)? onDmReady;

  /// Called when a socket error occurs.
  Function(String)? onError;

  bool get isConnected => _isConnected;

  // ── Connect ────────────────────────────────────────────────────────────────
  /// Connects to Flask-SocketIO with JWT auth.
  /// Safe to call multiple times — skips if already connected.
  Future<void> connect() async {
    if (_isConnected && _socket?.connected == true) {
      debugPrint('[Socket] Already connected, skipping.');
      return;
    }

    final token = await AuthService.instance.getToken();
    if (token == null) {
      debugPrint('[Socket] No JWT token — cannot connect.');
      return;
    }

    try {
      _socket = IO.io(
        'http://192.168.1.26:5000',   // ← same IP as your Flask server
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );

      // ── Event listeners ──────────────────────────────────────────────────
      _socket!.onConnect((_) {
        _isConnected = true;
        debugPrint('[Socket] ✅ Connected to Flask-SocketIO');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('[Socket] ❌ Disconnected');
      });

      _socket!.onConnectError((data) {
        _isConnected = false;
        debugPrint('[Socket] Connection error: $data');
        if (onError != null) onError!('Connection failed. Please try again.');
      });

      _socket!.onReconnect((_) {
        _isConnected = true;
        debugPrint('[Socket] 🔄 Reconnected');
      });

      // ── Incoming message ────────────────────────────────────────────────
      _socket!.on('new_message', (data) {
        debugPrint('[Socket] 📨 New message: $data');
        if (onNewMessage != null && data is Map) {
          onNewMessage!(Map<String, dynamic>.from(data));
        }
      });

      // ── DM conversation ready ────────────────────────────────────────────
      _socket!.on('dm_ready', (data) {
        debugPrint('[Socket] 💬 DM ready: $data');
        if (onDmReady != null && data is Map) {
          final convId = data['conversation_id']?.toString() ?? '';
          if (convId.isNotEmpty) onDmReady!(convId);
        }
      });

      // ── Joined room confirmation ─────────────────────────────────────────
      _socket!.on('joined', (data) {
        debugPrint('[Socket] Joined room: $data');
      });

      // ── Server error ──────────────────────────────────────────────────────
      _socket!.on('error', (data) {
        debugPrint('[Socket] Server error: $data');
        if (onError != null && data is Map) {
          onError!(data['message']?.toString() ?? 'Unknown socket error.');
        }
      });

      _socket!.connect();

    } catch (e) {
      debugPrint('[Socket] Failed to initialize: $e');
    }
  }

  // ── Join conversation room ─────────────────────────────────────────────────
  /// Subscribes to a conversation room to receive real-time messages.
  /// Call this when opening a conversation.
  void joinConversation(String conversationId) {
    if (!_isConnected) {
      debugPrint('[Socket] Not connected — cannot join room $conversationId');
      return;
    }
    _socket?.emit('join_conversation', {
      'conversation_id': conversationId,
    });
    debugPrint('[Socket] Joined conversation room: $conversationId');
  }

  // ── Leave conversation room ────────────────────────────────────────────────
  /// Unsubscribes from a conversation room.
  /// Call this when navigating away from a chat screen.
  void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', {
      'conversation_id': conversationId,
    });
    debugPrint('[Socket] Left conversation room: $conversationId');
  }

  // ── Send message ───────────────────────────────────────────────────────────
  /// Emits a message to the server.
  /// Server saves it to DB and broadcasts to all room members.
  Future<void> sendMessage(String conversationId, String text) async {
    if (!_isConnected) {
      debugPrint('[Socket] Not connected — message not sent.');
      return;
    }
    final token = await AuthService.instance.getToken();
    _socket?.emit('send_message', {
      'token':           token ?? '',
      'conversation_id': conversationId,
      'text':            text,
    });
    debugPrint('[Socket] Sent message to conv $conversationId: $text');
  }

  // ── Start DM ───────────────────────────────────────────────────────────────
  /// Creates or finds a 1-on-1 conversation with another student.
  /// Used when tapping "Chat Seller" on a marketplace item or
  /// "Contact Reporter" on a lost & found item.
  ///
  /// Listen for the result via [onDmReady] callback.
  ///
  /// Example:
  ///   ChatSocketService.instance.onDmReady = (convId) {
  ///     context.push('/chat'); // navigate to chat
  ///   };
  ///   ChatSocketService.instance.startDm(item.sellerId);
  Future<void> startDm(String otherStudentId) async {
    if (!_isConnected) {
      // Try to connect first then start DM
      await connect();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    final token = await AuthService.instance.getToken();
    _socket?.emit('start_dm', {
      'token':            token ?? '',
      'other_student_id': otherStudentId,
    });
    debugPrint('[Socket] Starting DM with student: $otherStudentId');
  }

  // ── Disconnect ─────────────────────────────────────────────────────────────
  /// Disconnects the socket. Called by ChatController.dispose().
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket      = null;
    _isConnected = false;
    onNewMessage = null;
    onDmReady    = null;
    onError      = null;
    debugPrint('[Socket] Disconnected and cleaned up.');
  }

  // ── Reconnect with fresh token ─────────────────────────────────────────────
  /// Call this after login to connect with the new JWT token.
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 300));
    await connect();
  }
}