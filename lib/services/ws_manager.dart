// lib/services/ws_manager.dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../globalvariety.dart';

class WsManager {
  final String baseWs;
  WebSocketChannel? _ch;
  String? _currentRoom;

  WsManager(this.baseWs);

  void connect({
    required void Function(Map evt) onEvent,
    void Function(Object error)? onError,
  }) {
    _ch ??= WebSocketChannel.connect(Uri.parse(baseWs));
    _ch!.stream.listen((raw) {
      try {
        final data = raw is String ? raw : utf8.decode(raw);
        print('📩 WS raw: $data');
        final evt = jsonDecode(data);
        onEvent(evt);
      } catch (e) {
        print('❌ WS decode error: $e');
      }
    }, onError: (err) {
      print('❌ WS stream error: $err');
      if (onError != null) onError(err);
    }, onDone: () {
      print('🔌 WS closed');
      _ch = null;
    });
  }

  void subscribe(String chatId) {
    print('da subscribe: ${chatId} //////////////////////////////////////');
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
