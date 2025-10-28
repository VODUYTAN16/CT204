
import '../index.dart';
import 'index.dart';

class ProfilePage extends StatelessWidget {
  // Giả định có các thuộc tính này để hiển thị

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin cá nhân'),
      ),
      body: Center(
        child :Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(avatarUrl),
              ),
              SizedBox(height: 16),
              Text(
                userName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                userEmail,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Chuyển tới trang chỉnh sửa hồ sơ
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfilePage()),
                  );
                },
                icon: Icon(Icons.edit),
                label: Text('Chỉnh sửa hồ sơ'),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showLogoutConfirmationDialog(context),
                icon: Icon(Icons.logout),
                label: Text('Đăng xuất'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Đăng xuất'),
        content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy')),
          TextButton(
            onPressed: () async {
              await logout();           // ⬅️ KHÔNG cần setState/context ở đây
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => AuthScreen()),
              );
            },
            child: Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

// logout không nhận setState/context
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      // Hủy WS
      try {
        wsSingleton.dispose();
      } catch (_) {}

      // Dọn state global
      currentChat = null;
      currentChatIsGroup = false;
      currentChatPeerAvatarPath = null;
      chatList = [];
      selectedImages.clear();
      isTyping = false;
      controller.clear();

      // (tùy chọn) xoá token local, cache...
    } catch (e) {
      print('Lỗi đăng xuất: $e');
    }
  }}