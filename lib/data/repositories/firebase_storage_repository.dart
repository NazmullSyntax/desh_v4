import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import '../../domain/repositories/storage_repository.dart';

/// Firebase Storage implementation of [StorageRepository].
///
/// This is the ONLY file that should import `firebase_storage`. Active
/// once `AppConfig.useFirebase = true` (see lib/config/app_config.dart)
/// and Firebase has been initialized in main.dart.
class FirebaseStorageRepository implements StorageRepository {
  final fb_storage.FirebaseStorage _storage;

  FirebaseStorageRepository({fb_storage.FirebaseStorage? storage})
      : _storage = storage ?? fb_storage.FirebaseStorage.instance;

  @override
  Future<String> uploadFile({
    required String localFilePath,
    required String folder,
    required String fileName,
  }) async {
    final ref = _storage.ref().child(folder).child(fileName);
    final task = await ref.putFile(File(localFilePath));
    return task.ref.getDownloadURL();
  }

  @override
  Future<void> deleteFile(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    await ref.delete();
  }
}
