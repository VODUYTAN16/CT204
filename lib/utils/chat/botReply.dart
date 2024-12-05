import '../../ui/chat_widget.dart';
import '../../index.dart';
import 'index.dart';

void botReply(String userMessage, Function setState, ScrollController scrollController) async {
  String? botResponse = await sendToGimini(userMessage, scrollController);

  setState(() {
    currentChat?.messages.add({
      "text": botResponse,
      "sender": "Bot",
      "images": [],
      "captions": [],
    });
  });
  scrollToBottom(scrollController);

  await firestore.collection('chats').doc(currentChat?.id).update({
    'messages': FieldValue.arrayUnion([
      {
        "text": botResponse,
        "sender": "Bot",
        "images": [],
        "captions": null,
      }
    ]),
  });
}
