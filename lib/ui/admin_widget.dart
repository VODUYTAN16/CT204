import 'package:namer_app/index.dart';

class AdminScreen extends StatefulWidget{
  @override
  AdminScreenState createState() => AdminScreenState();
}

class AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> uploadedFiles = []; // Danh sách file với tên và trạng thái tải

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, // Chọn nhiều file
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'], // Các định dạng cho phép
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.path != null) {
            // Trường hợp Mobile/Desktop (dùng file.path)
            setState(() {
              uploadedFiles.add({
                "name": file.name,
                "status": "Đang tải...", // Hiển thị trạng thái ban đầu
                "progress": 0.0, // Tiến trình ban đầu
              });
            });
            await _uploadFileFromDevice(file.path!, file.name);
          }
        }
      } else {
        print("Người dùng đã hủy chọn file.");
      }
    } catch (e) {
      print("Lỗi khi chọn file: $e");
    }
  }

  Future<void> _uploadFileFromDevice(String filePath, String originalFileName) async {
    try {
      File file = File(filePath);

      // Tạo tên file duy nhất bằng cách thêm timestamp vào trước tên gốc
      String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$originalFileName';

      // Tạo tham chiếu tới Firebase Storage
      Reference ref = FirebaseStorage.instance.ref().child('uploads/$uniqueFileName');

      // Thực hiện tải file
      UploadTask uploadTask = ref.putFile(file);

      // Theo dõi tiến trình tải
      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          int fileIndex = uploadedFiles.indexWhere((file) => file["name"] == originalFileName);
          if (fileIndex != -1) {
            uploadedFiles[fileIndex]["progress"] =
                event.bytesTransferred / event.totalBytes;
          }
        });
      });

      // Chờ tải lên hoàn tất
      TaskSnapshot snapshot = await uploadTask;
      String fileUrl = await snapshot.ref.getDownloadURL();
      print("Tải lên thành công. URL: $fileUrl");

      // Cập nhật trạng thái tải thành công
      setState(() {
        int fileIndex = uploadedFiles.indexWhere((file) => file["name"] == originalFileName);
        if (fileIndex != -1) {
          uploadedFiles[fileIndex]["status"] = "Hoàn thành";
          uploadedFiles[fileIndex]["progress"] = 1.0; // Đặt tiến trình thành hoàn tất
          uploadedFiles[fileIndex]["url"] = fileUrl;
        }
      });
    } catch (e) {
      print("Lỗi khi tải file từ thiết bị: $e");

      // Cập nhật trạng thái lỗi
      setState(() {
        int fileIndex = uploadedFiles.indexWhere((file) => file["name"] == originalFileName);
        if (fileIndex != -1) {
          uploadedFiles[fileIndex]["status"] = "Thất bại";
          uploadedFiles[fileIndex]["progress"] = 0.0; // Đặt tiến trình về 0
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload File"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _pickFiles,
              icon: Icon(Icons.upload_file),
              label: Text(
                "Chọn File",
                textAlign: TextAlign.center, // Văn bản căn giữa
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20), // Điều chỉnh chiều cao
                minimumSize: Size(double.infinity, 0), // Đảm bảo nút full chiều ngang
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Danh sách file đã tải:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: uploadedFiles.length,
                itemBuilder: (context, index) {
                  var file = uploadedFiles[index];
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        file["status"] == "Hoàn thành"
                            ? Icons.check_circle
                            : file["status"] == "Thất bại"
                            ? Icons.error
                            : Icons.cloud_upload,
                        color: file["status"] == "Hoàn thành"
                            ? Colors.green
                            : file["status"] == "Thất bại"
                            ? Colors.red
                            : Colors.blue,
                      ),
                      title: Text(file["name"]),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(uploadedFiles[index]["status"]), // Trạng thái
                          if (file["progress"] > 0 && file["progress"] < 1 && file["status"] == "Đang tải...")// Hiển thị thanh progress nếu chưa tải xong
                            Column(
                              children: [
                                SizedBox(height: 8),
                                LinearProgressIndicator(value: file["progress"]),
                              ],
                            ),
                        ],
                      ),

                      trailing: file["status"] == "Hoàn thành"
                          ? IconButton(
                        icon: Icon(Icons.open_in_browser),
                        onPressed: () {
                          // Mở file đã tải
                          // TODO: Thêm logic mở URL file
                        },
                      )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
