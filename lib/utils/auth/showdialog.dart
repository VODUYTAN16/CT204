import '../../ui/auth_widget.dart';
import '../../index.dart';
import 'index.dart';

Future<void> showOtpDialog(String verificationId, BuildContext context) async {
  final TextEditingController _otpController = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text('Nhập mã OTP'),
        content: TextField(
          controller: _otpController,
          decoration: InputDecoration(hintText: 'Mã OTP'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final otpCode = _otpController.text.trim();
              if (otpCode.isNotEmpty && verificationId != null) {
                // Xác thực OTP
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                  verificationId: verificationId!,
                  smsCode: otpCode,
                );
                try {
                  UserCredential userCredential = await auth.signInWithCredential(credential);
                  if (!isLoginMode) {
                    userId = userCredential.user!.uid;
                    // Đăng ký người dùng nếu trong chế độ đăng ký
                    await firestore.collection('users').doc(userCredential.user!.uid).set({
                      'phoneNumber': userCredential.user!.phoneNumber,
                      'userId': userCredential.user!.uid,
                      'listChat': [],
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }
                  navigateToChat(userCredential.user, context);
                } on FirebaseAuthException catch (e) {
                  showError(e.message ?? 'Xác thực OTP thất bại', context);
                }
              } else {
                showError('Vui lòng nhập mã OTP', context);
              }
              Navigator.of(context).pop();
            },
            child: Text('Xác nhận'),
          ),
        ],
      );
    },
  );
}