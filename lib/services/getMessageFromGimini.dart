import '../ui/chat_widget.dart';
import '../index.dart';
import '../utils/chat/index.dart';
import 'package:http/http.dart' as http;
Future<String?> sendToGimini(Object userMessage, ScrollController scrollController) async {
  scrollToBottom(scrollController);

  if (currentChat?.messages != null && currentChat!.messages.isNotEmpty) {
    final url = Uri.parse('http://192.168.1.203:5000/api/v1/messages/send'); // API của bạn
    try {
      // Chuyển currentChat!.messages sang JSON
      final body = jsonEncode({ "messages": currentChat?.messages
      });
      print('body:' + body);

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

  return "Không phản hồi";

}


