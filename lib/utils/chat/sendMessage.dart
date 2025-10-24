import '../../ui/chat_widget.dart';
import '../../index.dart';
import 'index.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../crypto_utils.dart';
Future<void> sendMessage(Function setState, ScrollController scrollController) async {
  if (controller.text.isNotEmpty && selectedImages.isEmpty) {
    String userMessage = controller.text;

    // Cập nhật UI
    var newMessage = {
      "text": userMessage,
      "sender": userId,
      "images": [],
      "captions": null,
      "isTyping": false,
    };

    currentChat?.messages = currentChat!.messages.map((message) {
      if (message["isTyping"] == true) message["isTyping"] = false;
      return message;
    }).toList();

    setState(() {
      currentChat?.messages.add(newMessage);
    });

    scrollToBottom(scrollController);
    controller.clear();

    try {
      // 🔹 1. Lấy thông tin người dùng (để lấy danh sách otherpublickey)
      final response = await http.get(Uri.parse('$apiBaseUrl/user/$userId'));
      if (response.statusCode != 200) {
        print('Failed to fetch user info: ${response.body}');
        return;
      }

      final userData = jsonDecode(response.body);
      print('User Info: $userData');

      // 🔹 2. Tạo AES key base64
      final aesKeyB64 = AESUtil.generateKeyBase64();

      // 🔹 3. Mã hóa AES key bằng public key của từng người
      List<Map<String, dynamic>> encryptedAesList = [];

      for (var entry in userData['otherpublickey']) {
        final otherUserId = entry['userId'];
        final otherPublicKey = entry['publicKey'];

        try {
          final encryptedAes = RSAUtil.encryptKey(aesKeyB64, otherPublicKey);
          encryptedAesList.add({
            "userId": otherUserId,
            "encryptedAesKey": encryptedAes,
          });
        } catch (e) {
          print('Error encrypting AES key for $otherUserId: $e');
        }
      }

      // 🔹 4. Mã hóa nội dung tin nhắn
      final encryptedMessage = await AESUtil.encrypt(userMessage, aesKeyB64);

      // 🔹 5. Gửi tin nhắn đến backend
      final sendResponse = await http.post(
        Uri.parse('$apiBaseUrl/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chatId': currentChat?.id,
          'sender': userId,
          'text': encryptedMessage,
          'encryptAes': encryptedAesList,
        }),
      );

      if (sendResponse.statusCode == 200) {
        print('Message sent successfully');
      } else {
        print('Failed to send message: ${sendResponse.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}
