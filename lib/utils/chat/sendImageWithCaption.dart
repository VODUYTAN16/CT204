import '../../ui/chat_widget.dart';
import '../../index.dart';
import 'index.dart';
Future<void> sendImagesWithCaption(Function setState) async {

  if (selectedImages.isNotEmpty && currentChat != null) {
    // Tạo một tin nhắn mới
    var newMessage = {
      "text": null,
      "sender": "Me",
      "images": selectedImages.map((image) {
        return {
          'url': image['url'], // 'url' là khóa chứa URL hình ảnh
          'status': 'uploaded', // Đặt trạng thái là 'uploading'
        };
      }).toList(),
      "caption": controller.text.isNotEmpty ? controller.text : null,
    };

    // Cập nhật trạng thái trong ứng dụng
    setState(() {
      currentChat?.messages.add(newMessage);
      selectedImages.clear();
      controller.clear();
    });

    scrollToBottom();
    botReply(controller.text, setState);

    await firestore.collection('chats').doc(currentChat!.id).update({
      'messages': FieldValue.arrayUnion([newMessage]),
    });
  }
}
