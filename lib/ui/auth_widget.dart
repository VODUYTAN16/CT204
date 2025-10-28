import '../index.dart';
import 'index.dart';
import '../utils/auth/index.dart';

final FirebaseAuth auth = FirebaseAuth.instance;
// final GoogleSignIn googleSignIn = GoogleSignIn();
// final FirebaseFirestore firestore = FirebaseFirestore.instance;
final TextEditingController usernameController = TextEditingController();
final TextEditingController passwordController = TextEditingController();
final TextEditingController nameController = TextEditingController();


// bool isLogin = true; // True cho đăng nhập, false cho đăng ký
bool isPhoneLogin = false;
bool isLoginMode = true; // Biến thể hiện trạng thái đăng nhập hay đăng ký
bool isPasswordVisible = false;
String? verificationId;

class AuthScreen extends StatefulWidget {
  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  Future<void> _submit() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (isPhoneLogin) {
      // // Chuyển đổi số điện thoại sang định dạng E.164
      // String formattedPhoneNumber = '+84${username.substring(1)}'; // Bỏ số 0 đầu và thêm +84
      // // Đăng nhập/Đăng ký bằng số điện thoại
      // await submitPhoneLogin(formattedPhoneNumber, context);
    } else {
      // Đăng nhập/Đăng ký bằng email
      await submitEmailLogin(name, username, password, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9F5F2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 250, // Tăng chiều cao để có thêm không gian
                  child: Stack(
                    alignment: Alignment.center, // Căn giữa tất cả hình ảnh
                    children: [
                      // Hình ảnh lớn ở nền với bo góc
                      Positioned(
                        bottom: 10,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20), // Bo góc
                          child: Image.asset(
                            'assets/pic1.jpg',
                            width: 180,
                            height: 180,
                            fit: BoxFit.cover, // Cắt hình ảnh để vừa với bo góc
                          ),
                        ),
                      ),
                      // Hình ảnh nhỏ ở trên cùng bên trái với bo góc
                      Positioned(
                        left: 20,
                        top: 20,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20), // Bo góc
                          child: Image.asset(
                            'assets/pic2.jpg',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover, // Cắt hình ảnh để vừa với bo góc
                          ),
                        ),
                      ),
                      // Hình ảnh nhỏ ở dưới cùng bên phải với bo góc
                      Positioned(
                        right: 20,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20), // Bo góc
                          child: Image.asset(
                            'assets/pic3.jpg',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover, // Cắt hình ảnh để vừa với bo góc
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Trò chuyện cùng nhóm 3 người chúng tôi!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                // TextField nhập email hoặc số điện thoại
                if(!isLoginMode)
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Họ và tên',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: usernameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: isPhoneLogin ? 'Số điện thoại' : 'Địa chỉ email',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  ),
                ),
                SizedBox(height: 10), // Khoảng cách giữa hai TextField
                // TextField nhập mật khẩu hoặc mã OTP
                TextField(
                  controller: passwordController,
                  style: TextStyle(color: Colors.white),
                  obscureText: !isPasswordVisible, // Hiện hoặc ẩn mật khẩu dựa trên trạng thái
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white, // Màu của biểu tượng
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible; // Đảo ngược trạng thái khi nhấn
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(isLoginMode ? 'Đăng nhập' : 'Đăng ký'),
                ),
                SizedBox(height: 10),
                // ElevatedButton.icon(
                //   onPressed: () {
                //     setState(() {
                //       isPhoneLogin = !isPhoneLogin; // Thay đổi chế độ đăng nhập
                //     });
                //   },
                //   icon: Icon(Icons.phone, color: Colors.white),
                //   label: Text(isPhoneLogin ? 'Đăng nhập bằng email' : 'Đăng nhập bằng số điện thoại'),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.blue,
                //     padding: EdgeInsets.symmetric(vertical: 15),
                //   ),
                // ),
                SizedBox(height: 10),
                // Dòng chữ chuyển đổi chế độ đăng nhập/đăng ký
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isLoginMode = !isLoginMode; // Chuyển đổi giữa đăng nhập và đăng ký
                    });
                  },
                  child: Text(
                    isLoginMode ? 'Tôi chưa có tài khoản! Đăng ký' : 'Tôi đã có tài khoản! Đăng nhập',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Bằng cách đăng nhập, bạn đồng ý với Điều khoản Dịch vụ của chúng tôi và xác nhận rằng bạn đã đọc Chính sách quyền riêng tư của chúng tôi. Thông báo tại bộ sưu tập.',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
