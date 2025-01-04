import '../../ui/chat_widget.dart';
import '../../index.dart';
import 'index.dart';

Future<void> sendMessage(Function setState, ScrollController scrollController) async {
  if (controller.text.isNotEmpty && selectedImages.isEmpty) {
    String userMessage = controller.text;
    var newMessage = {
      "text": userMessage,
      "sender": "Me",
      "images": [],
      "captions": null,
      "isTyping": false
    };
// Ngưng typing toàn bộ
    currentChat?.messages = currentChat!.messages.map((message) {
      if (message["isTyping"] == true) {
        message["isTyping"] = false; // Thay đổi isTyping thành false
      }
      return message;
    }).toList();

    //Cập nhật giao diện với tin nhắn mới
    setState(() {
      currentChat?.messages.add(newMessage);
      isTyping = true;
    });

    scrollToBottom(scrollController); // Cuộn tới cuối danh sách tin nhắn
    controller.clear(); // Xóa nội dung trong ô nhập tin nhắn
    botReply(newMessage, setState, scrollController); // Gọi hàm trả lời của bot (nếu có)
    // setState(() {
    //   isTyping = false; // Ẩn hiệu ứng typing khi bot trả lời xong
    // });
    await firestore.collection('chats').doc(currentChat?.id).update({
      'messages': currentChat?.messages
    });
  }
}
