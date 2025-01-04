import '../../ui/chat_widget.dart';
import '../../index.dart';
import 'index.dart';
Future<void> sendImagesWithCaption(Function setState, ScrollController scrollController) async {

  if (selectedImages.isNotEmpty && currentChat != null) {
    // Tạo một tin nhắn mới
    var newMessage = {
      "text": null,
      "sender": "Me",
      "images": selectedImages.map((image) {
        return {
          "url": image["url"], // 'url' là khóa chứa URL hình ảnh
          "status": "uploaded", // Đặt trạng thái là 'uploading'
        };
      }).toList(),
      "caption": controller.text.isNotEmpty ? controller.text : null,
      "isTyping": false
    };

    // Ngưng typing toàn bộ
    currentChat?.messages = currentChat!.messages.map((message) {
      if (message["isTyping"] == true) {
        message["isTyping"] = false; // Thay đổi isTyping thành false
      }
      return message;
    }).toList();

    // Cập nhật trạng thái trong ứng dụng
    setState(() {
      currentChat?.messages.add(newMessage);
      selectedImages.clear();
      controller.clear();
      isTyping = true;
    });

    scrollToBottom(scrollController);
    botReply(newMessage, setState, scrollController);

    // setState(() {
    //   isTyping = false; // Ẩn hiệu ứng typing khi bot trả lời xong
    // });

    await firestore.collection('chats').doc(currentChat!.id).update({
      'messages': currentChat?.messages
    });
  }
}
