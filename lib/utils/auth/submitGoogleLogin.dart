import 'package:namer_app/ui/chat_widget.dart';
import '../../ui/auth_widget.dart';
import '../../index.dart';

// Hàm đăng nhập bằng Google
Future<void> signInWithGoogle(BuildContext context) async {
  try {
    // Bắt đầu quá trình đăng nhập
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      // Người dùng hủy bỏ quá trình đăng nhập
      return;
    }

    // Lấy thông tin chứng thực từ Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Tạo thông tin chứng thực mới cho Firebase
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Đăng nhập với Firebase bằng thông tin chứng thực từ Google
    final UserCredential userCredential = await auth.signInWithCredential(credential);

    // Kiểm tra đăng nhập thành công
    if (userCredential.user != null) {
      print("Đăng nhập thành công với Google: ${userCredential.user?.email}");
      // Điều hướng đến màn hình khác sau khi đăng nhập thành công
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen()),
      );
    }
  } catch (e) {
    print('Lỗi khi đăng nhập với Google: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Đăng nhập bằng Google thất bại.'),
    ));
  }
}
