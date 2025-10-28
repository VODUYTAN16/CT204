// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../globalvariety.dart';
// import '../crypto_utils.dart';
// import '../utils/chat/index.dart'; // Import mô hình Chat của bạn
//
// Future<List<Chat>> fetchUserChats(Function setState) async {
//   try {
//     final response = await http.get(
//       Uri.parse('${apiBaseUrl}/chatlist/'),
//     );
//
//     if (response.statusCode == 200) {
//       final List<dynamic> chatData = jsonDecode(response.body);
//
//       // ✅ Lấy private key đã lưu
//       final privateKeyPem = await getPrivateKey(userId);
//       if (privateKeyPem == null) {
//         print('⚠️ Không tìm thấy private key cho userId: $userId');
//         return [];
//       }
//
//       // ✅ Duyệt qua từng chat
//       List<Chat> userChats = [];
//
//       for (var chatJson in chatData) {
//         List<Map<String, dynamic>> messages = [];
//
//         // ✅ Duyệt qua từng tin nhắn trong chat
//         if (chatJson['messages'] != null) {
//           for (var msg in chatJson['messages']) {
//             final Map<String, dynamic> message = Map<String, dynamic>.from(msg);
//
//             try {
//               final List<dynamic> encryptAesList = message['encryptAes'] ?? [];
//
//               // ✅ Tìm đúng encrypted AES key cho userId hiện tại
//               final encryptedAesItem = encryptAesList.firstWhere(
//                     (item) => item['userId'] == userId,
//                 orElse: () => null,
//               );
//
//               if (encryptedAesItem != null) {
//                 final encryptedAesKey = encryptedAesItem['encryptedAesKey'];
//
//                 // ✅ Giải mã AES key bằng private RSA key
//                 final aesKey =
//                 await RSAUtil.decryptKey(encryptedAesKey, privateKeyPem);
//
//                 // ✅ Giải mã text bằng AES key
//                 final cipherText = message['text'];
//                 final decryptedText =
//                 await AESUtil.decrypt(cipherText, aesKey);
//
//                 message['text'] = decryptedText;
//               } else {
//                 print(
//                     '⚠️ Không tìm thấy encrypted AES key cho userId: $userId trong tin nhắn.');
//                 message['text'] = '[Không tìm thấy khóa AES]';
//               }
//             } catch (e) {
//               print('⚠️ Lỗi khi giải mã tin nhắn: $e');
//               message['text'] = '[Lỗi giải mã]';
//             }
//
//             messages.add(message);
//           }
//         }
//
//         // ✅ Thêm vào danh sách chat
//         userChats.add(Chat(
//           id: chatJson['id'],
//           title: chatJson['title'],
//           messages: messages,
//           isEditing: false,
//         ));
//       }
//
//       print('✅ Giải mã hoàn tất tất cả tin nhắn trong các chat');
//       return userChats;
//     } else {
//       throw Exception('❌ Lỗi khi tải danh sách chat: ${response.statusCode}');
//     }
//   } catch (e) {
//     print('⚠️ Lỗi khi lấy danh sách chat: $e');
//     return [];
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../globalvariety.dart';
import '../crypto_utils.dart';
import '../utils/chat/index.dart';

String _normId(dynamic v) {
  if (v == null) return '';
  if (v is Map && (v.containsKey('\$oid') || v.containsKey(r'$oid'))) {
    return (v['\$oid'] ?? v[r'$oid'] ?? '').toString();
  }
  return v.toString();
}

Future<List<Chat>> fetchUserChats(Function setState) async {
  try {
    // 1) Danh sách hội thoại của tôi
    final convRes = await http
        .get(Uri.parse('$apiBaseUrl/conversations?userId=$userId'))
        .timeout(const Duration(seconds: 12));

    if (convRes.statusCode != 200) {
      throw Exception('Lỗi tải hội thoại: ${convRes.statusCode} ${convRes.body}');
    }

    final List convos = jsonDecode(convRes.body) as List;

    // 2) Private key của tôi
    final privateKeyPem = await getPrivateKey(userId);
    if (privateKeyPem == null) {
      print('⚠️ Không tìm thấy private key cho userId: $userId');
      return [];
    }

    // 3) Với mỗi hội thoại, lấy 1 tin gần nhất để hiển thị preview
    Future<Chat> _buildChat(Map<String, dynamic> c) async {
      final String convoId = _normId(c['_id']);
      final String type = (c['type'] ?? '').toString();
      // Tiêu đề: group dùng title; direct có thể để trống hoặc tự render phía UI
      final String title =
      (c['title']?.toString().isNotEmpty ?? false) ? c['title'].toString() : (type == 'group' ? 'Nhóm' : 'Trực tiếp');

      final List<Map<String, dynamic>> preview = [];

      try {
        final msgRes = await http
            .get(Uri.parse('$apiBaseUrl/messages?conversationId=$convoId&limit=1'))
            .timeout(const Duration(seconds: 8));

        if (msgRes.statusCode == 200) {
          final List msgs = jsonDecode(msgRes.body) as List;
          if (msgs.isNotEmpty) {
            final Map<String, dynamic> m = Map<String, dynamic>.from(msgs.first);
            // Lấy key dành cho tôi
            final mid = _normId(m['_id']);
            if (mid.isNotEmpty) {
              final keyRes = await http
                  .get(Uri.parse('$apiBaseUrl/messages/key?messageId=$mid&userId=$userId'))
                  .timeout(const Duration(seconds: 6));

              if (keyRes.statusCode == 200) {
                final keyJson = jsonDecode(keyRes.body);
                final encAesKey = keyJson['encryptedAesKey'] as String?;
                if (encAesKey != null && encAesKey.isNotEmpty) {
                  final aesKey = await RSAUtil.decryptKey(encAesKey, privateKeyPem);
                  final cipher = m['text']?.toString() ?? '';
                  m['text'] = await AESUtil.decrypt(cipher, aesKey);
                } else {
                  m['text'] = 'Tin nhắn ẩn';
                }
              } else if (keyRes.statusCode == 404) {
                m['text'] = 'Tin nhắn ẩn';
              } else {
                m['text'] = '[Lỗi lấy khóa: ${keyRes.statusCode}]';
              }
            } else {
              m['text'] = '[Thiếu messageId]';
            }

            m['sender'] ??= m['senderId']?.toString();
            m['isTyping'] = false;
            m['status'] = 'sent';
            preview.add(m);
          }
        }
      } catch (e) {
        // Không chặn tổng thể; chỉ bỏ preview khi lỗi
        // print('Preview error for $convoId: $e');
      }

      return Chat(
        id: convoId,
        title: title,
        messages: preview, // chỉ 1 message gần nhất để hiển thị danh sách
        isEditing: false,
      );
    }

    final chats = await Future.wait<Chat>(
      convos.map((e) => _buildChat(Map<String, dynamic>.from(e))),
    );

    print('✅ Tải danh sách hội thoại + preview xong');
    return chats;
  } catch (e) {
    print('⚠️ Lỗi khi lấy danh sách chat: $e');
    return [];
  }
}
