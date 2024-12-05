import '../../ui/auth_widget.dart';
import '../../index.dart';
import 'index.dart';

Future<void> submitPhoneLogin(String phoneNumber, BuildContext context) async {
  await auth.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    verificationCompleted: (PhoneAuthCredential credential) async {
      // Auto-retrieval case (Android only)
      UserCredential userCredential = await auth.signInWithCredential(credential);
      navigateToChat(userCredential.user, context);
    },
    verificationFailed: (FirebaseAuthException e) {
      showError(e.message ?? 'Đăng nhập thất bại', context);
    },
    codeSent: (String verificationId, int? resendToken) async {
      verificationId = verificationId;
      await showOtpDialog(verificationId, context);
    },
    codeAutoRetrievalTimeout: (String verificationId) {
      verificationId = verificationId;
    },
  );
}
