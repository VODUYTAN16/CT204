// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:uuid/uuid.dart';
//
// import '../../ui/chat_widget.dart';
// import '../../index.dart';
// import 'index.dart';
// import '../../crypto_utils.dart';
//
// Future<void> sendMessage(
//     Function setState,
//     ScrollController scrollController,
//     ) async {
//   if (controller.text.trim().isEmpty || selectedImages.isNotEmpty) return;
//
//   final chatId = currentChat?.id;
//   if (chatId == null) return;
//
//   final String plain = controller.text.trim();
//   final String tempId = const Uuid().v4();
//
//   // 1) Optimistic bubble
//   final optimistic = {
//     "_id": tempId,
//     "text": plain,                       // hiển thị bản rõ cho người gửi
//     "sender": userId,
//     "images": [],
//     "captions": null,
//     "isTyping": false,
//     "timestamp": DateTime.now().toIso8601String(),
//     "status": "sending",
//   };
//
//   // Tắt bubble "typing"
//   currentChat?.messages = currentChat!.messages.map((m) {
//     if (m["isTyping"] == true) m["isTyping"] = false;
//     return m;
//   }).toList();
//
//   setState(() {
//     currentChat?.messages.add(optimistic);
//   });
//   scrollToBottom(scrollController);
//   controller.clear();
//
//   try {
//     // 2) Lấy otherpublickey (nên cache ở nơi khác sau này)
//     final ures = await http
//         .get(Uri.parse('$apiBaseUrl/user/$userId'))
//         .timeout(const Duration(seconds: 10));
//     if (ures.statusCode != 200) {
//       throw Exception('GET /user failed: ${ures.body}');
//     }
//     final userData = jsonDecode(ures.body);
//
//     // 3) Tạo khóa AES phiên
//     final aesKeyB64 = AESUtil.generateKeyBase64();
//
//     // 4) Mã hóa AES key cho từng người nhận (cho phép rỗng)
//     final List<Map<String, dynamic>> encryptedAesList = [];
//     for (final entry in (userData['otherpublickey'] as List)) {
//       final otherUserId = entry['userId'];
//       final otherPub = entry['publicKey'];
//       try {
//         final encKey = RSAUtil.encryptKey(aesKeyB64, otherPub);
//         encryptedAesList.add({
//           "userId": otherUserId,
//           "encryptedAesKey": encKey,
//         });
//       } catch (_) {
//         // bỏ qua người nhận bị lỗi mã hóa
//       }
//     }
//
//     // 5) Mã hóa nội dung
//     final cipherText = await AESUtil.encrypt(plain, aesKeyB64);
//
//     // 6) Gửi tới backend
//     final payload = {
//       'chatId': chatId,
//       'sender': userId,
//       'text': cipherText,
//       'encryptAes': encryptedAesList,     // có thể []
//       'clientMessageId': tempId,          // => yêu cầu backend phát lại trong WS
//     };
//
//     final resp = await http
//         .post(
//       Uri.parse('$apiBaseUrl/sendMessage'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(payload),
//     )
//         .timeout(const Duration(seconds: 12));
//
//     if (resp.statusCode == 200) {
//       // Không chèn message mới vào UI ở đây.
//       // Chỉ chuyển trạng thái cho bubble tạm -> "sent".
//       setState(() {
//         final ix = currentChat!.messages.indexWhere((m) => m["_id"] == tempId);
//         if (ix != -1) currentChat!.messages[ix]["status"] = "sent";
//       });
//     } else {
//       throw Exception('POST /sendMessage failed: ${resp.body}');
//     }
//   } catch (e) {
//     // 7) Rollback trạng thái nếu lỗi
//     setState(() {
//       final ix = currentChat!.messages.indexWhere((m) => m["_id"] == tempId);
//       if (ix != -1) currentChat!.messages[ix]["status"] = "failed";
//     });
//   } finally {
//     scrollToBottom(scrollController);
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'index.dart';
import '../../ui/chat_widget.dart';
import '../../index.dart';
import '../../crypto_utils.dart';

Future<void> sendMessage(
    Function setState,
    ScrollController scrollController,
    ) async {
  // 0) Kiểm tra input
  final String plain = controller.text.trim();
  if (plain.isEmpty || selectedImages.isNotEmpty) return;

  final String? conversationId = currentChat?.id; // = conversationId
  if (conversationId == null) return;

  // 1) Optimistic bubble (chỉ để hiển thị cục bộ)
  final String tempId = const Uuid().v4();
  final optimistic = {
    "_id": tempId,
    "text": plain,                 // hiển thị bản rõ cho chính mình
    "senderId": userId,            // field mới: senderId
    "captions": null,
    "isTyping": false,
    "timestamp": DateTime.now().toIso8601String(),
    "status": "sending",
    "kind": "text",
  };

  // Tắt bubble “typing”
  currentChat?.messages = currentChat!.messages.map((m) {
    if (m["isTyping"] == true) m["isTyping"] = false;
    return m;
  }).toList();

  setState(() => currentChat?.messages.add(optimistic));
  scrollToBottom(scrollController);
  controller.clear();

  try {
    // 2) Lấy danh sách thành viên và publicKey
    // YÊU CẦU backend có route: GET /conversations/:id/members
    // trả về: [{ "userId": "...", "publicKey": "-----BEGIN PUBLIC KEY-----..." }, ...]
    final memRes = await http
        .get(Uri.parse('$apiBaseUrl/conversations/$conversationId/members'))
        .timeout(const Duration(seconds: 10));

    if (memRes.statusCode != 200) {
      throw Exception('GET /conversations/:id/members failed: ${memRes.body}');
    }
    final List members = jsonDecode(memRes.body) as List;

    // 3) Tạo khóa AES phiên và mã hóa cho từng thành viên (loại chính mình)
    final String aesKeyB64 = AESUtil.generateKeyBase64();
    final List<Map<String, dynamic>> keys = [];

    for (final m in members) {
      final String uid = m['userId'];
      // if (uid == userId) continue;
      final String pub = m['publicKey'];
      try {
        print("///////${uid}////${pub}");
        final encKey = await RSAUtil.encryptKey(aesKeyB64, pub);
        keys.add({"userId": uid, "encryptedAesKey": encKey});
      } catch (_) {
        // bỏ qua người mã hóa lỗi, vẫn gửi cho các thành viên còn lại
      }
    }

    // 4) Mã hóa nội dung bằng AES
    final String cipherText = await AESUtil.encrypt(plain, aesKeyB64);

    // 5) Gửi tới backend mới: POST /messages
    final payload = {
      "conversationId": conversationId,
      "senderId": userId,
      "clientMessageId": tempId,
      "kind": "text",
      "text": cipherText,
      "captions": null,
      "keys": keys, // [{userId, encryptedAesKey}]
    };
    print(payload);
    final resp = await http
        .post(
      Uri.parse('$apiBaseUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    )
        .timeout(const Duration(seconds: 12));

    if (resp.statusCode == 200) {
      // Không chèn message mới ở đây; chờ WS “message”
      setState(() {
        final ix =
        currentChat!.messages.indexWhere((m) => m["_id"] == tempId);
        if (ix != -1) currentChat!.messages[ix]["status"] = "sent";
      });
    } else {
      throw Exception('POST /messages failed: ${resp.body}');
    }
  } catch (e) {
    // 6) Rollback trạng thái nếu lỗi
    setState(() {
      final ix = currentChat!.messages.indexWhere((m) => m["_id"] == tempId);
      if (ix != -1) currentChat!.messages[ix]["status"] = "failed";
    });
  } finally {
    scrollToBottom(scrollController);
  }
}
