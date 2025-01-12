
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  String id;
  String title;
  late List<Map<String, dynamic>> messages;
  bool isEditing;

  Chat({required this.id, required this.title, required this.messages, this.isEditing = false});
  // Phương thức để tạo đối tượng Chat từ Document Firestore
  factory Chat.fromDocument(DocumentSnapshot doc) {
    return Chat(
      id: doc.id,
      title: doc['title'] ?? '',
      messages: [],
    );
  }
}

late String userId;
const String avatarUrl = 'assets/avatar.jpg';
const String userName = 'Họ và tên';
String userEmail = 'email@example.com';
bool isAdmin  = false;

final FirebaseFirestore firestore = FirebaseFirestore.instance;
// API của gimini
const String apiKey = 'AIzaSyA_INlI-31sF05njnggLQQ8oiTRORLqhvI';

