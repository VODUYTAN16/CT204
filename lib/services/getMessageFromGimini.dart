import '../ui/chat_widget.dart';
import '../index.dart';
import '../utils/chat/index.dart';
import 'package:http/http.dart' as http;
Future<String?> sendToGimini(String userMessage, ScrollController scrollController) async {
  scrollToBottom(scrollController);

  if (apiKey.isEmpty) {
    print('No API_KEY provided.');
    return 'Sorry, API key is missing.';
  }

  final model = GenerativeModel(
    model: 'gemini-1.5-flash', // Model của Gemini
    apiKey: apiKey,
  );

  // Lấy lịch sử tin nhắn gần nhất
  final List<String> messageHistory = [];
  if (currentChat?.messages != null && currentChat!.messages.length > 1) {
    // Lấy tối đa 10 tin nhắn gần nhất
    // final recentMessages = currentChat!.messages
    //     .sublist((currentChat!.messages.length - 100).clamp(0,
    //     currentChat!.messages.length - 2)); // Đảm bảo không vượt quá chỉ số
    // for (var msg in recentMessages) {
    //   // Chỉ thêm tin nhắn nếu không rỗng
    //   if (msg["text"] != null &&
    //       msg["text"].isNotEmpty) { // Kiểm tra phần text
    //     messageHistory.add(
    //         msg["text"].toString()); // Thêm phần text vào messageHistory
    //   }
    // }
    final url = Uri.parse('http://192.168.1.8:5000/api/v1/messages/send'); // API của bạn

    try {
      // Chuyển currentChat!.messages sang JSON
      final body = jsonEncode({
        "messages": [
          {
            "captions": null,
            "images": [],
            "sender": "Me",
            "text": "mình nuôi tôm kết hợp với trồng lúa"
          }
        ]
      });

      // Thực hiện POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Đảm bảo header là JSON
        },
        body: body,
      );

      // Xử lý phản hồi từ server
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        print('Phản hồi từ server: ${data['answer']}');
        if (data['answer'] != null && data['answer'].isNotEmpty) {
          return data['answer'];
        } else {
          print('Error: No response from the API.');
          return 'Sorry, something went wrong.';
        }
      } else {
        print('Lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
    }
  }

  // Tạo prompt với lịch sử tin nhắn
  final prompt = 'Bạn có thể tham khảo lịch sử trò chuyện: $messageHistory : để trả lời câu hỏi: "${userMessage} "\n :Phản hồi bằng tiếng việt';

  // final response = await model.generateContent([Content.text(prompt)]);

  // if (response != null && response.text!.isNotEmpty) {
  //   return response.text;
  // } else {
  //   print('Error: No response from the API.');
  //   return 'Sorry, something went wrong.';
  // }

}


