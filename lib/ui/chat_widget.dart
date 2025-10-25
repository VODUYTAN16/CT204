import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../component/builChatList.dart';
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

    // 1) Kết nối WS một lần qua singleton (idempotent: connect sẽ tự bỏ qua nếu đã mở)
    wsSingleton.connect(onEvent: (evt) => _onWsEvent(evt));

    // 2) Tải danh sách + subscribe phòng đầu tiên (loadUserChats không cần truyền ws)
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await loadUserChats(setState);      // bỏ tham số ws
    scrollToBottom(scrollController);
    // nếu bạn muốn chắc chắn đã subscribe ngay tại đây:
    final id = currentChat?.id;
    if (id != null) wsSingleton.subscribe(id);
  }

  void _onWsEvent(Map evt) async {
    try{

      if (evt['type'] != 'message') return;
      if (evt['chatId'] != currentChat?.id) return;

      final msg = Map<String, dynamic>.from(evt['message']);
      print("////////////////////////////////////////////////websocket//////////////////////////////");
      print(msg);
      print(msg['sender']);
      // 🟢 Thêm điều kiện này để bỏ qua tin nhắn do chính mình gửi
      if (msg['sender'] == userId) return;

      final privateKeyPem = await getPrivateKey(userId);
      if (privateKeyPem == null) return;  // phòng thủ

      final encForMe = (msg['encryptAes'] as List?)?.cast<Map>()
          .firstWhere((e) => e['userId'] == userId, orElse: () => {});

      if (encForMe!.isNotEmpty) {
        final aesKey = await RSAUtil.decryptKey(encForMe['encryptedAesKey'], privateKeyPem);
        msg['text'] = await AESUtil.decrypt(msg['text'], aesKey);
      } else {
        msg['text'] = '[Không có khóa AES cho bạn]';
      }
      scrollToBottom(scrollController);

      setState(() {
        final exists = currentChat!.messages.any((m) => m['_id'] == msg['_id']);
        if (!exists) currentChat!.messages.add(msg);
      });
    }
    catch(e){print('Lỗi _onWsEvent');}

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
          shrinkWrap: true,
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
                        // createNewChat đã set currentChat
                        final String? newId = currentChat?.id;
                        if (newId != null) {
                          await fetchMessages(newId, setState); // thường rỗng
                          wsSingleton.subscribe(newId);         // subscribe phòng mới
                        }
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
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5, // hoặc 400, 500 tuỳ ý
              child: FutureBuilder<List<Chat>>(
                future: fetchUserChats(setState),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Có lỗi xảy ra!'));
                  } else if (snapshot.hasData) {
                    final chatListData = snapshot.data!;
                    return FutureBuilder<List<Widget>>(
                      future: buildChatList(chatListData, context, setState, scrollController),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (snapshot.hasData) {
                          return ListView(
                            shrinkWrap: true,
                            children: snapshot.data!,
                          );
                        } else {
                          return Center(child: Text('No chats available'));
                        }
                      },
                    );
                  }
                  return Center(child: Text('Không có chat nào!'));
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(child: buildMessageList(scrollController, isTyping, setState)),
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
                shrinkWrap: true,
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
