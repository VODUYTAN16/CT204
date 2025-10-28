// lib/api/social_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../globalvariety.dart'; // apiBaseUrl, userId
import '../utils/chat/index.dart'; // Chat model
import '../crypto_utils.dart';
import '../ui/chat_widget.dart'; // currentChat, wsSingleton, fetchMessages, scrollToBottom
import '../index.dart';

Future<Map<String, dynamic>?> fetchUserById(String uid) async {
  final r = await http.get(Uri.parse('$apiBaseUrl/users/$uid'));
  if (r.statusCode != 200) return null;
  final Map<String, dynamic> j = jsonDecode(r.body);
  return j;
}


// ======= Friends =======
Future<List<Map<String, dynamic>>> fetchFriends() async {
  final r = await http.get(Uri.parse('$apiBaseUrl/friendships?userId=$userId'));
  if (r.statusCode != 200) return [];
  final List list = jsonDecode(r.body);
  return list.cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> fetchIncomingFriendRequests() async {
  // Cần route này ở backend: trả danh sách { _id: requestId, requester: {userId, email, name, avatar} }
  final r = await http.get(Uri.parse('$apiBaseUrl/friendships/pending?userId=$userId'));
  if (r.statusCode != 200) return [];
  final List list = jsonDecode(r.body);
  return list.cast<Map<String, dynamic>>();
}

Future<bool> requestFriendByEmail(String email) async {
  final r = await http.post(
    Uri.parse('$apiBaseUrl/friendships/request'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"requesterId": userId, "email": email.trim().toLowerCase()}),
  );
  return r.statusCode == 200;
}

Future<bool> acceptFriendRequest(String requestId) async {
  final r = await http.post(Uri.parse('$apiBaseUrl/friendships/$requestId/accept'));
  return r.statusCode == 200;
}

Future<bool> deleteFriend(String friendUserId) async {
  // Cần route này ở backend
  final r = await http.delete(
    Uri.parse('$apiBaseUrl/friendships/between?userId=$userId&friendId=$friendUserId'),
  );
  return r.statusCode == 200;
}

// ======= Conversations / Groups =======
Future<List<Map<String, dynamic>>> fetchMyConversations() async {
  final r = await http.get(Uri.parse('$apiBaseUrl/conversations?userId=$userId'));
  if (r.statusCode != 200) return [];
  final List list = jsonDecode(r.body);
  print(list);
  // if (convos.isNotEmpty) {
  //   // chọn chat cuối cùng làm current chat
  //   final lastChat = convos.last;
  //   setState(() {
  //     _selectedChat = Chat.fromJson(lastChat);
  //     _loading = false;
  //   });
  // } else {
  //   // không có conversation
  //   setState(() => _loading = false);
  // }
  return list.cast<Map<String, dynamic>>();
}

Future<String?> createDirectConversation(String friendUserId) async {
  final r = await http.post(
    Uri.parse('$apiBaseUrl/conversations/direct'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"a": userId, "b": friendUserId}),
  );
  if (r.statusCode != 200) return null;
  final j = jsonDecode(r.body);
  return j['conversationId']?.toString();
}

Future<String?> createGroup(
    String title,
    List<String> memberIds, {
      BuildContext? context,
    }) async {
  final String safeTitle = title.trim();
  print('-----------------------------------------------------${memberIds.length}');

  // Ràng buộc: cần ít nhất 3 thành viên trong memberIds
  if (memberIds.length < 2 ) {
    final msg = 'Nhóm cần tối thiểu 3 thành viên.';
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop();
    } else {
      // fallback
      // ignore: avoid_print
      print(msg);
    }
    return null;
  }

  if (safeTitle.isEmpty) {
    final msg = 'Tên nhóm không được để trống.';
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      // ignore: avoid_print
      print(msg);
    }
    return null;
  }

  try {
    final r = await http.post(
      Uri.parse('$apiBaseUrl/conversations/group'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': safeTitle,
        'createdBy': userId,
        'memberIds': memberIds,
      }),
    );

    if (r.statusCode != 200) {
      final msg = 'Tạo nhóm thất bại: ${r.statusCode}';
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      } else {
        // ignore: avoid_print
        print('$msg ${r.body}');
      }
      return null;
    }

    final j = jsonDecode(r.body);
    return j['conversationId']?.toString();
  } catch (e) {
    final msg = 'Lỗi mạng khi tạo nhóm: $e';
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      // ignore: avoid_print
      print(msg);
    }
    return null;
  }
}

Future<bool> addMemberToGroup(String conversationId, String targetUserId) async {
  final r = await http.post(
    Uri.parse('$apiBaseUrl/conversations/$conversationId/members'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"userId": targetUserId}),
  );
  return r.statusCode == 200;
}

