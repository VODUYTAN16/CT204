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
            onTap: () {
              setState(() {
                currentChat = chat;
                scrollToBottom(scrollController);
              });
              fetchMessages(chat.id, setState);
              Navigator.of(context).pop();
            },
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
                    await firestore.collection('chats').doc(chat.id).delete();
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
