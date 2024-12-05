import '../../ui/chat_widget.dart';
import '../../index.dart';
void scrollToBottom() {
  if (scrollController.hasClients) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}