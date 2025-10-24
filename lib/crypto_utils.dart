import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:basic_utils/basic_utils.dart';

// ================== AES UTIL ==================
// Lớp này chịu trách nhiệm mã hóa / giải mã dữ liệu bằng AES (thuật toán đối xứng)
class AESUtil {
  // 🔹 Sinh khóa AES ngẫu nhiên 128-bit và trả về ở dạng Base64
  //    - keySize = 16 byte (tương ứng 128-bit)
  //    - Base64 giúp dễ truyền tải qua mạng hoặc in ra màn hình
  static String generateKeyBase64({int keySize = 16}) {
    final rnd = Random.secure(); // Tạo bộ sinh số ngẫu nhiên an toàn
    final key = Uint8List.fromList(
        List<int>.generate(keySize, (_) => rnd.nextInt(256)));
    return base64Encode(key); // ✅ Trả về chuỗi Base64 của khóa AES
  }

  // 🔹 Sinh IV (Initialization Vector - vector khởi tạo) ngẫu nhiên 16 byte
  //    IV giúp đảm bảo mỗi lần mã hóa cùng 1 dữ liệu cũng cho ra kết quả khác
  static Uint8List _generateIV() {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(16, (_) => rnd.nextInt(256)));
  }

  // 🔹 Tạo đối tượng PaddedBlockCipher để thực hiện mã hóa AES ở chế độ CBC + PKCS7 Padding
  //    - forEncrypt = true => mã hóa
  //    - forEncrypt = false => giải mã
  //    - KeyParameter(key): sử dụng khóa AES
  //    - ParametersWithIV: truyền thêm IV (vector khởi tạo)
  static PaddedBlockCipher _initCipher(
      bool forEncrypt, Uint8List key, Uint8List iv) {
    final cipher =
    PaddedBlockCipher('AES/CBC/PKCS7'); // Dùng AES/CBC với padding PKCS7
    cipher.init(
        forEncrypt,
        PaddedBlockCipherParameters(
            ParametersWithIV(KeyParameter(key), iv), null));
    return cipher;
  }

  // 🔹 Mã hóa dữ liệu bằng AES
  //    - Sinh IV ngẫu nhiên
  //    - Mã hóa plaintext
  //    - Ghép IV + ciphertext rồi mã hóa Base64 để dễ lưu truyền
  static String encrypt(String plaintext, String keyBase64) {
    final key =
    base64Decode(keyBase64); // Giải mã chuỗi Base64 để lấy bytes thật
    final iv = _generateIV(); // Sinh IV
    final cipher = _initCipher(true, key, iv); // Tạo cipher để mã hóa

    final inputBytes =
    Uint8List.fromList(utf8.encode(plaintext)); // Chuỗi gốc → bytes
    final encrypted = cipher.process(inputBytes); // Mã hóa dữ liệu
    final combined =
    Uint8List.fromList(iv + encrypted); // Ghép IV và ciphertext

    final result = base64Encode(combined); // Chuỗi mã hóa cuối cùng (Base64)

    // In ra console để theo dõi quy trình
    print("\n[🔒 AES ENCRYPTION]");
    print("Plaintext: $plaintext");
    print("IV bytes: ${iv.toList()}");
    print("Cipher bytes: ${encrypted.toList()}");
    print("Cipher (Base64): $result");

    return result;
  }

  // 🔹 Giải mã dữ liệu AES
  //    - Tách IV ra khỏi ciphertext
  //    - Dùng cùng khóa AES để giải mã
  static String decrypt(String cipherBase64, String keyBase64) {
    final key = base64Decode(keyBase64); // Giải mã khóa AES từ Base64
    final combined =
    base64Decode(cipherBase64); // Giải mã chuỗi mã hóa từ Base64
    final iv = combined.sublist(0, 16); // 16 byte đầu là IV
    final cipherBytes = combined.sublist(16); // Phần còn lại là ciphertext

    final cipher =
    _initCipher(false, key, Uint8List.fromList(iv)); // Chuẩn bị để giải mã
    final decryptedBytes = cipher.process(Uint8List.fromList(cipherBytes));
    final plaintext = utf8.decode(decryptedBytes); // Chuyển bytes → string gốc


    return plaintext;
  }
}

