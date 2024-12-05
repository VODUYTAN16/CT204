import '../../index.dart';
import '../../ui/index.dart';
void navigateToChat(User? user,BuildContext context) {
  if (user != null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen()),
    );
  }
}