import '../../ui/chat_widget.dart';
import '../../index.dart';

Future<void> pickImage(ImageSource source, Function setState) async {
  final XFile? image = await picker.pickImage(source: source);
  if (image != null) {
    String tempImageUrl = image.path; // Đường dẫn tạm thời để hiển thị ảnh

    // Thêm ảnh vào danh sách với trạng thái "loading"
    setState(() {
      selectedImages.add({
        'url': tempImageUrl,
        'status': 'loading',
      });
    });

    String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';

    // Tải ảnh lên Firebase Storage trong nền
    FirebaseStorage.instance
        .ref('images/$fileName')
        .putFile(File(image.path))
        .then((TaskSnapshot uploadTask) async {
      if (uploadTask.state == TaskState.success) {
        String imageUrl = await uploadTask.ref.getDownloadURL();

        // Cập nhật URL thật của ảnh và thay đổi trạng thái thành "uploaded"
        setState(() {
          int index = selectedImages.indexWhere((img) => img['url'] == tempImageUrl);
          if (index != -1) {
            selectedImages[index]['url'] = imageUrl;
            selectedImages[index]['status'] = 'uploaded';
          }
        });
      } else {
        // Xử lý lỗi tải lên thất bại
        setState(() {
          int index = selectedImages.indexWhere((img) => img['url'] == tempImageUrl);
          if (index != -1) {
            selectedImages[index]['status'] = 'failed';
          }
        });
        print("Failed to upload image: $fileName");
      }
    });
  }
}

void removeImage(String imageUrl, Function setState) {
  setState(() {
    selectedImages.removeWhere((image) => image['url'] == imageUrl);
  });
}
