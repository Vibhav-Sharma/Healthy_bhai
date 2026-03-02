import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage.
  /// Returns the download URL of the uploaded file.
  ///
  /// [file] - The file to upload (Mobile/Desktop)
  /// [bytes] - The file bytes to upload (Web)
  /// [patientId] - Used to organize files by patient
  /// [fileName] - Original file name
  static Future<String> uploadFile({
    File? file,
    Uint8List? bytes,
    required String patientId,
    required String fileName,
  }) async {
    // Create a unique path: reports/{patientId}/{timestamp}_{fileName}
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'reports/$patientId/${timestamp}_$fileName';

    final ref = _storage.ref().child(path);
    TaskSnapshot uploadTask;
    
    if (bytes != null) {
      uploadTask = await ref.putData(bytes);
    } else if (file != null) {
      uploadTask = await ref.putFile(file);
    } else {
      throw Exception('No file or bytes provided for upload');
    }
    
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  }

  /// Delete a file from Firebase Storage by its URL.
  static Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      // File might already be deleted, ignore
    }
  }
}
