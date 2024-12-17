import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../index.dart';
import 'index.dart';
import '../utils/chat/index.dart';
late List<Chat> chatList = [];
Chat? currentChat;
final TextEditingController controller = TextEditingController();
final ImagePicker picker = ImagePicker();
List<Map<String, dynamic>> selectedImages = [];
bool isTyping = false;

class ChatScreen extends StatefulWidget {
  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    loadUserChats(setState); // Gọi phương thức để tải danh sách chat
  }

  // Hàm kiểm tra tất cả ảnh đều đã được upload
  bool _allImagesUploaded() {
    return selectedImages.every((img) => img['status'] == 'uploaded');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF3F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(currentChat?.title ?? ''),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        backgroundColor: Color(0xFFEFF3F5),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF9CC6FF),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(avatarUrl), // Đường dẫn đến hình ảnh avatar
                  ),
                  SizedBox(width: 16), // Khoảng cách giữa avatar và text
                  GestureDetector(
                    onTap: () {
                      // Điều hướng đến trang mới khi nhấn vào avatar
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                    child: Text(
                      userName, // Thay thế bằng tên người dùng
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                // Kiểm tra nếu user là admin
                if (isAdmin)
                  Column(
                      children: [
                        Container(
                          child: InkWell(
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AdminScreen()),
                              );
                            },
                            splashColor: Colors.green.withOpacity(0.5),
                            highlightColor: Colors.green.withOpacity(0.3),
                            child: Container(
                              color: Colors.white,
                              child: ListTile(
                                title: Text('Upload File'),
                                leading: Icon(Icons.upload_file),
                                trailing: Icon(Icons.arrow_forward),
                              ),
                            ),
                          ),
                        ),
                        Divider(),
                      ]
                  ),
                Container(
                  child: InkWell(
                    onTap: () async {
                      final String? newChatTitle = await showNewChatDialog(context);
                      if (newChatTitle != null && newChatTitle.isNotEmpty) {
                        await createNewChat(newChatTitle, setState);
                        Navigator.of(context).pop();
                      }
                    },
                    splashColor: Colors.blue.withOpacity(0.5),
                    highlightColor: Colors.blue.withOpacity(0.3),
                    child: Container(
                      color: Colors.white,
                      child: ListTile(
                        title: Text('Tạo mới'),
                        leading: Icon(Icons.chat),
                        trailing: Icon(Icons.arrow_forward),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(),
            StreamBuilder<List<Chat>>(
              stream: _fetchUserChatsStream(userId), // Gọi hàm stream ở đây
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Có lỗi xảy ra!'));
                } else if (snapshot.hasData) {
                  final chatListData = snapshot.data!;
                  return Column(
                    children: [
                      FutureBuilder<List<Widget>>(
                        future: buildChatList(chatListData, context, setState,scrollController), // Gọi hàm này với danh sách chat
                        builder: (BuildContext context, AsyncSnapshot<List<Widget>> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else if (snapshot.hasData) {
                            return Column(
                              children: snapshot.data!,
                            );
                          } else {
                            return Center(child: Text('No chats available'));
                          }
                        },
                      ),
                    ],
                  );
                }
                return Center(child: Text('Không có chat nào!'));
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(child: buildMessageList(scrollController, isTyping)),
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.camera_alt),
                    onPressed: () => pickImage(ImageSource.camera, setState),
                  ),
                  IconButton(
                    icon: Icon(Icons.photo),
                    onPressed: () => pickImage(ImageSource.gallery, setState),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Tin nhắn',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: (_allImagesUploaded())
                        ? () {
                      sendMessage(setState, scrollController);
                      sendImagesWithCaption(setState, scrollController);
                      scrollToBottom(scrollController);
                    }
                        : null,
                    color: _allImagesUploaded() ? Colors.blue : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (selectedImages.isNotEmpty)
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedImages.length,
                itemBuilder: (context, index) {
                  final image = selectedImages[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: image['status'] == 'loading'
                              ? Stack(
                            children: [
                              Image.file(
                                File(image['url']),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withOpacity(0.5),
                                  child: Center(
                                    child: LoadingAnimationWidget.dotsTriangle(
                                      size: 30, color:Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                              : Image.network(
                            image['url'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: Icon(Icons.clear, color: Colors.red),
                            onPressed: () => removeImage(image['url'], setState),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// Thêm phương thức để lấy stream từ Firestore
Stream<List<Chat>> _fetchUserChatsStream(String userId) {
  return FirebaseFirestore.instance.collection('chats')
      .where('userId', isEqualTo: userId) // Thay đổi điều kiện nếu cần
      .snapshots()
      .map((snapshot) => snapshot.docs
      .map((doc) => Chat.fromDocument(doc)) // Giả sử bạn có phương thức để tạo Chat từ Document
      .toList());
}
