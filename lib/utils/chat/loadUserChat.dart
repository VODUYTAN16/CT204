import '../../ui/chat_widget.dart';
import '../../index.dart';
import 'index.dart';
Future<void> loadUserChats(Function setState) async {
  List<Chat> userChats = await fetchUserChats(setState); // Gọi hàm lấy danh sách chat
  print(userChats);
  setState(() {
    chatList = userChats; // Cập nhật danh sách chat
    if (chatList.isNotEmpty) {
      currentChat = chatList.last;
    }else{
      createNewChat('Tin nhắn mới', setState);
    }
  });
}