Future<bool> removeMemberFromGroup(String conversationId, String targetUserId) async {
  // Cần route này ở backend
  final r = await http.delete(
    Uri.parse('$apiBaseUrl/conversations/$conversationId/members/$targetUserId'),
  );
  return r.statusCode == 200;
}

Future<bool> renameGroup(String conversationId, String newTitle) async {
  // Cần route này ở backend
  final r = await http.patch(
    Uri.parse('$apiBaseUrl/conversations/$conversationId'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"title": newTitle}),
  );
  return r.statusCode == 200;
}

Future<bool> deleteGroup(String conversationId) async {
  final r = await http.delete(Uri.parse('$apiBaseUrl/conversations/$conversationId'));
  return r.statusCode == 200;
}

// ======= Navigation helpers =======
Future<void> openDirectChat(String friendUserId, Function setState, ScrollController scroll) async {
  // 1) Lấy profile để có name + avatar
  final profile = await fetchUserById(friendUserId);
  final displayName = (profile?['name']?.toString()?.trim().isNotEmpty ?? false)
      ? profile!['name'].toString().trim()
      : (profile?['email']?.toString() ?? 'Trò chuyện');

  final avatar = profile?['avatar']?.toString() ?? '';

  // 2) Tạo (hoặc lấy) conversation direct
  final cid = await createDirectConversation(friendUserId);
  if (cid == null) return;
  wsSingleton.subscribe(cid);

  // 3) Gán title và avatar cho màn chat
  currentChat = Chat(id: cid, title: displayName, messages: [], isEditing: false);
  currentChatPeerAvatarPath = avatar;   // URL ảnh đối phương
  currentChatIsGroup = false;
  currentChatIsGroup = false;


  await fetchMessages(cid, setState);
  wsSingleton.subscribe(cid);
  scrollToBottom(scroll);
}

Future<void> openExistingDirectChat(
    Map<String, dynamic> convo,
    Function setState,
    ScrollController scroll,
    ) async {
  final String? cid = convo['_id']?.toString();
  if (cid == null) return;

  // 1) Lấy peerId từ directPair (ưu tiên)
  String? peerId;
  final dp = convo['directPair'] as Map<String, dynamic>?;
  if (dp != null) {
    final String? a = dp['a']?.toString();
    final String? b = dp['b']?.toString();
    if (a == userId) {
      peerId = b;
    } else if (b == userId) {
      peerId = a;
    } else {
      // fallback nếu userId không khớp (trường hợp dữ liệu lệch)
      peerId = a ?? b;
    }
  }

  // 2) Fallback sang members/participants nếu chưa có peerId
  if (peerId == null || peerId.isEmpty) {
    final members = (convo['members'] ?? convo['participants']) as List<dynamic>?;
    if (members != null && members.isNotEmpty) {
      for (final m in members) {
        final String? mid = (m is Map)
            ? (m['_id'] ?? m['userId'] ?? m['id'])?.toString()
            : m?.toString();
        if (mid != null && mid != userId) {
          peerId = mid;
          break;
        }
      }
    }
  }

  // 3) Lấy profile peer để có tên + avatar
  Map<String, dynamic>? profile;
  if (peerId != null && peerId.isNotEmpty) {
    profile = await fetchUserById(peerId);
  }

  // 4) Xác định title hiển thị
  final String displayName = (() {
    final name = profile?['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    final email = profile?['email']?.toString().trim();
    if (email != null && email.isNotEmpty) return email;
    final t = convo['title']?.toString().trim();
    if (t != null && t.isNotEmpty) return t;
    return 'Trò chuyện';
  })();

  // 5) Ảnh local: ưu tiên avatarLocal, nếu không có thì avatar (vẫn có thể là local path)
  final String avatarPath = (() {
    final aLocal = profile?['avatarLocal']?.toString();
    if (aLocal != null && aLocal.isNotEmpty) return aLocal;
    final a = profile?['avatar']?.toString();
    return a ?? '';
  })();

  // 6) Cập nhật chat hiện tại
  currentChat = Chat(id: cid, title: displayName, messages: [], isEditing: false);
  currentChatPeerAvatarPath = avatarPath; // path local (asset/file) của đối phương
  currentChatIsGroup = false;

  // 7) Nạp tin nhắn & subscribe
  await fetchMessages(cid, setState);
  wsSingleton.subscribe(cid);
  scrollToBottom(scroll);
}


Future<void> openGroupChat(Map<String, dynamic> convo, Function setState, ScrollController scroll) async {
  final cid = convo['_id']?.toString();
  if (cid == null) return;
  final title = (convo['title']?.toString().isNotEmpty ?? false) ? convo['title'].toString() : 'Nhóm';
  currentChat = Chat(id: cid, title: title, messages: [], isEditing: false);
  currentChatPeerAvatarPath = null;     // không dùng cho nhóm
  currentChatIsGroup = true;

  await fetchMessages(cid, setState);
  wsSingleton.subscribe(cid);
  scrollToBottom(scroll);
}
