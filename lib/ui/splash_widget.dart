import 'index.dart';
import '../index.dart';

class SplashScreen extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnAuth();
  }

  // Hàm kiểm tra đăng nhập và điều hướng
  Future<void> _navigateBasedOnAuth() async {
    await Future.delayed(Duration(seconds: 1)); // Thời gian hiển thị splash screen

    // Kiểm tra xem người dùng đã đăng nhập hay chưa
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Nếu người dùng đã đăng nhập, điều hướng đến HomePage
      userId = currentUser.uid;
      userEmail = currentUser.email!;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => ChatScreen()),
      );
    } else {
      // Nếu người dùng chưa đăng nhập, điều hướng đến LoginPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    }
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
    // return Scaffold(
    //   body: Container(
    //     decoration: BoxDecoration(
    //       color: Color(0xFF2d4665), // Màu nền chính xác như trong cấu hình
    //       image: DecorationImage(
    //         image: AssetImage('assets/icon/shirmp_removebng.png'),
    //         fit: BoxFit.contain, // Có thể điều chỉnh fit cho phù hợp (e.g., cover, contain)
    //       ),
    //     ),
    //   ),
    // );
  }
}
