// lib/services/ws_manager.dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsManager {
  final String baseWs; // ví dụ: ws://10.0.2.2:5000 (Android emulator), ws://localhost:5000 (iOS)
  WebSocketChannel? _ch;
  String? _currentRoom;

  WsManager(this.baseWs);

  void connect({
    required void Function(Map evt) onEvent,
    void Function(Object error)? onError,
  }) {
    _ch ??= WebSocketChannel.connect(Uri.parse(baseWs));
    _ch!.stream.listen((raw) {
      try { onEvent(jsonDecode(raw as String)); } catch (_) {}
    }, onError: onError, onDone: () { _ch = null; });
  }

  void subscribe(String chatId) {
    if (_ch == null) return;
    if (_currentRoom != null && _currentRoom != chatId) {
      _ch!.sink.add(jsonEncode({"type":"unsubscribe","chatId":_currentRoom}));
    }
    _currentRoom = chatId;
    _ch!.sink.add(jsonEncode({"type":"subscribe","chatId":chatId}));
  }

  void dispose() {
    if (_currentRoom != null) {
      _ch?.sink.add(jsonEncode({"type":"unsubscribe","chatId":_currentRoom}));
    }
    _ch?.sink.close();
    _ch = null;
    _currentRoom = null;
  }
}
