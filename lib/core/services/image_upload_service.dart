import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  static final _storage = FirebaseStorage.instance;
  static final _picker = ImagePicker();

  /// Pick an image from gallery
  static Future<XFile?> pickFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
  }

  /// Pick an image from camera
  static Future<XFile?> pickFromCamera() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
  }

  /// Upload image to Firebase Storage, returns download URL
  static Future<String> uploadProductImage(XFile file, String productName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = productName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    final path = 'products/${safeName}_$timestamp.jpg';

    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(File(file.path));
    return await uploadTask.ref.getDownloadURL();
  }

  /// Upload employee profile picture
  static Future<String> uploadEmployeeImage(XFile file, String employeeName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = employeeName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    final path = 'users/${safeName}_$timestamp.jpg';

    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(File(file.path));
    return await uploadTask.ref.getDownloadURL();
  }

  /// Delete image from Firebase Storage by URL
  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (_) {
      // Ignore errors if image doesn't exist
    }
  }
}
