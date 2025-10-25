// import '../../ui/chat_widget.dart';
// import '../../index.dart';
// import 'index.dart';
// Future<void> loadUserChats(Function setState, WsManager ws) async {
//   List<Chat> userChats = await fetchUserChats(setState); // Gọi hàm lấy danh sách chat
//   print(userChats);
//   setState(() {
//     chatList = userChats; // Cập nhật danh sách chat
//     if (chatList.isNotEmpty) {
//       currentChat = chatList.last;
//     }else{
//       createNewChat('Tin nhắn mới', setState);
//     }
//   });
// }
// load_user_chats.dart (ví dụ)
import '../../ui/chat_widget.dart';
import '../../index.dart';     // nơi có wsSingleton, currentChat, chatList, userId...
import 'index.dart';          // fetchUserChats, fetchMessages, createNewChat

Future<void> loadUserChats(Function setState) async {
  final List<Chat> userChats = await fetchUserChats(setState);

  if (userChats.isNotEmpty) {
    final Chat last = userChats.last;

    setState(() {
      chatList = userChats;
      currentChat = last;
      currentChat!.messages = [];          // dọn UI tạm
    });

    await fetchMessages(last.id, setState); // tải lịch sử
    wsSingleton.subscribe(last.id);         // bật realtime cho phòng hiện tại
  } else {
    // Tạo phòng mới
    await createNewChat('Tin nhắn mới', setState);

    // createNewChat đã set currentChat
    final String? newId = currentChat?.id;
    if (newId != null) {
      await fetchMessages(newId, setState); // thường rỗng
      wsSingleton.subscribe(newId);         // subscribe phòng mới
    }
  }
}
