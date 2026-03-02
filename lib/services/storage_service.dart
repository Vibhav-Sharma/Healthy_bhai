import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage.
  /// Returns the download URL of the uploaded file.
  ///
  /// [file] - The file to upload
  /// [patientId] - Used to organize files by patient
  /// [fileName] - Original file name
  static Future<String> uploadFile({
    required File file,
    required String patientId,
    required String fileName,
  }) async {
    // Create a unique path: reports/{patientId}/{timestamp}_{fileName}
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'reports/$patientId/${timestamp}_$fileName';

    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
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
