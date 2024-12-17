import '../index.dart';
import '../ui/chat_widget.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

Widget buildMessageList(ScrollController scrollController, bool isTyping) {
  // Kiểm tra xem chat có null hoặc không có tin nhắn
  if (currentChat == null || currentChat!.messages.isEmpty) {
    return Center(child: Text('Let’s chat!'));
  }

  return ListView.builder(
    controller: scrollController,
    itemCount: currentChat!.messages.length + (isTyping ? 1 : 0), // Thêm 1 nếu đang hiển thị hiệu ứng typing
    itemBuilder: (context, index) {
      if (isTyping && index == currentChat!.messages.length) {
        // Hiển thị hiệu ứng typing
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5, // Chiều rộng tối đa 50%
              ),
              decoration: BoxDecoration(
                color: Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 0.5,
                    blurRadius: 5,
                    offset: Offset(2, 3),
                  ),
                ],
              ),
              child: LoadingAnimationWidget.waveDots(
                    size: 30, color:Colors.black,
                  ),
                ),
            ),
        );
      }

      bool isMe = currentChat!.messages[index]["sender"] == "Me";

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.all(10.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            decoration: BoxDecoration(
              color: isMe ? Color(0xFFC7E4FF) : Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 0.5,
                  blurRadius: 5,
                  offset: Offset(2, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentChat!.messages[index]["text"] != null)
                  MarkdownBody(
                    data: '${currentChat!.messages[index]["text"]}',
                  ),
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
                              if (image['status'] == 'uploading')
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.5),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
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
