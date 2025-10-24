import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ui/chat_widget.dart';
import '../index.dart';
import '../utils/chat/index.dart';
import '../crypto_utils.dart';

Future<void> fetchMessages(String chatId, Function setState) async {
  try {
    final url = Uri.parse('${apiBaseUrl}/messages/$chatId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("📩 Dữ liệu tin nhắn qua chatId: ${data}");

      // ✅ Lấy private key từ local storage
      final privateKeyPem = await getPrivateKey(userId);
      if (privateKeyPem == null) {
        print('⚠️ Không tìm thấy private key cho userId: $userId');
        return;
      }

      // ✅ Duyệt qua từng tin nhắn
      final List<Map<String, dynamic>> messages = [];

      for (var msg in data['messages']) {
        final Map<String, dynamic> message = Map<String, dynamic>.from(msg);

        try {
          final List<dynamic> encryptAesList = message['encryptAes'] ?? [];
          // print("🔑 encryptAesList của tin nhắn: $encryptAesList");

          // ✅ Tìm đúng khóa AES được mã hóa cho userId hiện tại
          final encryptedAesItem = encryptAesList.firstWhere(
                (item) => item['userId'] == userId,
            orElse: () => null,
          );

          if (encryptedAesItem == null) {
            print('⚠️ Không tìm thấy encrypted AES key cho userId: $userId');
            message['text'] = '[Không tìm thấy khóa AES cho bạn]';
          } else {
            final encryptedAesKey = encryptedAesItem['encryptedAesKey'];

            // ✅ Giải mã AES key bằng private RSA key
            final aesKey = await RSAUtil.decryptKey(encryptedAesKey, privateKeyPem);

            // ✅ Giải mã nội dung tin nhắn bằng AES key
            final cipherText = message['text'];
            final decryptedText = await AESUtil.decrypt(cipherText, aesKey);

            // ✅ Thay thế text cũ bằng text đã giải mã
            message['text'] = decryptedText;
          }
        } catch (e) {
          print('⚠️ Lỗi khi giải mã tin nhắn: $e');
          message['text'] = '[Lỗi giải mã]';
        }

        message['isTyping'] = false;
        messages.add(message);
      }

      // ✅ Cập nhật UI
      setState(() {
        currentChat!.messages = messages;
      });

      print('✅ Tất cả tin nhắn đã được giải mã và cập nhật UI');
    } else {
      print('❌ Lỗi khi tải tin nhắn: ${response.statusCode}');
    }

  } catch (e) {
    print('⚠️ Lỗi kết nối hoặc giải mã tin nhắn: $e');
  }
}
