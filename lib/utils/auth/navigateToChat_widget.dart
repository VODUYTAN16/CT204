import '../../index.dart';
import '../../ui/index.dart';
void navigateToChat(String uid,BuildContext context) {
  if (uid != null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen()),
    );
  }
}