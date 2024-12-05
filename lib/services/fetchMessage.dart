import '../ui/chat_widget.dart';
import '../index.dart';
import '../utils/chat/index.dart';
Future<void> fetchMessages(String chatId, Function setState) async {
  DocumentSnapshot chatDoc = await firestore.collection('chats')
      .doc(chatId)
      .get();

  if (chatDoc.exists) {
    setState(() {
      // Cập nhật tin nhắn từ Firestore vào currentChat
      currentChat!.messages = List.from(chatDoc['messages'] ?? []);
    });}
}