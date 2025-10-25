// import '../../ui/chat_widget.dart';
// import '../../index.dart';
// import 'index.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import '../../crypto_utils.dart';
// Future<void> sendMessage(Function setState, ScrollController scrollController) async {
//   if (controller.text.isNotEmpty && selectedImages.isEmpty) {
//     String userMessage = controller.text;
//
//     // Cập nhật UI
//     var newMessage = {
//       "text": userMessage,
//       "sender": userId,
//       "images": [],
//       "captions": null,
//       "isTyping": false,
//     };
//
//     currentChat?.messages = currentChat!.messages.map((message) {
//       if (message["isTyping"] == true) message["isTyping"] = false;
//       return message;
//     }).toList();
//
//     setState(() {
//       currentChat?.messages.add(newMessage);
//     });
//
//     scrollToBottom(scrollController);
//     controller.clear();
//
//     try {
//       // 🔹 1. Lấy thông tin người dùng (để lấy danh sách otherpublickey)
//       final response = await http.get(Uri.parse('$apiBaseUrl/user/$userId'));
//       if (response.statusCode != 200) {
//         print('Failed to fetch user info: ${response.body}');
//         return;
//       }
//
//       final userData = jsonDecode(response.body);
//       print('User Info: $userData');
//
//       // 🔹 2. Tạo AES key base64
//       final aesKeyB64 = AESUtil.generateKeyBase64();
//
//       // 🔹 3. Mã hóa AES key bằng public key của từng người
//       List<Map<String, dynamic>> encryptedAesList = [];
//
//       for (var entry in userData['otherpublickey']) {
//         final otherUserId = entry['userId'];
//         final otherPublicKey = entry['publicKey'];
//
//         try {
//           final encryptedAes = RSAUtil.encryptKey(aesKeyB64, otherPublicKey);
//           encryptedAesList.add({
//             "userId": otherUserId,
//             "encryptedAesKey": encryptedAes,
//           });
//         } catch (e) {
//           print('Error encrypting AES key for $otherUserId: $e');
//         }
//       }
//
//       // 🔹 4. Mã hóa nội dung tin nhắn
//       final encryptedMessage = await AESUtil.encrypt(userMessage, aesKeyB64);
//
//       // 🔹 5. Gửi tin nhắn đến backend
//       final sendResponse = await http.post(
//         Uri.parse('$apiBaseUrl/sendMessage'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'chatId': currentChat?.id,
//           'sender': userId,
//           'text': encryptedMessage,
//           'encryptAes': encryptedAesList,
//         }),
//       );
//
//       if (sendResponse.statusCode == 200) {
//         print('Message sent successfully');
//       } else {
//         print('Failed to send message: ${sendResponse.body}');
//       }
//     } catch (e) {
//       print('Error sending message: $e');
//     }
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../ui/chat_widget.dart';
import '../../index.dart';
import 'index.dart';
import '../../crypto_utils.dart';

Future<void> sendMessage(
    Function setState,
    ScrollController scrollController,
    ) async {
  if (controller.text.trim().isEmpty || selectedImages.isNotEmpty) return;

  final chatId = currentChat?.id;
  if (chatId == null) return;

  final String plain = controller.text.trim();
  final String tempId = const Uuid().v4();

  // 1) Optimistic bubble
  final optimistic = {
    "_id": tempId,
    "text": plain,                       // hiển thị bản rõ cho người gửi
    "sender": userId,
    "images": [],
    "captions": null,
    "isTyping": false,
    "timestamp": DateTime.now().toIso8601String(),
    "status": "sending",
  };

  // Tắt bubble "typing"
  currentChat?.messages = currentChat!.messages.map((m) {
    if (m["isTyping"] == true) m["isTyping"] = false;
    return m;
  }).toList();

  setState(() {
    currentChat?.messages.add(optimistic);
  });
  scrollToBottom(scrollController);
  controller.clear();

  try {
    // 2) Lấy otherpublickey (nên cache ở nơi khác sau này)
    final ures = await http
        .get(Uri.parse('$apiBaseUrl/user/$userId'))
        .timeout(const Duration(seconds: 10));
    if (ures.statusCode != 200) {
      throw Exception('GET /user failed: ${ures.body}');
    }
    final userData = jsonDecode(ures.body);

    // 3) Tạo khóa AES phiên
    final aesKeyB64 = AESUtil.generateKeyBase64();

    // 4) Mã hóa AES key cho từng người nhận (cho phép rỗng)
    final List<Map<String, dynamic>> encryptedAesList = [];
    for (final entry in (userData['otherpublickey'] as List)) {
      final otherUserId = entry['userId'];
      final otherPub = entry['publicKey'];
      try {
        final encKey = RSAUtil.encryptKey(aesKeyB64, otherPub);
        encryptedAesList.add({
          "userId": otherUserId,
          "encryptedAesKey": encKey,
        });
      } catch (_) {
        // bỏ qua người nhận bị lỗi mã hóa
      }
    }

    // 5) Mã hóa nội dung
    final cipherText = await AESUtil.encrypt(plain, aesKeyB64);

    // 6) Gửi tới backend
    final payload = {
      'chatId': chatId,
      'sender': userId,
      'text': cipherText,
      'encryptAes': encryptedAesList,     // có thể []
      'clientMessageId': tempId,          // => yêu cầu backend phát lại trong WS
    };

    final resp = await http
        .post(
      Uri.parse('$apiBaseUrl/sendMessage'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    )
        .timeout(const Duration(seconds: 12));

    if (resp.statusCode == 200) {
      // Không chèn message mới vào UI ở đây.
      // Chỉ chuyển trạng thái cho bubble tạm -> "sent".
      setState(() {
        final ix = currentChat!.messages.indexWhere((m) => m["_id"] == tempId);
        if (ix != -1) currentChat!.messages[ix]["status"] = "sent";
      });
    } else {
      throw Exception('POST /sendMessage failed: ${resp.body}');
    }
  } catch (e) {
    // 7) Rollback trạng thái nếu lỗi
    setState(() {
      final ix = currentChat!.messages.indexWhere((m) => m["_id"] == tempId);
      if (ix != -1) currentChat!.messages[ix]["status"] = "failed";
    });
  } finally {
    scrollToBottom(scrollController);
  }
}
