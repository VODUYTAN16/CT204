
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
   String id;
   String title;
   List<dynamic> messages; // Danh sách tin nhắn trong chat
   bool isEditing;

  Chat({
    required this.id,
    required this.title,
    required this.messages,
     this.isEditing =  false,
  });

  // Phương thức từ JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      title: json['title'],
      messages: List.from(json['messages'] ?? []),
    );
  }
}


late String userId;
 String avatarUrl = 'assets/avatar.jpg';
 String userName = 'Họ và tên';
String userEmail = 'email@example.com';
bool isAdmin  = false;

final FirebaseFirestore firestore = FirebaseFirestore.instance;
// API của gimini
const String apiKey = 'AIzaSyA_INlI-31sF05njnggLQQ8oiTRORLqhvI';

late String privateKey_RSA ;

const String apiBaseUrl = 'http://192.168.1.53:5000';