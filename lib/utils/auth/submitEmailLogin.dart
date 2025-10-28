import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../../ui/auth_widget.dart';
import '../../index.dart';
import 'index.dart';
import '../../crypto_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> submitEmailLogin(String name, String email, String password, BuildContext context) async {
  try {
    if (isLoginMode) {
      // Đăng nhập người dùng
      // Đăng nhập người dùng qua API (MongoDB)
      final response = await http.post(
        Uri.parse('${apiBaseUrl}/login'), // URL server của bạn
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password, // Mật khẩu đã mã hóa
        }),
      );


      if (response.statusCode == 200) {
        // Nếu đăng nhập thành công, parse dữ liệu người dùng từ response
        final userData = jsonDecode(response.body);
        userId = userData['uid'];
        userEmail = userData['email'];
        avatarUrl = userData['avatar'];
        userName = userData['name'];
        // Mã hóa AES key bằng RSA
        String? privateKeyString = await getPrivateKey(userId);
        if (privateKeyString != null ) {
          privateKey_RSA = privateKeyString;
        } else {
          print("Private key RSA not found!");
          showError('Private key not found!', context);
          return;
        }

        // Tiến hành các thao tác sử dụng privateKey như giải mã hoặc mã hóa
        print("Private key RSA loaded successfully!");
        navigateToChat(userId, context);
      } else {
        print('Login failed: ${response.body}');
        showError('Login failed', context);
      }
    } else {
      // Tạo cặp khóa RSA
      final receiverKeys = RSAUtil.generateKeys();
      final publicKey = receiverKeys['publicKeyPem']!;
      final privateKey = receiverKeys['privateKeyPem']!;
      print('Khóa riêng nè--------------------------------------');
      print(privateKey);
      privateKey_RSA = privateKey;

      // Tạo khóa AES
      // Lưu public key vào MongoDB thông qua API
      final apiResponse = await http.post(
        Uri.parse('${apiBaseUrl}/register'), // API để lưu public key
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'name':name,
          'password': password,
          'publicKey': publicKey,  // Lưu public key lên MongoDB
        }),
      );
      print(apiResponse.statusCode);

      final userData;

      if (apiResponse.statusCode == 200 || apiResponse.statusCode == 201) {
        print('Public key saved successfully');

        userData = jsonDecode(apiResponse.body);
        print(userData);
        userId = userData['uid'];
        avatarUrl = userData['avatar'];
        userName = userData['name'];
        // Lưu private key vào Flutter Secure Storage
        await storePrivateKey(privateKey, userId);
        // navigateToChat(userId, context);
      } else {
        userData = {
          'uid': userId,
          'email': null,
          'password': null,
          'publicKey': null,  // Lưu public key lên MongoDB
        };
        print('Failed to save public key: ${apiResponse.body}');
        showError('User already exists', context);
      }


    }
  } catch (e) {
    print('Error: $e');
    showError('User already exists', context);
  }
}
