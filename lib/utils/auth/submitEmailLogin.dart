import '../../ui/auth_widget.dart';
import '../../index.dart';
import 'index.dart';
Future<void> submitEmailLogin(String email, String password, BuildContext context) async {
  try {
    if (isLoginMode) {
      // Đăng nhập bằng email
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      userId = userCredential.user!.uid;
      userEmail = userCredential.user!.email!;
      navigateToChat(userCredential.user, context);
    } else {
      // Đăng ký bằng email
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      userId = userCredential.user!.uid;
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'username': email,
        'userId': userCredential.user!.uid,
        'status': "member",
        'listChat': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      navigateToChat(userCredential.user, context);
    }
  } on FirebaseAuthException catch (e) {
    showError(e.message ?? 'Đăng nhập thất bại',context);
  }
}
