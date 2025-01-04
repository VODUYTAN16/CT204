import '../ui/chat_widget.dart';
import '../index.dart';
import '../utils/chat/index.dart';
Future<void> fetchMessages(String chatId, Function setState) async {
  DocumentSnapshot chatDoc = await firestore.collection('chats')
      .doc(chatId)
      .get();

  if (chatDoc.exists) {
    setState(() {
      currentChat!.messages = List<Map<String, dynamic>>.from(
        (chatDoc['messages'] as List).cast<Map<String, dynamic>>(),
      ).map((message) {
        return {
          ...message,
          "isTyping": false,
        };
      }).toList();
    });
  }


}