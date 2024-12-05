import '../index.dart';

Future<String?> showNewChatDialog(BuildContext context) async {
  String newChatTitle = 'Cuộc trò chuyện mới';
  return await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Tạo cuộc trò chuyện mới'),
        content: TextField(
          onChanged: (value) {
            newChatTitle = value;
          },
          decoration: InputDecoration(
              hintText: 'Đặt tên cho cuộc trò chuyện'),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Hủy'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Tạo'),
            onPressed: () {
              Navigator.of(context).pop(newChatTitle);
            },
          ),
        ],
      );
    },
  );
  return newChatTitle;
}
