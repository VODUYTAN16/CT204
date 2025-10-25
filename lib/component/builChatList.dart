import 'package:http/http.dart' as http;

import '../index.dart';
import '../ui/chat_widget.dart';
import '../utils/chat/index.dart';

Future<List<Widget>> buildChatList(List<Chat> chatListData,BuildContext context, Function setState, ScrollController scrollController) async {
  return chatList.reversed.map((chat) {
    bool isCurrentChat = currentChat == chat;
    return Column(
      children: [
        Container(
          color: isCurrentChat ? Color(0xFFC7E4FF) : Colors.transparent,
          child: ListTile(
            title: chat.isEditing
                ? TextField(
              controller: TextEditingController(text: chat.title),
              onSubmitted: (value) async {
                setState(() {
                  chat.title = value;
                  chat.isEditing = false;
                });
                await firestore.collection('chats').doc(chat.id).update({
                  'title': value,
                });
              },
              decoration: InputDecoration(hintText: 'Nhập tiêu đề mới'),
            )
                : Text(chat.title),

    // Giả sử bạn có WsManager ws; và currentChat có thể null lần đầu
    onTap: () async {
    final String? prevId = currentChat?.id;
    final String newId = chat.id;

    // Nếu bấm lại đúng phòng đang mở thì chỉ đóng drawer/menu
    if (prevId == newId) {
    Navigator.of(context).pop();
    return;
    }

    // 1) Cập nhật phòng hiện tại cho UI phản hồi ngay
    setState(() {
    currentChat = chat;
    currentChat!.messages = [];        // tùy chọn: xóa tạm để tránh chồng nội dung
    });

    // 2) Tải lịch sử phòng mới
    await fetchMessages(newId, setState);

    // 3) Chuyển subscription WebSocket sang phòng mới (không đóng kết nối)
    wsSingleton.subscribe(newId);

    // 4) Cuộn xuống và đóng menu
    scrollToBottom(scrollController);
    Navigator.of(context).pop();
    },

    // onTap: () {
            //   setState(() {
            //     currentChat = chat;
            //     scrollToBottom(scrollController);
            //   });
            //   fetchMessages(chat.id, setState);
            //   Navigator.of(context).pop();
            // },

            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz),
              onSelected: (value) async {
                if (value == 'edit') {
                  setState(() {
                    chat.isEditing = true;
                  });
                } else if (value == 'delete') {
                  if (chatList.length > 1) { // Kiểm tra số lượng chat
                    setState(() {
                      chatList.remove(chat);
                    });
                    final response = await http.delete(
                      Uri.parse('${apiBaseUrl}/deleteChat/${chat.id}'),
                    );

                    if (response.statusCode == 200) {
                      print('Đã xóa chat thành công');
                    } else {
                      print('Lỗi xóa chat: ${response.body}');
                    }

                  } else {
                    // Hiển thị thông báo không thể xóa bằng Overlay
                    final overlay = Overlay.of(context);
                    final overlayEntry = OverlayEntry(
                      builder: (context) {
                        // Tính toán vị trí căn giữa
                        final screenWidth = MediaQuery.of(context).size.width;
                        return Positioned(
                          top: MediaQuery.of(context).padding.top + 50, // Độ cao từ trên xuống
                          left: (screenWidth - 300) / 2, // Căn giữa (300 là chiều rộng của Container)
                          child: Material(
                            elevation: 4.0,
                            child: Container(
                              width: 300, // Đặt chiều rộng cho Container
                              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                              ),
                              child: Center(
                                child: Text(
                                  'Không thể xóa cuộc trò chuyện cuối cùng!',
                                  style: TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center, // Căn giữa văn bản
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );

                    overlay.insert(overlayEntry);

                    // Thời gian hiển thị
                    Future.delayed(Duration(seconds: 3), () {
                      overlayEntry.remove();
                    });
                  }
                }

              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Chỉnh sửa'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Xóa'),
                  ),
                ];
              },
            ),
          ),
        ),
        Divider(
          color: Colors.grey[300], // Màu nhạt cho đường line
          thickness: 1.0,           // Độ dày của đường line
          height: 0.5,              // Khoảng cách giữa các đường line
          indent: 16.0,             // Khoảng cách từ mép trái
          endIndent: 16.0,          // Khoảng cách từ mép phải
        ),
      ],
    );
  }).toList();
}