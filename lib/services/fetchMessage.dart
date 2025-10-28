// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../ui/chat_widget.dart';
// import '../index.dart';
// import '../utils/chat/index.dart';
// import '../crypto_utils.dart';
//
// Future<void> fetchMessages(String chatId, Function setState) async {
//   try {
//     final url = Uri.parse('${apiBaseUrl}/messages/$chatId');
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print("📩 Dữ liệu tin nhắn qua chatId: ${data}");
//
//       // ✅ Lấy private key từ local storage
//       final privateKeyPem = await getPrivateKey(userId);
//       if (privateKeyPem == null) {
//         print('⚠️ Không tìm thấy private key cho userId: $userId');
//         return;
//       }
//
//       // ✅ Duyệt qua từng tin nhắn
//       final List<Map<String, dynamic>> messages = [];
//
//       for (var msg in data['messages']) {
//         final Map<String, dynamic> message = Map<String, dynamic>.from(msg);
//
//         try {
//           final List<dynamic> encryptAesList = message['encryptAes'] ?? [];
//           // print("🔑 encryptAesList của tin nhắn: $encryptAesList");
//
//           // ✅ Tìm đúng khóa AES được mã hóa cho userId hiện tại
//           final encryptedAesItem = encryptAesList.firstWhere(
//                 (item) => item['userId'] == userId,
//             orElse: () => null,
//           );
//
//           if (encryptedAesItem == null) {
//             print('⚠️ Không tìm thấy encrypted AES key cho userId: $userId');
//             message['text'] = 'Tin nhắn ẩn';
//           } else {
//             final encryptedAesKey = encryptedAesItem['encryptedAesKey'];
//
//             // ✅ Giải mã AES key bằng private RSA key
//             final aesKey = await RSAUtil.decryptKey(encryptedAesKey, privateKeyPem);
//
//             // ✅ Giải mã nội dung tin nhắn bằng AES key
//             final cipherText = message['text'];
//             final decryptedText = await AESUtil.decrypt(cipherText, aesKey);
//
//             // ✅ Thay thế text cũ bằng text đã giải mã
//             message['text'] = decryptedText;
//           }
//         } catch (e) {
//           print('⚠️ Lỗi khi giải mã tin nhắn: $e');
//           message['text'] = '[Lỗi giải mã]';
//         }
//
//         message['isTyping'] = false;
//         messages.add(message);
//       }
//
//       // ✅ Cập nhật UI
//       setState(() {
//         currentChat!.messages = messages;
//       });
//
//       print('✅ Tất cả tin nhắn đã được giải mã và cập nhật UI');
//     } else {
//       print('❌ Lỗi khi tải tin nhắn: ${response.statusCode}');
//     }
//
//   } catch (e) {
//     print('⚠️ Lỗi kết nối hoặc giải mã tin nhắn: $e');
//   }
// }
// //
// // import 'dart:convert';
// // import 'package:http/http.dart' as http;
// // import '../ui/chat_widget.dart';
// // import '../index.dart';
// // import '../utils/chat/index.dart';
// // import '../crypto_utils.dart';
// //
// // String _normId(dynamic v) {
// //   // Hỗ trợ cả string, ObjectId JSON {"\$oid": "..."} hoặc kiểu khác
// //   if (v == null) return '';
// //   if (v is Map && (v.containsKey('\$oid') || v.containsKey(r'$oid'))) {
// //     return (v['\$oid'] ?? v[r'$oid'] ?? '').toString();
// //   }
// //   return v.toString();
// // }
// //
// // Future<void> fetchMessages(String chatId, Function setState) async {
// //   try {
// //     final url = Uri.parse('$apiBaseUrl/messages/$chatId');
// //     final response = await http.get(url).timeout(const Duration(seconds: 10));
// //
// //     if (response.statusCode != 200) {
// //       print('❌ Lỗi khi tải tin nhắn: ${response.statusCode} ${response.body}');
// //       return;
// //     }
// //
// //     final data = jsonDecode(response.body);
// //     // print("📩 Dữ liệu tin nhắn qua chatId: $data");
// //
// //     // Lấy private key của user hiện tại
// //     final privateKeyPem = await getPrivateKey(userId);
// //     if (privateKeyPem == null) {
// //       print('⚠️ Không tìm thấy private key cho userId: $userId');
// //       return;
// //     }
// //
// //     // Danh sách đang có trên UI (có thể chứa bubble optimistic)
// //     final List<Map<String, dynamic>> existing =
// //     List<Map<String, dynamic>>.from(currentChat?.messages ?? const []);
// //
// //     // Dựng index để reconcile nhanh
// //     final Map<String, int> byId = {};
// //     final Map<String, int> byClientId = {};
// //     for (int i = 0; i < existing.length; i++) {
// //       final m = existing[i];
// //       final id = m['_id']?.toString();
// //       final cid = m['clientMessageId']?.toString();
// //       if (id != null) byId[id] = i;
// //       if (cid != null) byClientId[cid] = i;
// //     }
// //
// //     // Giải mã từng tin từ REST và MERGE vào existing
// //     for (final raw in (data['messages'] as List)) {
// //       final message = Map<String, dynamic>.from(raw);
// //
// //       try {
// //         final List<dynamic> encryptAesList = message['encryptAes'] ?? const [];
// //         // Tìm khoá AES dành cho mình
// //         final encForMe = encryptAesList.cast<Map?>().firstWhere(
// //               (item) => item != null && _normId(item!['userId']) == _normId(userId),
// //           orElse: () => null,
// //         );
// //
// //         if (encForMe == null) {
// //           message['text'] = '[Không tìm thấy khóa AES cho bạn]';
// //         } else {
// //           final encryptedAesKey = encForMe['encryptedAesKey'];
// //           final aesKey = await RSAUtil.decryptKey(encryptedAesKey, privateKeyPem);
// //           final cipherText = message['text'];
// //           final decryptedText = await AESUtil.decrypt(cipherText, aesKey);
// //           message['text'] = decryptedText;
// //         }
// //       } catch (e) {
// //         print('⚠️ Lỗi khi giải mã tin nhắn: $e');
// //         message['text'] = '[Lỗi giải mã]';
// //       }
// //
// //       message['isTyping'] = false;
// //       message['status'] ??= 'sent'; // REST coi như đã “sent”
// //
// //       // Reconcile:
// //       final id = message['_id']?.toString();
// //       final cid = message['clientMessageId']?.toString();
// //
// //       if (id != null && byId.containsKey(id)) {
// //         // Thay thế bản đã có (ưu tiên dữ liệu WS nếu sau này tới)
// //         existing[byId[id]!] = message;
// //       } else if (cid != null && byClientId.containsKey(cid)) {
// //         // Thay thế bubble optimistic theo clientMessageId
// //         existing[byClientId[cid]!] = message;
// //       } else {
// //         // Chưa có -> thêm vào
// //         existing.add(message);
// //       }
// //     }
// //
// //     // Sắp xếp theo timestamp tăng dần
// //     existing.sort((a, b) {
// //       final ta = DateTime.tryParse(a['timestamp']?.toString() ?? '')?.millisecondsSinceEpoch ?? 0;
// //       final tb = DateTime.tryParse(b['timestamp']?.toString() ?? '')?.millisecondsSinceEpoch ?? 0;
// //       return ta.compareTo(tb);
// //     });
// //
// //     // Cập nhật UI bằng merge
// //     setState(() {
// //       if (currentChat?.id == chatId) {
// //         currentChat!.messages = existing;
// //       }
// //     });
// //
// //     print('✅ Tin nhắn đã được giải mã, merge với UI và sắp xếp.');
// //   } catch (e) {
// //     print('⚠️ Lỗi kết nối hoặc giải mã tin nhắn: $e');
// //   }
// // }
// //
// //
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ui/chat_widget.dart';
import '../index.dart';
import '../utils/chat/index.dart';
import '../crypto_utils.dart';