// ================== RSA UTIL ==================
// Lớp này chịu trách nhiệm sinh khóa RSA (bất đối xứng) và mã hóa / giải mã khóa AES
class RSAUtil {
  // 🔹 Sinh cặp khóa RSA (Public & Private)
  //    - Dùng thuật toán RSA 1024-bit (mặc định)
  //    - Trả về ngay ở dạng PEM chuẩn quốc tế
  static Map<String, String> generateKeys({int bitLength = 1024}) {
    // Tạo bộ sinh số ngẫu nhiên an toàn
    final fort = FortunaRandom();
    final seed = Uint8List(32);
    final rnd = Random.secure();
    for (int i = 0; i < seed.length; i++) seed[i] = rnd.nextInt(256);
    fort.seed(KeyParameter(seed));

    // Cấu hình thuật toán sinh khóa RSA
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.from(65537), bitLength, 64), fort));

    // Sinh cặp khóa (public, private)
    final pair = keyGen.generateKeyPair();
    final pub = pair.publicKey as RSAPublicKey;
    final priv = pair.privateKey as RSAPrivateKey;

    // Chuyển khóa về dạng PEM (chuẩn quốc tế BEGIN/END PUBLIC KEY)
    final pubPem = CryptoUtils.encodeRSAPublicKeyToPem(pub);
    final privPem = CryptoUtils.encodeRSAPrivateKeyToPem(priv);


    // Trả về 2 khóa dạng PEM
    return {
      'publicKeyPem': pubPem,
      'privateKeyPem': privPem,
    };
  }

  // 🔹 Mã hóa khóa AES bằng public key (dạng PEM)
  //    - AES key được giải mã từ Base64 → bytes
  //    - RSAEngine dùng public key để mã hóa AES key
  static String encryptKey(String aesKeyBase64, String publicKeyPem) {
    final pub = CryptoUtils.rsaPublicKeyFromPem(
        publicKeyPem); // Chuyển PEM → RSAPublicKey
    final aesKeyBytes = base64Decode(aesKeyBase64); // Base64 → bytes
    final engine = PKCS1Encoding(RSAEngine())
      ..init(
          true,
          PublicKeyParameter<RSAPublicKey>(
              pub)); // Khởi tạo RSA engine để mã hóa

    final encrypted = engine.process(aesKeyBytes); // Mã hóa AES key
    final encryptedBase64 = base64Encode(encrypted); // Mã hóa kết quả ra Base64


    return encryptedBase64;
  }

  // 🔹 Giải mã khóa AES bằng private key (PEM)
  //    - Nhận ciphertext RSA (Base64)
  //    - Giải mã ra AES key gốc (Base64)
  static String decryptKey(String cipherBase64, String privateKeyPem) {
    final priv =
    CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem); // PEM → RSAPrivateKey
    final engine = PKCS1Encoding(RSAEngine())
      ..init(false,
          PrivateKeyParameter<RSAPrivateKey>(priv)); // Chuẩn bị để giải mã

    final cipherBytes = base64Decode(cipherBase64); // Base64 → bytes
    final decrypted = engine.process(cipherBytes); // Giải mã AES key
    final decryptedBase64 =
    base64Encode(decrypted); // Trả về AES key dạng Base64

    return decryptedBase64;
  }
}

// Lưu trữ private key vào Flutter Secure Storage
Future<void> storePrivateKey(String privateKey, String userId) async {
  final _storage = FlutterSecureStorage();
  await _storage.write(key: 'private_key_${userId}', value: privateKey);
}

// Lấy private key từ Flutter Secure Storage
Future<String?> getPrivateKey(String userId) async {
  final _storage = FlutterSecureStorage();
  return await _storage.read(key: 'private_key_${userId}');
}

void main() {
  print("=== 🔐 DEMO MÃ HÓA ĐẦU CUỐI (RSA + AES) ===");

  // 1️⃣ Sinh cặp khóa RSA cho người nhận (trả về PEM)
  final receiverKeys = RSAUtil.generateKeys();
  final receiverPubKey = receiverKeys['publicKeyPem']!;
  final receiverPrivKey = receiverKeys['privateKeyPem']!;

  // 2️⃣ Người gửi nhập tin nhắn cần mã hóa
  stdout.write("\n[✍️] Nhập tin nhắn cần mã hóa: ");
  final message = stdin.readLineSync() ?? "";

  // 3️⃣ Người gửi sinh khóa AES (Base64)
  final aesKeyB64 = AESUtil.generateKeyBase64();
  print("\n[🔑 AES KEY]");
  print("AES Key (Base64): $aesKeyB64");

  // 4️⃣ Mã hóa nội dung bằng AES (sử dụng AES key Base64)
  final cipherText = AESUtil.encrypt(message, aesKeyB64);

  // 5️⃣ Mã hóa khóa AES bằng RSA public key (người nhận)
  final encryptedAesKey = RSAUtil.encryptKey(aesKeyB64, receiverPubKey);

  // 6️⃣ Gửi dữ liệu đi (mô phỏng)
  print("\n[📤 DỮ LIỆU GỬI ĐI]");
  print("→ Encrypted AES Key (RSA, Base64): $encryptedAesKey");
  print("→ CipherText (AES, Base64): $cipherText");

  // 7️⃣ Người nhận giải mã khóa AES bằng private key PEM
  final decryptedAesKeyB64 =
  RSAUtil.decryptKey(encryptedAesKey, receiverPrivKey);
  print("\n[📥 AES KEY SAU GIẢI MÃ]");
  print("Decrypted AES Key (Base64): $decryptedAesKeyB64");

  // 8️⃣ Người nhận giải mã tin nhắn bằng AES
  final decryptedMessage = AESUtil.decrypt(cipherText, decryptedAesKeyB64);

  print("\n✅ [KẾT QUẢ CUỐI CÙNG]");
  print("Tin nhắn gốc sau khi giải mã: $decryptedMessage");
}
