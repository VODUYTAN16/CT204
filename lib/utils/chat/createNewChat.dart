import '../../ui/chat_widget.dart';
import '../../index.dart';
import 'index.dart';

Future<void> createNewChat(newChatTitle, Function setState) async {
  if (newChatTitle != null && newChatTitle.isNotEmpty) {
    // Tạo một tài liệu chat trong Firestore
    String chatId = 'chat_${userId}_${DateTime
        .now()
        .millisecondsSinceEpoch}';

    setState(() {
      chatList.add(Chat(
        id: chatId,
        title: newChatTitle,
        messages: [],
      ));
      currentChat = chatList.last;
    });

    await firestore.collection('chats').doc(chatId).set({
      'id': chatId,
      'title': newChatTitle,
      'messages': [], // Khởi tạo danh sách tin nhắn rỗng
    });

    // Cập nhật tài liệu của người dùng để thêm chatId vào listChat
    await firestore.collection('users').doc(userId).update({
      'listChat': FieldValue.arrayUnion([chatId]), // Thêm chatId vào listChat
    });

  }
}
