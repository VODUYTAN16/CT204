// lib/ui/drawer_social.dart
import 'dart:io';

import 'package:flutter/material.dart';
import '../services/APIhelper.dart';
import '../globalvariety.dart';
import '../utils/chat/index.dart';
import '../ui/chat_widget.dart';
import './index.dart';

class SocialDrawer extends StatefulWidget {
  final Function setRootState;
  final ScrollController scrollController;
  const SocialDrawer({super.key, required this.setRootState, required this.scrollController});

  @override
  State<SocialDrawer> createState() => _SocialDrawerState();
}

class _SocialDrawerState extends State<SocialDrawer> {
  late Future<List<Map<String, dynamic>>> _friendsFut;
  late Future<List<Map<String, dynamic>>> _pendingFut;
  late Future<List<Map<String, dynamic>>> _convosFut;

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  void _reloadAll() {
    _friendsFut  = fetchFriends();
    _pendingFut  = fetchIncomingFriendRequests();
    _convosFut   = fetchMyConversations();
  }

  Future<void> _addFriendDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm bạn bằng email'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'name@example.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Gửi')),
        ],
      ),
    );

    if (ok == true) {
      final done = await requestFriendByEmail(ctrl.text);
      if (done) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu kết bạn.')));
        setState(_reloadAll);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi yêu cầu thất bại.')));
      }
    }
  }

  Future<void> _renameGroupDialog(String conversationId, String currentTitle) async {
    final ctrl = TextEditingController(text: currentTitle);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đổi tên nhóm'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Tên nhóm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      final done = await renameGroup(conversationId, ctrl.text.trim());
      if (done) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đổi tên nhóm.')));
        setState(_reloadAll);
      }
    }
  }

  Future<void> _addMembersDialog(String conversationId) async {
    final friends = await fetchFriends();
    final selected = <String>{};
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setLocal) {
        return AlertDialog(
          title: const Text('Thêm thành viên'),
          content: SizedBox(
            width: 380,
            height: 400,
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (_, i) {
                final f = friends[i];
                final fid = f['_id']?.toString() ?? f['userId']?.toString() ?? '';
                final checked = selected.contains(fid);
                return CheckboxListTile(
                  value: checked,
                  onChanged: (v) {
                    setLocal(() {
                      if (v == true) selected.add(fid);
                      else selected.remove(fid);
                    });
                  },
                  title: Text(f['name']?.toString() ?? f['email']?.toString() ?? 'Bạn bè'),
                  subtitle: Text(f['email']?.toString() ?? ''),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
            ElevatedButton(
              onPressed: () async {
                var ok = true;
                for (final uid in selected) {
                  ok &= await addMemberToGroup(conversationId, uid);
                }
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm thành viên.')));
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      }),
    );
  }

  String? _peerIdFromConvo(Map<String, dynamic> c) {
    final pair = (c['directPair'] ?? {}) as Map<String, dynamic>;
    final a = pair['a']?.toString();
    final b = pair['b']?.toString();
    if (a == userId) return b;
    if (b == userId) return a;
    return a ?? b; // fallback
  }

  Widget _buildConvoTitle(Map<String, dynamic> c) {
    final isGroup = (c['type']?.toString() ?? '') == 'group';
    // Nhóm: ưu tiên title có sẵn, fallback "Nhóm"
    if (isGroup) {
      final t = (c['title']?.toString().trim().isNotEmpty ?? false)
          ? c['title'].toString().trim()
          : 'Nhóm';
      return Text(t);
    }

    // DIRECT: ưu tiên dữ liệu embed nếu có
    final embeddedName = (c['peer']?['name'] ?? c['peerName'])?.toString();
    if (embeddedName != null && embeddedName.trim().isNotEmpty) {
      return Text(embeddedName.trim());
    }

    // Không có -> fetch profile peerId
    final peerId = _peerIdFromConvo(c);
    if (peerId == null || peerId.isEmpty) {
      return const Text('Trực tiếp'); // fallback cuối
    }

    final fut = _profileFuts.putIfAbsent(peerId, () => fetchUserById(peerId));
    return FutureBuilder<Map<String, dynamic>?>(
      future: fut,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Text('Trực tiếp'); // tạm thời khi loading
        }
        final p = snap.data;
        final name = p?['name']?.toString();
        final email = p?['email']?.toString();
        final display = (name != null && name.trim().isNotEmpty)
            ? name.trim()
            : (email != null && email.isNotEmpty ? email : 'Trực tiếp');
        return Text(display);
      },
    );
  }

// Có thể đặt ở đầu _SocialDrawerState để cache lần fetch profile
  final Map<String, Future<Map<String, dynamic>?>> _profileFuts = {};

  Widget _buildConvoLeading(Map<String, dynamic> convo) {
    final isGroup = (convo['type']?.toString() ?? '') == 'group';
    if (isGroup) {
      return const Icon(Icons.groups);
    }

    // DIRECT: lấy peerId từ directPair
    final pair = (convo['directPair'] ?? {}) as Map<String, dynamic>;
    final a = pair['a']?.toString();
    final b = pair['b']?.toString();

    // userId là id hiện tại (đã có trong globalvariety.dart)
    String? peerId;
    if (a == userId) peerId = b;
    else if (b == userId) peerId = a;
    else peerId = a ?? b; // fallback nếu server chưa đồng bộ userId

    if (peerId == null || peerId.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.person));
    }

    // Nếu server đã embed sẵn avatar local cho peer trong convo, ưu tiên dùng ngay để tránh chờ Future
    final embeddedPath = (convo['peer']?['avatarLocal'] ?? convo['peerAvatarLocal'] ?? '').toString();
    if (embeddedPath.isNotEmpty) {
      final ImageProvider provider = embeddedPath.startsWith('assets/')
          ? AssetImage(embeddedPath)
          : FileImage(File(embeddedPath)) as ImageProvider;
      return CircleAvatar(backgroundImage: provider);
    }

    // Chưa có -> gọi API lấy profile peer (có cache Future để ListView không giật)
    final fut = _profileFuts.putIfAbsent(peerId, () => fetchUserById(peerId!));
    return FutureBuilder<Map<String, dynamic>?>(
      future: fut,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const CircleAvatar(child: Icon(Icons.person));
        }
        final profile = snap.data;
        final path = (profile?['avatarLocal'] ?? profile?['avatar'] ?? '').toString();

        if (path.isNotEmpty) {
          final ImageProvider provider = path.startsWith('assets/')
              ? AssetImage(path)
              : FileImage(File(path)) as ImageProvider;
          return CircleAvatar(backgroundImage: provider);
        }
        return const CircleAvatar(child: Icon(Icons.person));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: RefreshIndicator(
        onRefresh: () async => setState(_reloadAll),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF9CC6FF)),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage(avatarUrl),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                    child: Text(
                      userName,
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
            // ======= Groups / Conversations =======

            ListTile(
              title: const Text('Nhóm & hội thoại', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.group_add),
                onPressed: () async {
                  // Tạo nhóm nhanh: hỏi tên, chọn bạn để thêm
                  final titleCtrl = TextEditingController();
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Tạo nhóm mới'),
                      content: TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Tên nhóm')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tiếp tục')),
                      ],
                    ),
                  );
                  if (ok != true) return;

                  final friends = await fetchFriends();
                  final selected = <String>{};
                  if (!context.mounted) return;
                  await showDialog(
                    context: context,
                    builder: (_) => StatefulBuilder(builder: (context, setLocal) {
                      return AlertDialog(
                        title: const Text('Chọn thành viên'),
                        content: SizedBox(
                          width: 380, height: 400,
                          child: ListView.builder(
                            itemCount: friends.length,
                            itemBuilder: (_, i) {
                              final f = friends[i];
                              final fid = f['_id']?.toString() ?? f['userId']?.toString() ?? '';
                              final checked = selected.contains(fid);
                              return CheckboxListTile(
                                value: checked,
                                onChanged: (v) {
                                  setLocal(() {
                                    if (v == true) selected.add(fid); else selected.remove(fid);
                                  });
                                },
                                title: Text(f['name']?.toString() ?? f['email']?.toString() ?? 'Bạn'),
                                subtitle: Text(f['email']?.toString() ?? ''),
                              );
                            },
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
                          ElevatedButton(
                            onPressed: () async {
                              final cid = await createGroup(titleCtrl.text, selected.toList(), context: context);
                              if (cid != null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo nhóm.')));
                                setState(_reloadAll);
                              }
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text('Tạo'),
                          ),
                        ],
                      );
                    }),
                  );
                },
              ),
            ),
            FutureBuilder(
              future: _convosFut,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final convos = (snap.data ?? []) as List<Map<String, dynamic>>;
                if (convos.isEmpty) return const ListTile(title: Text('Chưa có hội thoại.'));
                return Column(
                  children: convos.map((c) {
                    final id = c['_id']?.toString() ?? '';
                    final isGroup = (c['type']?.toString() ?? '') == 'group';
                    final title = (c['title']?.toString().isNotEmpty ?? false)
                        ? c['title'].toString()
                        : isGroup ? 'Nhóm' : 'Trực tiếp';

                    return ListTile(

                      leading: _buildConvoLeading(c),
                      title: _buildConvoTitle(c),
                      onTap: () async {
                        if (isGroup) {
                          await openGroupChat(c, widget.setRootState, widget.scrollController);
                        } else {
                          await openExistingDirectChat(c, widget.setRootState, widget.scrollController);
                        }
                        wsSingleton.subscribe(c['_id']!.toString());
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      trailing: isGroup
                          ? PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'add') {
                            await _addMembersDialog(id);
                          } else if (value == 'rename') {
                            await _renameGroupDialog(id, title);
                          } else if (value == 'delete') {
                            final ok = await deleteGroup(id);
                            if (ok) setState(_reloadAll);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'add', child: Text('Thêm thành viên')),
                          const PopupMenuItem(value: 'rename', child: Text('Đổi tên nhóm')),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Xóa nhóm', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      )
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const Divider(),

            // ======= Friends =======
            ListTile(
              title: const Text('Bạn bè', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(icon: const Icon(Icons.person_add), onPressed: _addFriendDialog),
            ),
            FutureBuilder(
              future: _friendsFut,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final friends = (snap.data ?? []) as List<Map<String, dynamic>>;
                if (friends.isEmpty) {
                  return const ListTile(title: Text('Chưa có bạn bè.'));
                }
                return Column(
                  children: friends.map((f) {
                    final fid = f['_id']?.toString() ?? f['userId']?.toString() ?? '';
                    final title = f['name']?.toString() ?? f['email']?.toString() ?? 'Bạn';
                    final subtitle = f['email']?.toString() ?? '';
                    return ListTile(
                      leading: Builder(builder: (_) {
                        final path = (f['avatarLocal'] ?? f['avatar'] ?? '').toString();
                        if (path.isNotEmpty) {
                          final ImageProvider provider = path.startsWith('assets/')
                              ? AssetImage(path)
                              : FileImage(File(path)) as ImageProvider;
                          return CircleAvatar(backgroundImage: provider);
                        }
                        return const CircleAvatar(child: Icon(Icons.person));
                      }),


                      title: Text(title),
                      subtitle: Text(subtitle),
                      onTap: () async {
                        await openDirectChat(fid, widget.setRootState, widget.scrollController);

                        if (context.mounted) Navigator.of(context).pop();
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.person_remove),
                        onPressed: () async {
                          final ok = await deleteFriend(fid);
                          if (ok) setState(_reloadAll);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // ======= Friend requests (incoming) =======
            const Divider(),
            const ListTile(title: Text('Yêu cầu kết bạn', style: TextStyle(fontWeight: FontWeight.bold))),
            FutureBuilder(
              future: _pendingFut,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final reqs = (snap.data ?? []) as List<Map<String, dynamic>>;
                if (reqs.isEmpty) return const ListTile(title: Text('Không có yêu cầu mới.'));
                return Column(
                  children: reqs.map((r) {
                    final reqId = r['_id']?.toString() ?? '';
                    final requester = r['requester'] ?? {};
                    final title = requester['name']?.toString() ?? requester['email']?.toString() ?? 'Người dùng';
                    final email = requester['email']?.toString() ?? '';
                    return ListTile(
                      leading: const Icon(Icons.mail),
                      title: Text(title),
                      subtitle: Text(email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                if (await acceptFriendRequest(reqId)) setState(_reloadAll);
                              }),
                          // Bạn có thể thêm nút từ chối nếu có route tương ứng
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),


          ],
        ),
      ),
    );
  }
}