String _normId(dynamic v) {
  if (v == null) return '';
  if (v is Map && (v.containsKey('\$oid') || v.containsKey(r'$oid'))) {
    return (v['\$oid'] ?? v[r'$oid'] ?? '').toString();
  }
  return v.toString();
}

Future<void> fetchMessages(String chatId, Function setState) async {
  try {
    // 1) Gọi REST lấy danh sách message theo conversationId
    final uri = Uri.parse(
      '$apiBaseUrl/messages?conversationId=$chatId&limit=100',
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 12));

    if (resp.statusCode != 200) {
      print('❌ Lỗi khi tải tin nhắn: ${resp.statusCode} ${resp.body}');
      return;
    }

    final List<dynamic> list = jsonDecode(resp.body);

    // 2) Lấy private key của user hiện tại
    final privateKeyPem = await getPrivateKey(userId);
    if (privateKeyPem == null) {
      print('⚠️ Không tìm thấy private key cho userId: $userId');
      return;
    }

    // 3) Danh sách đang hiển thị (có thể có bubble optimistic)
    final List<Map<String, dynamic>> existing =
    List<Map<String, dynamic>>.from(currentChat?.messages ?? const []);

    // Dựng index để reconcile nhanh
    final Map<String, int> byId = {};
    final Map<String, int> byClientId = {};
    for (int i = 0; i < existing.length; i++) {
      final m = existing[i];
      final id = m['_id']?.toString();
      final cid = m['clientMessageId']?.toString();
      if (id != null) byId[id] = i;
      if (cid != null) byClientId[cid] = i;
    }

    // 4) Giải mã từng message
    // Backend mới không nhúng encryptAes; cần gọi /messages/key cho chính mình.
    Future<Map<String, dynamic>> _decryptOne(Map<String, dynamic> raw) async {
      final msg = Map<String, dynamic>.from(raw);
      try {
        final mid = _normId(msg['_id']);
        if (mid.isEmpty) {
          // msg['text'] = '[Thiếu messageId]';
        } else {
          final keyUri = Uri.parse(
              '$apiBaseUrl/messages/key?messageId=$mid&userId=$userId');
          final keyResp =
          await http.get(keyUri).timeout(const Duration(seconds: 8));

          if (keyResp.statusCode == 200) {
            final keyJson = jsonDecode(keyResp.body);
            final encAesKey = keyJson['encryptedAesKey'] as String?;
            if (encAesKey == null || encAesKey.isEmpty) {
              // msg['text'] = 'Tin nhắn ẩn';
            } else {
              final aesKey = await RSAUtil.decryptKey(encAesKey, privateKeyPem);
              final cipher = msg['text'] as String? ?? '';
              msg['text'] = await AESUtil.decrypt(cipher, aesKey);

              final sp = msg['senderProfile'] as Map?;
              if (sp != null) {
                msg['name'] = (sp['name']?.toString() ?? '').trim();
                msg['email'] = (sp['email']?.toString() ?? '').trim();
                msg['avatar'] = (sp['avatar']?.toString() ?? '').trim(); // local path/asset/file
              }
            }
          } else if (keyResp.statusCode == 404) {
            // Không có khóa cho mình (ví dụ: rời nhóm trước thời điểm tin)
            // msg['text'] = 'Tin nhắn ẩn';
          } else {
            // msg['text'] = '[Lỗi lấy khóa: ${keyResp.statusCode}]';
          }
        }
      } catch (e) {
        print('⚠️ Lỗi khi giải mã tin nhắn: $e');
        msg['text'] = '[Lỗi giải mã]';
      }

      msg['isTyping'] = false;
      msg['status'] ??= 'sent';
      // Chuẩn hóa trường cho UI hiện tại
      msg['sender'] ??= msg['senderId']?.toString();
      return msg;
    }

    // Giải mã song song có kiểm soát; đơn giản hóa bằng Future.wait
    final decoded = await Future.wait<Map<String, dynamic>>(
      list.map((e) => _decryptOne(Map<String, dynamic>.from(e))),
    );

    // 5) Reconcile vào existing theo _id hoặc clientMessageId
    for (final message in decoded) {
      final id = message['_id']?.toString();
      final cid = message['clientMessageId']?.toString();

      if (id != null && byId.containsKey(id)) {
        existing[byId[id]!] = message;
      } else if (cid != null && byClientId.containsKey(cid)) {
        existing[byClientId[cid]!] = message;
      } else {
        existing.add(message);
      }
    }

    // 6) Sắp xếp theo timestamp tăng dần
    existing.sort((a, b) {
      final ta = DateTime.tryParse(a['timestamp']?.toString() ?? '')
          ?.millisecondsSinceEpoch ??
          0;
      final tb = DateTime.tryParse(b['timestamp']?.toString() ?? '')
          ?.millisecondsSinceEpoch ??
          0;
      return ta.compareTo(tb);
    });

    // 7) Cập nhật UI nếu vẫn đang ở đúng phòng
    setState(() {
      if (currentChat?.id == chatId) {
        currentChat!.messages = existing;
      }
    });
    print(currentChat!.messages);

    print('✅ Tin nhắn đã được giải mã, merge với UI và sắp xếp.');
  } catch (e) {
    print('⚠️ Lỗi kết nối hoặc giải mã tin nhắn: $e');
  }
}
