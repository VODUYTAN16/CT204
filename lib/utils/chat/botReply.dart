import '../../ui/chat_widget.dart';
import '../../index.dart';
import 'index.dart';

void botReply(Object userMessage, Function setState, ScrollController scrollController) async {
  String? botResponse = await sendToGimini(userMessage, scrollController);

  setState(() {
    currentChat?.messages.add({
      "text": botResponse,
      "sender": "Bot",
      "images": [],
      "captions": [],
      "isTyping": true
    });
    isTyping = false;
  });
  scrollToBottom(scrollController);

  // setState(() {
  //   isTyping = false; // Ẩn hiệu ứng typing khi bot trả lời xong
  // });

  // Lọc các tin nhắn có isTyping là true và cập nhật giá trị của chúng thành false
// Thực hiện delay trước khi cập nhật tin nhắn
  await Future.delayed(Duration(seconds: 2), () async {
    // Lọc và cập nhật các tin nhắn có isTyping là true thành false
    currentChat?.messages = currentChat!.messages.map((message) {
      if (message["isTyping"] == true) {
        message["isTyping"] = false; // Thay đổi isTyping thành false
      }
      return message;
    }).toList();

    // Cập nhật mảng tin nhắn lên Firestore
    await firestore.collection('chats').doc(currentChat?.id).update({
      'messages': currentChat?.messages
    });
  });

}
