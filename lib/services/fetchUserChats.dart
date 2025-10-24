import 'dart:convert';
import 'package:http/http.dart' as http;
import '../globalvariety.dart';
import '../crypto_utils.dart';
import '../utils/chat/index.dart'; // Import mô hình Chat của bạn

Future<List<Chat>> fetchUserChats(Function setState) async {
  try {
    final response = await http.get(
      Uri.parse('${apiBaseUrl}/chatlist/'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> chatData = jsonDecode(response.body);

      // ✅ Lấy private key đã lưu
      final privateKeyPem = await getPrivateKey(userId);
      if (privateKeyPem == null) {
        print('⚠️ Không tìm thấy private key cho userId: $userId');
        return [];
      }

      // ✅ Duyệt qua từng chat
      List<Chat> userChats = [];

      for (var chatJson in chatData) {
        List<Map<String, dynamic>> messages = [];

        // ✅ Duyệt qua từng tin nhắn trong chat
        if (chatJson['messages'] != null) {
          for (var msg in chatJson['messages']) {
            final Map<String, dynamic> message = Map<String, dynamic>.from(msg);

            try {
              final List<dynamic> encryptAesList = message['encryptAes'] ?? [];

              // ✅ Tìm đúng encrypted AES key cho userId hiện tại
              final encryptedAesItem = encryptAesList.firstWhere(
                    (item) => item['userId'] == userId,
                orElse: () => null,
              );

              if (encryptedAesItem != null) {
                final encryptedAesKey = encryptedAesItem['encryptedAesKey'];

                // ✅ Giải mã AES key bằng private RSA key
                final aesKey =
                await RSAUtil.decryptKey(encryptedAesKey, privateKeyPem);

                // ✅ Giải mã text bằng AES key
                final cipherText = message['text'];
                final decryptedText =
                await AESUtil.decrypt(cipherText, aesKey);

                message['text'] = decryptedText;
              } else {
                print(
                    '⚠️ Không tìm thấy encrypted AES key cho userId: $userId trong tin nhắn.');
                message['text'] = '[Không tìm thấy khóa AES]';
              }
            } catch (e) {
              print('⚠️ Lỗi khi giải mã tin nhắn: $e');
              message['text'] = '[Lỗi giải mã]';
            }

            messages.add(message);
          }
        }

        // ✅ Thêm vào danh sách chat
        userChats.add(Chat(
          id: chatJson['id'],
          title: chatJson['title'],
          messages: messages,
          isEditing: false,
        ));
      }

      print('✅ Giải mã hoàn tất tất cả tin nhắn trong các chat');
      return userChats;
    } else {
      throw Exception('❌ Lỗi khi tải danh sách chat: ${response.statusCode}');
    }
  } catch (e) {
    print('⚠️ Lỗi khi lấy danh sách chat: $e');
    return [];
  }
}
