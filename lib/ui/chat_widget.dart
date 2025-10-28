import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../component/builChatList.dart';
import '../index.dart';
import 'index.dart';
import '../utils/chat/index.dart';
late List<Chat> chatList = [];
Chat? currentChat;
// Dùng cho direct chat: avatar của người bên kia để hiển thị trên AppBar
String? currentChatPeerAvatarPath;
// Đánh dấu loại hội thoại
bool currentChatIsGroup = false;
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
  bool _booting = true; // ⬅️ trạng thái khởi động
  @override
  void initState() {
    super.initState();
    wsSingleton.connect(onEvent: (evt) => _onWsEvent(evt));
    // _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await loadUserChats(setState); // sẽ set currentChat nếu có
      final id = currentChat?.id;
      if (id != null) wsSingleton.subscribe(id);
      scrollToBottom(scrollController);
    } finally {
      if (mounted) setState(() => _booting = false); // ⬅️ tắt splash
    }
  }

  void _onWsEvent(dynamic evt) async {
    try {
      // 0) Chuẩn hoá event thành Map
      Map<String, dynamic> e;
      if (evt is String) {
        e = jsonDecode(evt) as Map<String, dynamic>;
      } else if (evt is Map) {
        e = Map<String, dynamic>.from(evt);
      } else {
        print('[WS] Unknown event type: ${evt.runtimeType}');
        return;
      }

      // 1) Loại event
      final type = (e['type'] ?? e['event'] ?? '').toString();
      if (type != 'message') {
        // Debug nhẹ để biết có event khác lọt vào
        // print('[WS] ignore type=$type');
        return;
      }

      // 2) Trùng phòng?
      final evConvId = (e['conversationId'] ?? e['chatId'] ?? e['roomId'] ?? '')
          .toString();
      if (evConvId.isEmpty || evConvId != (currentChat?.id ?? '')) {
        // print('[WS] event for other room: $evConvId');
        return;
      }

      // 3) Lấy object message (nếu server bọc trong "message")
      final raw = (e['message'] is Map)
          ? Map<String, dynamic>.from(e['message'])
          : Map<String, dynamic>.from(e);

      // 4) Bỏ qua tin của chính mình
      final senderId = (raw['senderId'] ?? raw['sender'])?.toString();
      if (senderId == userId) return;

      // 5) Giải mã text
      final privateKeyPem = await getPrivateKey(userId);
      if (privateKeyPem == null) {
        print('[WS] No privateKey for $userId');
        return;
      }

      String decryptedText = '[Không có khóa AES cho bạn]';

      final encList = (raw['encryptAes'] as List?)?.cast<Map>();
      if (encList != null && encList.isNotEmpty) {
        final encForMe = encList.firstWhere(
              (m) => (m['userId']?.toString() == userId),
          orElse: () => const {},
        );
        if (encForMe.isNotEmpty) {
          final aesKey = await RSAUtil.decryptKey(
              encForMe['encryptedAesKey'], privateKeyPem);
          decryptedText =
          await AESUtil.decrypt(raw['text']?.toString() ?? '', aesKey);
        }
      } else {
        // Fallback: gọi /messages/key
        final mid = (raw['_id'] ?? raw['id'] ?? '').toString();
        if (mid.isNotEmpty) {
          final keyUri = Uri.parse(
              '$apiBaseUrl/messages/key?messageId=$mid&userId=$userId');
          final keyResp = await http.get(keyUri).timeout(
              const Duration(seconds: 8));
          if (keyResp.statusCode >= 200 && keyResp.statusCode < 300) {
            final keyJson = jsonDecode(keyResp.body);
            final encAesKey = keyJson['encryptedAesKey']?.toString() ?? '';
            if (encAesKey.isNotEmpty) {
              final aesKey = await RSAUtil.decryptKey(encAesKey, privateKeyPem);
              decryptedText =
              await AESUtil.decrypt(raw['text']?.toString() ?? '', aesKey);
            }
          } else if (keyResp.statusCode == 404) {
            decryptedText = 'Tin nhắn ẩn';
          } else {
            decryptedText = '[Lỗi lấy khóa: ${keyResp.statusCode}]';
          }
        }
      }

      raw['text'] = decryptedText;
      raw['isTyping'] = false;
      raw['status'] ??= 'sent';
      raw['sender'] ??= senderId;


      // 6) Đỡ sẵn profile (Hướng A)
      final sp = raw['senderProfile'];
      if (sp is Map) {
        raw['name'] = (sp['name']?.toString() ?? '').trim();
        raw['email'] = (sp['email']?.toString() ?? '').trim();
        raw['avatar'] = (sp['avatar']?.toString() ?? '').trim();
      }

      // 7) Nhét vào UI nếu chưa có
      final exists = currentChat?.messages.any((m) =>
      m['_id']?.toString() == (raw['_id']?.toString())) ?? false;
      if (!exists) {
        if (!mounted) return;
        setState(() => currentChat?.messages.add(raw));
        scrollToBottom(scrollController);
      }
    } catch (e, st) {
      print('[_onWsEvent] error: $e');
      print(st);
    }
  }

  // Hàm kiểm tra tất cả ảnh đều đã được upload
  bool _allImagesUploaded() {
    return selectedImages.every((img) => img['status'] == 'uploaded');
  }

  @override
  Widget build(BuildContext context) {
    final bool hasChat = currentChat != null;
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
      drawer: SocialDrawer(
        setRootState: setState,
        scrollController: scrollController,
      ),
      body: hasChat
          ? Column(
        children: <Widget>[
          Expanded(
              child: buildMessageList(scrollController, isTyping, setState)),
          _buildComposer(),
          if (selectedImages.isNotEmpty) _buildSelectedImages(),
        ],
      )
          : _buildSplash(), // ⬅️ Mặc định hiện GIF
    );
  }
  Widget _buildSplash() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset('assets/splash.gif', fit: BoxFit.cover),
    );
  }


  Widget _buildComposer() {
    if (currentChat == null) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          IconButton(icon: const Icon(Icons.camera_alt),
              onPressed: () => pickImage(ImageSource.camera, setState)),
          IconButton(icon: const Icon(Icons.photo),
              onPressed: () => pickImage(ImageSource.gallery, setState)),
          Expanded(child: TextField(controller: controller,
              decoration: const InputDecoration(hintText: 'Tin nhắn'))),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _allImagesUploaded()
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
    );
  }

  Widget _buildSelectedImages() {
    return SizedBox(
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
                              size: 30,
                              color: Colors.white,
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
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () => removeImage(image['url'], setState),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}
