import '../../ui/chat_widget.dart';
import '../../index.dart';
import '../auth/showError.dart';
import 'index.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> createNewChat(String newChatTitle, Function setState) async {
  try {
    if (newChatTitle != null && newChatTitle.isNotEmpty) {
      // Gửi yêu cầu POST đến API backend để tạo chat
      print('-----------------------------------------------------------------------------------------------------------');
      print(newChatTitle);
      final response = await http.post(
        Uri.parse('${apiBaseUrl}/createNewChat'), // API MongoDB
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'newChatTitle': newChatTitle,  // Tiêu đề của cuộc trò chuyện mới
        }),
      );

      if (response.statusCode == 200) {
        // Nếu tạo chat thành công, cập nhật giao diện
        final newChatData = jsonDecode(response.body);
        final newChat = Chat(
          id: newChatData['chatId'],
          title: newChatData['title'],
          messages: [],
          isEditing: false,
        );

        setState(() {
          chatList.add(newChat);
          currentChat = chatList.last;
        });

        print('New chat created successfully');
      } else {
        print('Failed to create new chat: ${response.body}');
      }
    } else {
      print('Chat title cannot be empty:');
    }
  } catch (e) {
    print('Error: $e');
  }
}
