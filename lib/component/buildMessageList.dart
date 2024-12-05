import '../index.dart';
import '../ui/chat_widget.dart';

Widget buildMessageList(ScrollController scrollController) {

  // Kiểm tra xem chat có null hoặc không có tin nhắn
  if (currentChat == null || currentChat!.messages.isEmpty) {
    return Center(child: Text('Let’s chat!'));
  }

  return ListView.builder(
    controller: scrollController,
    itemCount: currentChat!.messages.length,
    itemBuilder: (context, index) {
      bool isMe = currentChat!.messages[index]["sender"] == "Me";

      return Padding( // Thêm Padding cho mỗi tin nhắn
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.all(10.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85, // Chiều rộng tối đa 85%
            ),
            decoration: BoxDecoration(
              color: isMe ? Color(0xFFC7E4FF) : Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3), // Màu bóng với độ trong suốt
                  spreadRadius: 0.5, // Độ lan rộng của bóng
                  blurRadius: 5, // Độ mờ của bóng
                  offset: Offset(2, 3), // Vị trí bóng (x, y)
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị văn bản nếu có
                if (currentChat!.messages[index]["text"] != null)
                  MarkdownBody(
                    data: '${currentChat!.messages[index]["text"]}',
                  ),
                // Hiển thị hình ảnh
                if (currentChat!.messages[index]["images"] is List)
                  Column(
                    children: [
                      for (var image in currentChat!.messages[index]["images"])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  image['url'],
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              if (image['status'] == 'uploading') // Check if uploading
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.5),
                                    child: Center(
                                      child: CircularProgressIndicator(), // Loading indicator
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                // Hiển thị caption nếu có
                if (currentChat!.messages[index]["caption"] != null)
                  Padding(
                    padding: EdgeInsets.only(top: 5.0),
                    child: Text(
                      currentChat!.messages[index]["caption"],
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
