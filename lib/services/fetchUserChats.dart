import '../ui/chat_widget.dart';
import '../index.dart';
import '../utils/chat/index.dart';

Future<List<Chat>> fetchUserChats(String userId) async {
  try {
    // Lấy thông tin người dùng từ Firestore
    DocumentSnapshot userDoc = await firestore.collection('users').doc(userId).get();
    if (userDoc['status'] != null) {
      // Kiểm tra nếu 'status' là một chuỗi và có giá trị 'admin'
      isAdmin = userDoc['status'].toString() == 'admin';
    }


    List<Chat> userChats = [];

    if (userDoc.exists) {
      // Lấy danh sách chatId từ trường listChat
      List<dynamic> chatIds = userDoc['listChat'] ?? [];

      // Lấy thông tin chi tiết của các chat một lần
      List<DocumentSnapshot> chatDocs = await Future.wait(
        chatIds.map((chatId) async {
          return await firestore.collection('chats').doc(chatId).get();
        }),
      );

      // Lặp qua từng chatDoc để tạo danh sách chat
      for (DocumentSnapshot chatDoc in chatDocs) {
        if (chatDoc.exists) {
          userChats.add(Chat(
            id: chatDoc.id, // Sử dụng id tài liệu Firestore
            title: chatDoc['title'], // Tiêu đề của chat
            messages: List.from(chatDoc['messages'] ?? []), // Danh sách tin nhắn (nếu có)
            isEditing: false, // Mặc định là không chỉnh sửa
          ));
        }
      }
    }

    return userChats;
  } catch (e) {
    print("Lỗi khi lấy danh sách chat: $e");
    return []; // Trả về danh sách rỗng trong trường hợp có lỗi
  }
}