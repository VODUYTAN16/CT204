import '../../ui/chat_widget.dart';
import '../../index.dart';
import 'index.dart';
Future<void> sendMessage(Function setState) async {
  if (controller.text.isNotEmpty && selectedImages.isEmpty) {
    String userMessage = controller.text;

    //Cập nhật giao diện với tin nhắn mới
    setState(() {
      currentChat?.messages.add({
        "text": userMessage,
        "sender": "Me",
        "images": [],
        "captions": null,
      });
    });

    scrollToBottom(); // Cuộn tới cuối danh sách tin nhắn
    controller.clear(); // Xóa nội dung trong ô nhập tin nhắn
    botReply(userMessage, setState); // Gọi hàm trả lời của bot (nếu có)

    await firestore.collection('chats').doc(currentChat?.id).set({
      'messages': FieldValue.arrayUnion([
        {
          "text": userMessage,
          "sender": "Me",
          "images": [],
          "captions": null,
        }
      ]),
    }, SetOptions(merge: true));

  }
}
